part of '../../admin_web_dashboard.dart';

class AdminWebUsers extends StatelessWidget {
  const AdminWebUsers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Text('U${index + 1}'),
              ),
              title: Text('User ${index + 1}'),
              subtitle: Text('user${index + 1}@example.com'),
              trailing: Chip(
                label: Text(index % 2 == 0 ? 'Donor' : 'Receiver'),
                backgroundColor: index % 2 == 0 ? Colors.green.shade100 : Colors.blue.shade100,
              ),
            ),
          );
        },
      ),
    );
  }
}