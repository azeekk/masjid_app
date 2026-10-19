import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffScreen extends StatelessWidget {
  final String role; // "teacher", "imam", "khatheeb"
  final String title;
  const StaffScreen({super.key, required this.role, required this.title});

  String get monthKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  Future<void> _addStaff(BuildContext context) async {
    final name = TextEditingController(), salary = TextEditingController();
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Add $title'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: salary, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monthly Salary')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await FirebaseFirestore.instance.collection('staff').add({
            'name': name.text, 'role': role,
            'monthlySalary': double.tryParse(salary.text) ?? 0, 'salaryStatus': {},
          });
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$title Salaries')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addStaff(context), child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('staff').where('role', isEqualTo: role).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(children: snap.data!.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final salary = (data['monthlySalary'] ?? 0).toDouble();
            final status = Map<String, dynamic>.from(data['salaryStatus'] ?? {});
            final paid = (status[monthKey]?['paid'] ?? false) == true;
            return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text(data['name']),
                subtitle: Text('Salary: ৳$salary/month'),
                trailing: paid
                    ? const Text('✅ Paid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                    : ElevatedButton(child: const Text('Pay'),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('staff').doc(d.id).update({
                            'salaryStatus.$monthKey': {'paid': true, 'amount': salary,
                              'date': DateTime.now().toIso8601String()}
                          });
                        }),
              ),
            );
          }).toList());
        },
      ),
    );
  }
}