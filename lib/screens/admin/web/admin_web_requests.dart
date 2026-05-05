import 'package:flutter/material.dart';

class AdminWebRequests extends StatelessWidget {
  const AdminWebRequests({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> requests = [
      {
        'patient': 'Ali Khan',
        'bloodGroup': 'A+',
        'units': 2,
        'hospital': 'City Hospital',
        'status': 'Pending'
      },
      {
        'patient': 'Ahmed Raza',
        'bloodGroup': 'B+',
        'units': 1,
        'hospital': 'DHQ Hospital',
        'status': 'Approved'
      },
      {
        'patient': 'Sara Khan',
        'bloodGroup': 'O-',
        'units': 3,
        'hospital': 'General Hospital',
        'status': 'Fulfilled'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Requests')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.bloodtype, color: Colors.red),
              title: Text(request['patient']),
              subtitle: Text(
                  '${request['bloodGroup']} - ${request['units']} units - ${request['hospital']}'),
              trailing: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(request['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request['status'],
                  style: TextStyle(
                      color: _getStatusColor(request['status']),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Fulfilled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}