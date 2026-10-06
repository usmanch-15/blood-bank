import 'workflow_service.dart';
class ReportService {
 Future<void> submitReport({required String reason,String? targetUserId,String? targetRequestId,String? details,bool feedback=false}) async {
 await WorkflowService.call('submitReport',{'title':reason,'description':details??'','reportedUserId':targetUserId,'targetRequestId':targetRequestId,'feedback':feedback});
 }
}
