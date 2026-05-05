part of '../../admin_web_dashboard.dart';

class AdminWebRequests extends StatelessWidget {
  const AdminWebRequests({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> requests = const [
    {'patient': 'John Doe', 'bloodGroup': 'O+', 'units': 2, 'hospital': 'City Hospital', 'status': 'Pending'},
    {'patient': 'Jane Smith', 'bloodGroup': 'A-', 'units': 1, 'hospital': 'General Hospital', 'status': 'Approved'},
    {'patient': 'Mike Johnson', 'bloodGroup': 'B+', 'units': 3, 'hospital': 'University Medical', 'status': 'Fulfilled'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              subtitle: Text('${request['bloodGroup']} - ${request['units']} units - ${request['hospital']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(request['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(request['status'], style: TextStyle(color: _getStatusColor(request['status']))),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Approved': return Colors.green;
      case 'Fulfilled': return Colors.blue;
      default: return Colors.grey;
    }
  }
}