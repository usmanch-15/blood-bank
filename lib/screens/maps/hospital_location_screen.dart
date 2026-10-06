import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geo_location_service.dart';

class HospitalLocationScreen extends StatefulWidget {
  final LatLng? initial;
  const HospitalLocationScreen({super.key,this.initial});
  @override
  State<HospitalLocationScreen> createState()=>_HospitalLocationScreenState();
}
class _HospitalLocationScreenState extends State<HospitalLocationScreen>{
  final _map=MapController();
  final _lat=TextEditingController(),_lng=TextEditingController();
  LatLng? _selected;
  String? _error;
  bool _locating=false;
  @override
  void initState(){super.initState();if(widget.initial!=null)_select(widget.initial!);}
  void _select(LatLng p){setState((){_selected=p;_lat.text=p.latitude.toStringAsFixed(6);_lng.text=p.longitude.toStringAsFixed(6);_error=null;});}
  @override
  void dispose(){_lat.dispose();_lng.dispose();_map.dispose();super.dispose();}
  Future<void> _locate()async{setState(()=>_locating=true);try{final p=await GeoLocationService().getCurrentLocation();if(!mounted)return;final point=LatLng(p.latitude,p.longitude);_select(point);_map.move(point,15);}catch(e){if(mounted)setState(()=>_error=e.toString());}finally{if(mounted)setState(()=>_locating=false);}}
  void _manual(){final lat=double.tryParse(_lat.text),lng=double.tryParse(_lng.text);if(lat==null||lng==null||!lat.isFinite||!lng.isFinite||lat.abs()>90||lng.abs()>180){setState(()=>_error='Enter valid latitude and longitude.');return;}_select(LatLng(lat,lng));_map.move(_selected!,15);}
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Hospital Location Selection')),body:Column(children:[
    const Padding(padding:EdgeInsets.all(16),child:Text('Tap the hospital or meeting point on the map. Confirm the pin matches your hospital address. You can also enter coordinates if map tiles are unavailable.')),
    Expanded(child:FlutterMap(mapController:_map,options:MapOptions(initialCenter:widget.initial??const LatLng(30.3753,69.3451),initialZoom:widget.initial==null?5:14,onTap:(_,p)=>_select(p)),children:[TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.usmanch.bloodbank'),if(_selected!=null)MarkerLayer(markers:[Marker(point:_selected!,child:const Icon(Icons.location_pin,color:Colors.red,size:40))]),const SimpleAttributionWidget(source:Text('OpenStreetMap contributors'))])),
    Padding(padding:const EdgeInsets.all(12),child:Column(children:[Row(children:[Expanded(child:TextField(controller:_lat,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'Latitude'))),const SizedBox(width:8),Expanded(child:TextField(controller:_lng,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'Longitude'))),IconButton(onPressed:_manual,tooltip:'Use entered coordinates',icon:const Icon(Icons.check))]),if(_error!=null)Text(_error!),Wrap(spacing:12,children:[TextButton.icon(onPressed:_locating?null:_locate,icon:const Icon(Icons.my_location),label:Text(_locating?'Locating…':'Use my location')),FilledButton(onPressed:_selected==null?null:()=>Navigator.pop(context,_selected),child:const Text('Confirm meeting point'))])])),
  ]));
}
