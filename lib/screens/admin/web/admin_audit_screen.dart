import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/workflow_service.dart';
import '../../../widgets/paged_records.dart';
class AdminAuditScreen extends StatefulWidget{
  const AdminAuditScreen({super.key});
  @override
  State<AdminAuditScreen> createState()=>_AdminAuditScreenState();
}
class _AdminAuditScreenState extends State<AdminAuditScreen>{
  bool _busy=false;String _collection='audit_logs';
  Future<void> _export()async{setState(()=>_busy=true);try{final items=<dynamic>[];String? cursor;do{final page=await WorkflowService.call('exportPage',{'admin':true,'collection':_collection,'cursor':cursor});items.addAll(page['items'] as List);cursor=page['cursor'];}while(cursor!=null);await Share.share(const JsonEncoder.withIndent('  ').convert({'collection':_collection,'generatedAt':DateTime.now().toIso8601String(),'records':items}),subject:'Blood bank administrative export');}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}finally{if(mounted)setState(()=>_busy=false);}}
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Admin Audit & Export')),body:Column(children:[Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:16,crossAxisAlignment:WrapCrossAlignment.center,children:[DropdownButton<String>(value:_collection,items:['audit_logs','users','blood_requests','donations','sosRequests','misuse_reports','feedback'].map((c)=>DropdownMenuItem(value:c,child:Text(c.replaceAll('_',' ')))).toList(),onChanged:_busy?null:(v)=>setState(()=>_collection=v!)),FilledButton.icon(onPressed:_busy?null:_export,icon:const Icon(Icons.download),label:Text(_busy?'Preparing export…':'Export all pages'))])),Expanded(child:PagedRecords(query:FirebaseFirestore.instance.collection('audit_logs').orderBy('createdAt',descending:true),itemBuilder:(context,doc){final d=doc.data();return ListTile(title:Text(d['action']??'Event'),subtitle:Text('Actor: ${d['actorId']??d['viewedBy']??'system'}\n${d['collection']??''} ${d['recordId']??d['requestId']??''}'),isThreeLine:true);})),]));
}
