import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  Future<void> _addStudent(BuildContext context) async {
    final name = TextEditingController(), sclass = TextEditingController(), fee = TextEditingController();
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Student'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Student Name')),
        TextField(controller: sclass, decoration: const InputDecoration(labelText: 'Class')),
        TextField(controller: fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Fee')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await FirebaseFirestore.instance.collection('students').add({
            'name': name.text, 'class': sclass.text,
            'totalFee': double.tryParse(fee.text) ?? 0, 'payments': [],
          });
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _addPayment(String studentId, double currentBalance) async {
    final amount = TextEditingController();
    await showDialog(context: navigatorKey.currentContext!, builder: (ctx) => AlertDialog(
      title: Text('Collect Payment (Balance: ৳$currentBalance)'),
      content: TextField(controller: amount, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await FirebaseFirestore.instance.collection('students').doc(studentId).update({
            'payments': FieldValue.arrayUnion([{
              'amount': double.tryParse(amount.text) ?? 0,
              'date': DateTime.now().toIso8601String(),
            }])
          });
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Collect')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Madrasa Students')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addStudent(context), child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').orderBy('name').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(children: snap.data!.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final totalFee = (data['totalFee'] ?? 0).toDouble();
            final given = (data['payments'] as List).fold<double>(
                0, (s, p) => s + (p['amount'] as num));
            final balance = totalFee - given;
            return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text('${data['name']} (${data['class']})'),
                subtitle: Text('Fee: ৳$totalFee | Given: ৳$given'),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('৳$balance', style: TextStyle(
                    color: balance > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(balance > 0 ? 'Due' : 'Paid', style: const TextStyle(fontSize: 11)),
                ]),
                onTap: balance > 0 ? () => _addPayment(d.id, balance) : null,
              ),
            );
          }).toList());
        },
      ),
    );
  }
}

// Add at top of main.dart for showing dialogs from anywhere:
final navigatorKey = GlobalKey<NavigatorState>();
// and in MaterialApp: navigatorKey: navigatorKey,