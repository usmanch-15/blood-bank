import 'package:flutter/material.dart';
import '../../services/workflow_service.dart';
import '../requests/request_tracking_screen.dart';
class SosAlertDetailScreen extends StatefulWidget {
  final String requestId;
  const SosAlertDetailScreen({super.key,required this.requestId});
  @override
  State<SosAlertDetailScreen> createState()=>_SosAlertDetailScreenState();
}
class _SosAlertDetailScreenState extends State<SosAlertDetailScreen>{
  late Future<Map<String,dynamic>> _sos;
  @override
  void initState(){super.initState();_sos=WorkflowService.call('getSos',{'sosId':widget.requestId});}
  @override
  Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:_sos,builder:(context,s){if(s.hasData&&s.data!['requestId']!=null)return RequestTrackingScreen(requestId:s.data!['requestId']);return Scaffold(appBar:AppBar(title:const Text('SOS alert')),body:Center(child:s.connectionState==ConnectionState.waiting?const CircularProgressIndicator():Column(mainAxisSize:MainAxisSize.min,children:[Text(s.hasError?'Unable to open this SOS.':'This older SOS requires administrator assistance.'),TextButton(onPressed:()=>setState(()=>_sos=WorkflowService.call('getSos',{'sosId':widget.requestId})),child:const Text('Retry'))])));});
}
