import '../../widgets/dashboard_components.dart';
import '../../utils/feedback.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/settings_service.dart';
import '../../services/workflow_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/validators.dart';
import '../../utils/input_formatters.dart';
import '../maps/hospital_location_screen.dart';
import '../requests/request_list_screen.dart';
import 'sos_status_screen.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});
  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> {
  final _form = GlobalKey<FormState>();
  final _hospital = TextEditingController(), _phone = TextEditingController();
  final _hospitalFocusNode = FocusNode();
  LatLng? _point;
  String _hospitalAddress = '';
  String _group = 'O+', _urgency = 'critical';
  String? _error;
  int _count = 0;
  bool _sending = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    try {
      final phone = await SettingsService().getPhoneOnce();
      if (mounted && _phone.text.isEmpty) _phone.text = phone ?? '';
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hospital.dispose();
    _hospitalFocusNode.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final selection = await Navigator.push<LocationSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalLocationScreen(initial: _point),
      ),
    );
    if (selection != null && mounted) {
      setState(() {
        _point = selection.point;
        _hospital.text = selection.hospitalName;
        _hospitalAddress = selection.address;
      });
      if (selection.hospitalName.isEmpty) {
        FocusScope.of(context).requestFocus(_hospitalFocusNode);
      }
    }
  }

  void _start() {
    if (!_form.currentState!.validate()) return;
    if (_point == null) {
      setState(
        () => _error = 'Select the hospital or emergency meeting point.',
      );
      return;
    }
    setState(() {
      _count = 10;
      _error = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _count--);
      if (_count == 0) {
        t.cancel();
        _send();
      }
    });
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final result = await WorkflowService.call('createSosAlert', {
        'bloodGroup': _group,
        'urgency': _urgency,
        'latitude': _point!.latitude,
        'longitude': _point!.longitude,
        'hospitalName': _hospital.text.trim(),
        'hospitalAddress': _hospitalAddress,
        'contactNumber': AppValidators.normalizePhone(_phone.text),
      });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => SosStatusScreen(
                  sosId: result['id'] as String,
                  requestId: result['requestId'] as String,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppFeedback.message(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).sosEmergency)),
    body: Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          DashboardPanel(
            tint: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: .25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sos, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dashboardText(
                          context,
                          'Reach nearby donors',
                          'قریبی عطیہ دہندگان کو اطلاع دیں',
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  dashboardText(
                    context,
                    'An SOS requests one urgent donation. For multiple units, create a blood request. Donor response is voluntary; contact emergency services when needed.',
                    'ایس او ایس ایک فوری عطیے کی درخواست ہے۔ زیادہ یونٹس کے لیے خون کی درخواست بنائیں۔ عطیہ رضاکارانہ ہے؛ ضرورت ہو تو ایمرجنسی خدمات سے رابطہ کریں۔',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _group,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).bloodGroupNeeded,
            ),
            items:
                ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
            onChanged:
                _sending || _count > 0
                    ? null
                    : (v) => setState(() => _group = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _urgency,
            decoration: const InputDecoration(labelText: 'Urgency'),
            items:
                ['urgent', 'critical', 'life_threatening']
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
            onChanged:
                _sending || _count > 0
                    ? null
                    : (v) => setState(() => _urgency = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _hospital,
            focusNode: _hospitalFocusNode,
            inputFormatters: AppInputFormatters.hospitalName,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).hospitalMeetingPoint,
            ),
            validator: AppValidators.validateHospitalName,
            enabled: !_sending && _count == 0,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: AppInputFormatters.phone,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).contactNumber,
            ),
            validator: AppValidators.validatePhone,
            enabled: !_sending && _count == 0,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _sending || _count > 0 ? null : _pick,
            icon: const Icon(Icons.pin_drop),
            label: Text(
              _point == null
                  ? 'Select emergency location'
                  : 'Meeting point confirmed — change',
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_count > 0) ...[
            Text('Sending in $_count seconds', textAlign: TextAlign.center),
            OutlinedButton(
              onPressed: () {
                _timer?.cancel();
                setState(() => _count = 0);
              },
              child: Text(AppLocalizations.of(context).cancel),
            ),
          ] else
            FilledButton(
              onPressed: _sending ? null : _start,
              child: Text(_sending ? 'Saving SOS…' : 'Start SOS countdown'),
            ),
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestListScreen(mode: 'sos'),
                  ),
                ),
            child: const Text('My active SOS & history'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                if (!await launchUrl(Uri(scheme: 'tel', path: '1122'))) {
                  throw StateError('Dialer unavailable.');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppFeedback.message(e))),
                  );
                }
              }
            },
            icon: const Icon(Icons.call),
            label: const Text('Call Rescue 1122'),
          ),
        ],
      ),
    ),
  );
}
