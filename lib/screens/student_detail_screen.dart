import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  Future<void> _unmark(String monthKey) async {
    await FirebaseFirestore.instance.collection('students').doc(student.id).update({
      'feeStatus.$monthKey': FieldValue.delete()
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(student.name)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('students').doc(student.id).snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final s = Student.fromDoc(snap.data!.id, snap.data!.data() as Map<String, dynamic>);
          return Column(children: [
            Card(margin: const EdgeInsets.all(12), child: ListTile(
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Class ${s.sclass}'),
              trailing: Text('৳${s.monthlyFee}/mo', style: const TextStyle(fontSize: 16, color: Colors.green)),
            )),
            Expanded(child: _monthList(s)),
          ]);
        },
      ),
    );
  }

  Widget _monthList(Student s) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return DateFormat('yyyy-MM').format(d);
    });
    return ListView.builder(
      itemCount: months.length,
      itemBuilder: (ctx, i) {
        final key = months[i];
        final paid = s.isPaidFor(key);
        final st = s.feeStatus[key];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(DateFormat('MMMM yyyy').format(DateTime.parse('$key-01'))),
            subtitle: paid ? Text('${st?['method']} • by ${st?['collectedBy'] ?? 'admin'}') : null,
            trailing: paid
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('✅ ৳${st?['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.undo, size: 20), onPressed: () => _unmark(key)),
                  ])
                : const Text('❌ Unpaid', style: TextStyle(color: Colors.red)),
          ),
        );
      },
    );
  }
}