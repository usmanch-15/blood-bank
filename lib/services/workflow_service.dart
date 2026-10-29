import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';

class WorkflowService {
  static const cloudflareStage1Enabled = bool.fromEnvironment(
    'CLOUDFLARE_STAGE1_ENABLED',
    defaultValue: false,
  );
  static const cloudflareStage2Enabled = bool.fromEnvironment(
    'CLOUDFLARE_STAGE2_ENABLED',
    defaultValue: false,
  );
  static const cloudflareStage3Enabled = bool.fromEnvironment(
    'CLOUDFLARE_STAGE3_ENABLED',
    defaultValue: false,
  );
  static const _stage1Workflows = {
    'createBloodRequest',
    'acceptDonation',
    'declineRequest',
    'updateAssignment',
    'closeRequest',
    'getRequest',
    'discoverRequests',
    'findDonors',
    'notifyRequest',
  };
  static const _stage2Workflows = {
    'markConversationRead',
    'blockUser',
    'unblockUser',
    'reportConversation',
    'sharePhoneNumber',
    'notifyChatMessage',
  };
  static const _stage3Workflows = {
    'createSosAlert',
    'getSos',
    'resolveSos',
    'confirmDonation',
    'donationHistory',
    'acknowledgeDonation',
    'disputeDonation',
    'submitDonationDispute',
    'getDonorContact',
  };

  static const region = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );
  // Keep the default aligned with Functions' default deployment region.
  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: region);

  static Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    if (_stage1Workflows.contains(name)) {
      return ApiClient.instance.call(name, data);
    }
    if ((cloudflareStage2Enabled && _stage2Workflows.contains(name)) ||
        (cloudflareStage3Enabled && _stage3Workflows.contains(name))) {
      return _callCloudflare(name, data);
    }
    try {
      final result = await functions.httpsCallable(name).call(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[function] name=$name code=${error.code} '
          'project=${Firebase.app().options.projectId} region=$region',
        );
      }
      rethrow;
    }
  }

  static Future<void> notifyChatMessage({
    required String conversationId,
    required String messageId,
  }) async {
    if (!cloudflareStage2Enabled) return;
    await call('notifyChatMessage', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  static Future<Map<String, dynamic>> _callCloudflare(
    String name,
    Map<String, dynamic> data,
  ) => ApiClient.instance.call(name, data);

  static Map<String, dynamic> decode(Map<String, dynamic> data) {
    const dates = {
      'createdAt',
      'requiredBy',
      'fulfilledAt',
      'acceptedAt',
      'completedAt',
      'updatedAt',
      'triggerTime',
      'resolvedAt',
      'closedAt',
      'donationDate',
      'reportedAt',
      'reviewedAt',
      'nextEligibleDate',
    };
    dynamic convert(dynamic value, String key) {
      if (dates.contains(key) && value is num) {
        return Timestamp.fromMillisecondsSinceEpoch(value.toInt());
      }
      if (value is Map) {
        return value.map(
          (k, v) => MapEntry(k.toString(), convert(v, k.toString())),
        );
      }
      if (value is List) return value.map((v) => convert(v, '')).toList();
      return value;
    }

    return Map<String, dynamic>.from(convert(data, '') as Map);
  }

  static Future<Map<String, dynamic>> request(String id) async =>
      decode(await call('getRequest', {'requestId': id}));
}
