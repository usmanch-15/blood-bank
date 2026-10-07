import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkflowService {
  static Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable(name)
        .call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }

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
      if (dates.contains(key) && value is num)
        return Timestamp.fromMillisecondsSinceEpoch(value.toInt());
      if (value is Map)
        return value.map(
          (k, v) => MapEntry(k.toString(), convert(v, k.toString())),
        );
      if (value is List) return value.map((v) => convert(v, '')).toList();
      return value;
    }

    return Map<String, dynamic>.from(convert(data, '') as Map);
  }

  static Future<Map<String, dynamic>> request(String id) async =>
      decode(await call('getRequest', {'requestId': id}));
}
