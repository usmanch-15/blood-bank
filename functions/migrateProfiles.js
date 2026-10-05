// Explicit, operator-run migration. Defaults to DRY RUN; never run automatically.
// GOOGLE_CLOUD_PROJECT and Application Default Credentials must target the
// reviewed environment. Take a Firestore export first. No credentials in source.
const admin=require('./firebaseAdmin');
if (!process.env.GOOGLE_CLOUD_PROJECT) throw Error('Set GOOGLE_CLOUD_PROJECT explicitly.');
const apply=process.argv.includes('--apply');
admin.initializeApp({projectId:process.env.GOOGLE_CLOUD_PROJECT});
const db=admin.firestore();
async function run() {
  let last, count=0;
  for(;;) {
    let q=db.collection('users').orderBy(admin.firestore.FieldPath.documentId()).limit(100);
    if(last) q=q.startAfter(last);
    const page=await q.get();
    for(const doc of page.docs) {
      const d=doc.data();
      const consent=d.locationSharingEnabled===true;
      const update={isDonor:d.isDonor===true||d.role==='donor',isReceiver:d.isReceiver===true||d.role==='receiver',
        isAvailable:d.isAvailable===true,locationSharingEnabled:consent,
        latitude:consent&&Number.isFinite(d.latitude)?Math.round(d.latitude*100)/100:null,
        longitude:consent&&Number.isFinite(d.longitude)?Math.round(d.longitude*100)/100:null};
      const batch=db.batch();
      const contact={};
      for(const key of ['phoneNumber','cnic']) if(d[key]) contact[key]=d[key];
      // Never overwrite a newer private contact with a legacy public value.
      const existing=(await doc.ref.collection('private').doc('contact').get()).data()||{};
      for(const key of Object.keys(existing)) delete contact[key];
      if(Object.keys(contact).length) batch.set(doc.ref.collection('private').doc('contact'),contact,{merge:true});
      if(d.fcmToken) batch.set(doc.ref.collection('private').doc('device'),{fcmToken:d.fcmToken},{merge:true});
      for(const key of ['phoneNumber','cnic','phoneVerified','fcmToken','fcmUpdatedAt']) update[key]=admin.firestore.FieldValue.delete();
      batch.update(doc.ref,update);
      if(apply) await batch.commit();
      count++;
    }
    if(page.size<100) break;
    last=page.docs[page.size-1];
  }
  console.log(`${apply?'Updated':'Dry-run reviewed'} ${count} profiles. No account statuses or admin roles changed.`);
}
run().then(()=>admin.app().delete()).catch(e=>{console.error(e.message);process.exitCode=1;});
