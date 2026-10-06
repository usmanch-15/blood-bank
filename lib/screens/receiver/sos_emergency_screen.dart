import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/settings_service.dart';
import '../../services/workflow_service.dart';
import '../../utils/validators.dart';
import '../maps/hospital_location_screen.dart';
import '../requests/request_tracking_screen.dart';
import '../requests/request_list_screen.dart';
class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});
  @override
  State<SosEmergencyScreen> createState()=>_SosEmergencyScreenState();
}
class _SosEmergencyScreenState extends State<SosEmergencyScreen>{
  final _form=GlobalKey<FormState>();
  final _hospital=TextEditingController(),_phone=TextEditingController();
  LatLng? _point;
  String _group='O+',_urgency='critical';
  String? _error;
  int _count=0;
  bool _sending=false;
  Timer? _timer;
  @override
  void initState(){super.initState();_loadPhone();}
  Future<void> _loadPhone()async{try{final phone=await SettingsService().getPhoneOnce();if(mounted&&_phone.text.isEmpty)_phone.text=phone??'';}catch(_){}}
  @override
  void dispose(){_timer?.cancel();_hospital.dispose();_phone.dispose();super.dispose();}
  Future<void> _pick()async{final p=await Navigator.push<LatLng>(context,MaterialPageRoute(builder:(_)=>HospitalLocationScreen(initial:_point)));if(p!=null&&mounted)setState(()=>_point=p);}
  void _start(){if(!_form.currentState!.validate())return;if(_point==null){setState(()=>_error='Select the hospital or emergency meeting point.');return;}setState((){_count=10;_error=null;});_timer=Timer.periodic(const Duration(seconds:1),(t){if(!mounted){t.cancel();return;}setState(()=>_count--);if(_count==0){t.cancel();_send();}});}
  Future<void> _send()async{setState(()=>_sending=true);try{final result=await WorkflowService.call('createSosAlert',{'bloodGroup':_group,'urgency':_urgency,'latitude':_point!.latitude,'longitude':_point!.longitude,'hospitalName':_hospital.text.trim(),'contactNumber':AppValidators.normalizePhone(_phone.text)});if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>RequestTrackingScreen(requestId:result['requestId'])));}catch(e){if(mounted)setState(()=>_error=e.toString());}finally{if(mounted)setState(()=>_sending=false);}}
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('SOS Emergency')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[
    const Text('An SOS requests one urgent donation. For multiple units, create a blood request. Donor response is voluntary; contact emergency services when needed.'),
    DropdownButtonFormField<String>(initialValue:_group,decoration:const InputDecoration(labelText:'Blood group needed'),items:['A+','A-','B+','B-','AB+','AB-','O+','O-'].map((g)=>DropdownMenuItem(value:g,child:Text(g))).toList(),onChanged:_sending||_count>0?null:(v)=>setState(()=>_group=v!)),
    DropdownButtonFormField<String>(initialValue:_urgency,decoration:const InputDecoration(labelText:'Urgency'),items:['urgent','critical','life_threatening'].map((g)=>DropdownMenuItem(value:g,child:Text(g.replaceAll('_',' ')))).toList(),onChanged:_sending||_count>0?null:(v)=>setState(()=>_urgency=v!)),
    TextFormField(controller:_hospital,maxLength:100,decoration:const InputDecoration(labelText:'Hospital / meeting point'),validator:(v)=>v==null||v.trim().isEmpty?'Enter a hospital or meeting point':null,enabled:!_sending&&_count==0),
    TextFormField(controller:_phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Contact number'),validator:AppValidators.validatePhone,enabled:!_sending&&_count==0),
    OutlinedButton.icon(onPressed:_sending||_count>0?null:_pick,icon:const Icon(Icons.pin_drop),label:Text(_point==null?'Select emergency location':'Meeting point confirmed — change')),
    if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
    if(_count>0)...[Text('Sending in $_count seconds',textAlign:TextAlign.center),OutlinedButton(onPressed:(){_timer?.cancel();setState(()=>_count=0);},child:const Text('Cancel countdown'))]else FilledButton(onPressed:_sending?null:_start,child:Text(_sending?'Saving SOS…':'Start SOS countdown')),
    TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RequestListScreen(mode:'sos'))),child:const Text('My active SOS & history')),
    OutlinedButton.icon(onPressed:()async{try{if(!await launchUrl(Uri(scheme:'tel',path:'1122')))throw StateError('Dialer unavailable.');}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}},icon:const Icon(Icons.call),label:const Text('Call Rescue 1122')),
  ])));
}
