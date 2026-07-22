import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../controllers/receiver_controller.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> {
  bool _isSosActive = false;
  int _countdown = 10;
  bool _isSending = false;
  String _selectedBloodGroup = 'O+';
  String _selectedUrgency = 'critical';
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _urgencyLevels = ['urgent', 'critical', 'life_threatening'];

  @override
  void initState() {
    super.initState();
    // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    // SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _startSosCountdown() {
    if (_isSosActive) return;

    setState(() {
      _isSosActive = true;
      _countdown = 10;
      _isSending = false;
    });

    // Start countdown
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
        return true;
      } else {
        // Auto-send when countdown reaches 0
        _sendSosAlert();
        return false;
      }
    });
  }

  void _cancelSos() {
    setState(() {
      _isSosActive = false;
      _countdown = 10;
      _isSending = false;
    });
  }

  // ✅ FIX (Issue #2 / #19 / #20): previously this just did a fake
  // Future.delayed(2 seconds) and showed a success message — no donor
  // search, no Firestore write, no notification was ever sent. Now it
  // calls ReceiverController.sendSosAlert(), which:
  //   1. Gets the receiver's current GPS location
  //   2. Searches for eligible donors within 15km (auto-expands to 30km
  //      if none found — see geo_location_service.dart)
  //   3. Writes a sosRequests document
  //   4. Sends a push notification to every matched donor
  void _sendSosAlert() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _isSosActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to send an SOS alert.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final controller = context.read<ReceiverController>();
      await controller.sendSosAlert(
        receiverId: uid,
        bloodGroup: _selectedBloodGroup,
      );

      if (!mounted) return;

      final matchedCount = controller.nearbyDonors.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  matchedCount > 0
                      ? 'SOS Alert sent to $matchedCount nearby donor(s)!'
                      : 'SOS Alert saved, but no eligible donors were found nearby yet. We will keep trying.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _isSosActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send SOS alert: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBloodGroupSelector() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bloodtype, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'Blood Group Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bloodGroups.map((group) {
                bool isSelected = _selectedBloodGroup == group;
                return ChoiceChip(
                  label: Text(group),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedBloodGroup = group;
                    });
                  },
                  selectedColor: Colors.red.withOpacity(0.2),
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? Colors.red : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencySelector() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Emergency Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedUrgency,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _urgencyLevels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(
                    level.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: level == 'critical' || level == 'life_threatening'
                          ? Colors.red
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUrgency = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          if (_isSosActive && !_isSending)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'COUNTDOWN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Alert will be sent automatically',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

          if (_isSending)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'SENDING SOS ALERT...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Notifying nearby donors and hospitals',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),

          // SOS Button
          GestureDetector(
            onTap: _isSosActive ? _cancelSos : _startSosCountdown,
            onLongPress: _isSending ? null : _startSosCountdown,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSosActive ? 200 : 220,
              height: _isSosActive ? 200 : 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSosActive ? Colors.red.shade700 : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(_isSosActive ? 0.5 : 0.3),
                    blurRadius: _isSosActive ? 30 : 20,
                    spreadRadius: _isSosActive ? 10 : 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSosActive ? Icons.cancel : Icons.warning,
                    size: _isSosActive ? 60 : 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSosActive ? 'CANCEL SOS' : 'PRESS FOR SOS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (_isSosActive && !_isSending)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Tap to cancel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (!_isSosActive && !_isSending)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'How SOS Works:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Press to start 10-second countdown\n'
                        '• Alert sends automatically\n'
                        '• Nearby donors notified\n'
                        '• Emergency contacts called\n'
                        '• Hospital alert sent',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Long press for instant SOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.emergency, size: 24),
            SizedBox(width: 10),
            Text('SOS EMERGENCY'),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (_isSosActive)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () {
                // Simulate emergency call
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Emergency Call'),
                    content: const Text('Calling nearest emergency contact...'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Emergency call initiated'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Call Now'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'USE ONLY IN LIFE-THREATENING SITUATIONS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Blood Group Selector
            _buildBloodGroupSelector(),
            const SizedBox(height: 16),

            // Urgency Selector
            _buildUrgencySelector(),
            const SizedBox(height: 20),

            // Location Info
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Your Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lahore, Pakistan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Update Location'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location updated (Demo Mode)'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // SOS Button
            Center(
              child: _buildSosButton(),
            ),

            const SizedBox(height: 20),

            // Emergency Contacts
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contact_phone, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Contacts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      title: const Text('Ambulance'),
                      subtitle: const Text('1020'),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {},
                      ),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.local_hospital, color: Colors.white, size: 20),
                      ),
                      title: const Text('Nearest Hospital'),
                      subtitle: const Text('City Hospital'),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: Colors.orange),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}