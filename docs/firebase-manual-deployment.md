# Manual Firebase deployment files

Prepared from the existing working tree. No deployment or live changes performed. Rules and indexes must be rolled out with the compatible Functions and updated client; see firebase-staging-deployment.md.

## firestore.rules

Local path: `C:\Users\premier\StudioProjects\blood-bank\firestore.rules`

SHA-256: `ce29ff9a739e21b08e1a4e3e03b4c33eaafc81da51757c9d397c21d95022c773`

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function owner(uid) { return signedIn() && request.auth.uid == uid; }
    function active() {
      return signedIn()
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.status == 'approved';
    }
    function admin() {
      return active() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    function bloodGroup(value) { return value in ['A+','A-','B+','B-','AB+','AB-','O+','O-']; }
    function pakistan(d) {
      return d.latitude == null || (d.latitude >= 23.5 && d.latitude <= 37.1
        && d.longitude >= 60.8 && d.longitude <= 77.9);
    }
    function profileValid(d) {
      return d.name is string && d.name.size() >= 2 && d.name.size() <= 100
        && bloodGroup(d.bloodGroup) && d.isDonor is bool && d.isReceiver is bool
        && d.isAvailable is bool && d.locationSharingEnabled is bool
        && (d.role != 'donor' || d.isDonor) && (d.role != 'receiver' || d.isReceiver)
        && (!d.keys().hasAny(['phoneNumber','cnic','fcmToken','phoneVerified']))
        && (d.locationSharingEnabled || (d.latitude == null && d.longitude == null))
        && ((d.latitude == null) == (d.longitude == null))
        && (d.latitude == null || (d.latitude is number && d.latitude >= -90 && d.latitude <= 90))
        && (d.longitude == null || (d.longitude is number && d.longitude >= -180 && d.longitude <= 180));
    }
    match /users/{uid} {
      allow read: if owner(uid) || admin();
      allow create: if owner(uid) && profileValid(request.resource.data) && pakistan(request.resource.data)
        && request.resource.data.keys().hasOnly(['uid','email','name','role','bloodGroup','status',
          'isDonor','isReceiver','isAvailable','locationSharingEnabled','isEligible','rewardPoints',
          'createdAt','lastLoginAt','lastDonationDate','location','latitude','longitude','profileImageUrl'])
        && request.resource.data.uid == uid && request.resource.data.email == request.auth.token.email
        && request.resource.data.status == 'approved' && request.resource.data.role in ['donor','receiver']
        && request.resource.data.rewardPoints == 0 && request.resource.data.isEligible == true
        && request.resource.data.lastDonationDate == null;
      allow update: if (owner(uid) && admin() && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['lastLoginAt','notificationsEnabled','notificationPrefs'])) || (owner(uid) && active() && profileValid(request.resource.data)
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['latitude','longitude']) || pakistan(request.resource.data))
        && resource.data.role in ['donor','receiver'] && request.resource.data.role in ['donor','receiver']
        && (!resource.data.isDonor || request.resource.data.isDonor)
        && (!resource.data.isReceiver || request.resource.data.isReceiver)
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['email'])
          || request.resource.data.email == request.auth.token.email)
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'email','name','bloodGroup','role','isDonor','isReceiver','isAvailable','availabilityUpdatedAt',
          'locationSharingEnabled','latitude','longitude','location','locationUpdatedAt',
          'profileImageUrl','address','updatedAt','lastLoginAt','declinedRequestIds',
          'notificationsEnabled','notificationPrefs']));
      allow delete: if false; // Cleanup goes through the authenticated callable.
      match /devices/{deviceId} {
        allow read, delete: if owner(uid) && active();
        allow create, update: if owner(uid) && active()
          && request.resource.data.keys().hasOnly(['fcmToken','fcmUpdatedAt'])
          && request.resource.data.fcmToken is string && request.resource.data.fcmToken.size() <= 4096;
      }
      match /private/{document} {
        allow read: if (owner(uid) && active()) || admin();
        allow create: if owner(uid)
          && getAfter(/databases/$(database)/documents/users/$(uid)).data.status != 'suspended'
          && getAfter(/databases/$(database)/documents/users/$(uid)).data.status != 'rejected' && (
          (document == 'contact' && request.resource.data.keys().hasOnly(['phoneNumber','cnic'])) ||
          (document == 'device' && request.resource.data.keys().hasOnly(['fcmToken','fcmUpdatedAt'])));
        allow update: if owner(uid) && active() && (
          (document == 'device' && request.resource.data.keys().hasOnly(['fcmToken','fcmUpdatedAt'])) ||
          (document == 'contact' && request.resource.data.keys().hasOnly(['phoneNumber','cnic'])
            && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['phoneNumber'])
              || request.resource.data.phoneNumber == request.auth.token.phone_number)));
        allow delete: if owner(uid) && active() && document == 'device';
      }
    }
    match /verification_requests/{uid} {
      allow read: if admin() || (active() && request.auth.uid == uid);
      allow write: if false;
    }
    // Hospitals are maintained by administrators and are read-only to app users.
    // The client rejects entries that do not contain a valid name, address, and pin.
    match /hospitals/{hospitalId} {
      allow read: if active();
      allow create, update: if admin()
        && request.resource.data.name is string
        && request.resource.data.address is string
        && request.resource.data.latitude is number
        && request.resource.data.longitude is number
        && request.resource.data.latitude >= 23.5 && request.resource.data.latitude <= 37.1
        && request.resource.data.longitude >= 60.8 && request.resource.data.longitude <= 77.9;
      allow delete: if admin();
    }
    function participant(d) {
      return active() && (d.requesterId == request.auth.uid || request.auth.uid in d.get('participantIds', []) || request.auth.uid in d.get('acceptedDonorIds', []) || d.get('acceptedDonorId','') == request.auth.uid);
    }
    match /blood_requests/{id} {
      // Canonical requests contain patient/contact data, including legacy
      // records. Participants use server-redacted callable projections.
      allow read: if admin() || (active() && resource.data.requesterId == request.auth.uid);
      allow write: if false;
      match /invites/{donorId} {
        allow read: if admin() || (active() && (request.auth.uid == donorId || request.auth.uid == get(/databases/$(database)/documents/blood_requests/$(id)).data.requesterId));
        allow write: if false;
      }
      match /events/{eventId} {
        allow read: if admin() || (active() && request.auth.uid == get(/databases/$(database)/documents/blood_requests/$(id)).data.requesterId);
        allow write: if false;
      }
      match /private/contact {
        allow read, write: if admin() || (active() && request.auth.uid == get(/databases/$(database)/documents/blood_requests/$(id)).data.requesterId);
      }
      match /notReadyDonors/{donorId} {
        allow read: if admin() || (active() && request.auth.uid == get(/databases/$(database)/documents/blood_requests/$(id)).data.requesterId);
        allow write: if false;
      }
    }
    function liveChat(conversationId) {
      let c = get(/databases/$(database)/documents/conversations/$(conversationId)).data;
      let r = get(/databases/$(database)/documents/blood_requests/$(c.requestId)).data;
      let donor = c.participantIds[0] == r.requesterId ? c.participantIds[1] : c.participantIds[0];
      let legacy = donor in r.get('acceptedDonorIds', []) || donor == r.get('acceptedDonorId', '');
      let assignment = r.get('commitments', {}).get(donor, {'status': legacy ? 'accepted' : 'none'});
      return c.participantIds.size() == 2 && donor != r.requesterId
        && r.requesterId in c.participantIds
        && get(/databases/$(database)/documents/users/$(r.requesterId)).data.status == 'approved'
        && get(/databases/$(database)/documents/users/$(donor)).data.status == 'approved'
        && assignment.status in ['accepted','agreed','awaiting_confirmation']
        && r.status in ['pending','accepted','partially_fulfilled']
        && r.get('reviewStatus', '') != 'rejected'
        && (r.get('requiredBy', null) == null
          || (r.requiredBy is timestamp && r.requiredBy > request.time)
          || (r.requiredBy is number && (r.requiredBy == 0 || r.requiredBy > request.time.toMillis())));
    }
    match /conversations/{conversationId} {
      allow read: if active() && request.auth.uid in resource.data.participantIds;
      allow create, update, delete: if false;
      match /messages/{messageId} {
        allow read: if active()
          && request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        allow create: if active()
          && request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds
          && !(request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.get('blockedUserIds', []))
          && liveChat(conversationId)
          && request.resource.data.keys().hasOnly(['senderId','body','createdAt'])
          && request.resource.data.senderId == request.auth.uid
          && request.resource.data.body is string
          && request.resource.data.body.size() > 0
          && request.resource.data.body.size() <= 2000
          && request.resource.data.createdAt == request.time;
        allow update, delete: if false;
      }
    }
    match /callSessions/{sessionId} {
      allow read: if active() && request.auth.uid in resource.data.participantIds;
      allow create, update, delete: if false;
    }
    match /donations/{id} {
      allow read: if admin() || (active() && (resource.data.donorId == request.auth.uid || resource.data.get('requesterId','') == request.auth.uid));
      allow create, delete: if false;
      allow update: if active() && resource.data.donorId == request.auth.uid
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['certificateUrl']);
    }
    match /notifications/{id} {
      allow read: if active() && resource.data.userId == request.auth.uid;
      allow create: if admin();
      allow update: if active() && resource.data.userId == request.auth.uid
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead'])
        && request.resource.data.isRead is bool;
      allow delete: if admin() || (active() && resource.data.userId == request.auth.uid);
    }
    match /sosRequests/{id} {
      allow read: if admin() || (active() && resource.data.receiverId == request.auth.uid);
      allow write: if false;
    }
    match /rewards/{id} { allow read: if admin() || (active() && resource.data.donorId == request.auth.uid); allow write: if admin(); }
    match /blood_drives/{id} { allow read: if active(); allow write: if admin(); }
    match /audit_logs/{id} { allow read: if admin(); allow write: if false; }
    match /rate_limits/{id} { allow read: if admin(); allow write: if false; }
    match /admin_cache/{id} { allow read: if admin(); allow write: if false; }
    match /reports/{id} {
      allow read: if admin() || (active() && resource.data.reportedBy == request.auth.uid);
      allow create: if active() && request.resource.data.reportedBy == request.auth.uid;
      allow update, delete: if admin();
    }
    match /misuse_reports/{id} {
      allow read: if admin() || (active() && resource.data.reporterId == request.auth.uid);
      allow write: if false;
    }
    match /feedback/{id} {
      allow read: if admin() || (active() && resource.data.reporterId == request.auth.uid);
      allow write: if false;
    }
    match /broadcasts/{id} {
      allow read: if active();
      allow create: if admin() && request.resource.data.status == 'pending'
        && request.resource.data.audience in ['all','donors','receivers','bloodGroup']
        && request.resource.data.title is string && request.resource.data.title.size() > 0 && request.resource.data.title.size() <= 100
        && request.resource.data.body is string && request.resource.data.body.size() > 0 && request.resource.data.body.size() <= 2000;
      allow update: if false;
      allow delete: if admin();
    }
    match /awareness_banners/{id} {
      allow read: if admin();
      allow write: if false;
    }
    match /{document=**} { allow read, write: if false; }
  }
}
```

## firestore.indexes.json

Local path: `C:\Users\premier\StudioProjects\blood-bank\firestore.indexes.json`

SHA-256: `2d088b15d624a0e17e555d3cb1a3157993fc647451909c2bfd977b087b5e90cc`

```json
{
  "indexes": [
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isDonor",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "bloodGroup",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isAvailable",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isDonor",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "donations",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "donorId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "donationDate",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isReceiver",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "bloodGroup",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "role",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "lastDonationDate",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isDonor",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isAvailable",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "locationSharingEnabled",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "latitude",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "requesterId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isDonor",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "lastDonationDate",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "bloodGroup",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "urgency",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "reviewStatus",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "verification_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "submittedAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "misuse_reports",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "reportedAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isDonor",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isAvailable",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "lastActiveAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isDonor",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "profileVerified",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "profileVerifiedUntil",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "role",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isDonor",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isAvailable",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "locationSharingEnabled",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "latitude",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "longitude",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "acceptedDonorIds",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "invites",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        {
          "fieldPath": "donorId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "participantIds",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "acceptedDonorId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "donations",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "requesterId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "donationDate",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "bloodGroup",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "bloodGroup",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "urgency",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "bloodGroup",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "reviewStatus",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "urgency",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "blood_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "bloodGroup",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "callSessions",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "participantIds",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "misuse_reports",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "targetDonationId",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

## storage.rules

Local path: `C:\Users\premier\StudioProjects\blood-bank\storage.rules`

SHA-256: `059aa92f0d83835bfab8b68e028d726409a6981fd419cab078facc686c4592b6`

```text
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function active() {
      return request.auth != null
        && firestore.exists(/databases/(default)/documents/users/$(request.auth.uid))
        && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.status == 'approved';
    }
    match /certificates/{donorId}/{fileName} {
      allow read: if active() && request.auth.uid == donorId;
      allow delete: if active() && request.auth.uid == donorId;
    }
    match /certificates/{donorId}/{donationId}/certificate.pdf {
      allow read: if active() && request.auth.uid == donorId;
      allow create, update: if active() && request.auth.uid == donorId
        && firestore.exists(/databases/(default)/documents/donations/$(donationId))
        && firestore.get(/databases/(default)/documents/donations/$(donationId)).data.donorId == donorId
        && request.resource.size < 5 * 1024 * 1024 && request.resource.contentType == 'application/pdf';
      allow delete: if active() && request.auth.uid == donorId;
    }
    match /profile_images/{userId}/{fileName} {
      allow read: if active();
      allow create, update: if active() && request.auth.uid == userId
        && request.resource.size < 3 * 1024 * 1024 && request.resource.contentType.matches('image/.*');
      allow delete: if active() && request.auth.uid == userId;
    }
    match /verification_evidence/{userId}/{fileName} {
      allow create, update: if active() && request.auth.uid == userId
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*|application/pdf');
      allow read: if active()
        && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow delete: if active() && request.auth.uid == userId;
    }
    match /awareness_banners/{fileName} {
      allow read: if active();
      allow create, update: if active()
        && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin'
        && request.resource.size < 3 * 1024 * 1024
        && request.resource.contentType.matches('image/(jpeg|png|webp)');
      allow delete: if active()
        && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    match /{allPaths=**} { allow read, write: if false; }
  }
}
```

## firebase.json

Local path: `C:\Users\premier\StudioProjects\blood-bank\firebase.json`

SHA-256: `6e5d77447054c2034572cd38b7502c9913457f373215d17053402470ad0d35b7`

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        ".secret.local",
        ".env.local",
        "test",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ]
    }
  ],
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "functions": {
      "port": 5001
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": false
    },
    "singleProjectMode": true
  }
}
```

## .firebaserc

Local path: `C:\Users\premier\StudioProjects\blood-bank\.firebaserc`

SHA-256: `04465a748ae8b036b7acb9465da6520b36164938bd6ec802bfc8a0efa784f85a`

```json
{
  "projects": {
    "q": "blood-bank-98037"
  },
  "targets": {},
  "etags": {}
}
```

