import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  String get monthKey => DateFormat('yyyy-MM').format(DateTime.now());
  String get monthLabel => DateFormat('MMMM yyyy').format(DateTime.now());

  // ---------- Add student ----------
  Future<void> _addStudent(BuildContext context) async {
    final name = TextEditingController(),
        sclass = TextEditingController(),
        fee = TextEditingController(text: '500');
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Student'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Student Name')),
        TextField(controller: sclass, decoration: const InputDecoration(labelText: 'Class')),
        TextField(controller: fee, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monthly Fee')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await FirebaseFirestore.instance.collection('students').add({
            'name': name.text, 'class': sclass.text,
            'monthlyFee': double.tryParse(fee.text) ?? 0, 'feeStatus': {},
          });
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  // ---------- Collect fee (one-tap from collection view) ----------
  Future<void> _collect(BuildContext context, Student s) async {
    final amount = TextEditingController(text: s.monthlyFee.toStringAsFixed(0));
    String method = 'Cash';
    final collector = FirebaseAuth.instance.currentUser?.email ?? 'admin';

    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Collect Fee — ${s.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(monthLabel, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: method,
            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
            items: ['Cash', 'bKash', 'Nagad']
                .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => method = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('students').doc(s.id).update({
              'feeStatus.$monthKey': {
                'paid': true,
                'amount': double.tryParse(amount.text) ?? 0,
                'date': DateTime.now().toIso8601String(),
                'method': method,
                'collectedBy': collector,
              }
            });
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('✅ ৳${amount.text} received from ${s.name} ($method)')));
            }
          }, child: const Text('Collect')),
        ],
      ),
    ));
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Madrasa Students'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.calendar_month), text: 'This Month'),
            Tab(icon: Icon(Icons.people), text: 'All Students'),
          ]),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addStudent(context), child: const Icon(Icons.add)),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').orderBy('name').snapshots(),
          builder: (ctx, snap) {
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final students = snap.data!.docs
                .map((d) => Student.fromDoc(d.id, d.data() as Map<String, dynamic>)).toList();
            return TabBarView(children: [
              _collectionView(context, students),
              _allStudentsView(context, students),
            ]);
          },
        ),
      ),
    );
  }

  // ---------- Tab 1: This Month collection ----------
  Widget _collectionView(BuildContext context, List<Student> students) {
    final paidStudents = students.where((s) => s.isPaidFor(monthKey)).toList();
    final unpaid = students.where((s) => !s.isPaidFor(monthKey)).toList();
    final collected = paidStudents.fold<double>(0,
        (sum, s) => sum + (s.feeStatus[monthKey]?['amount'] ?? 0).toDouble());
    final expected = students.fold<double>(0, (sum, s) => sum + s.monthlyFee);

    return Column(children: [
      // Summary card
      Card(
        margin: const EdgeInsets.all(12),
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Collected', '৳$collected', Colors.green),
            _stat('Expected', '৳$expected', Colors.grey[700]!),
            _stat('Unpaid', '${unpaid.length}', Colors.red),
          ]),
        ),
      ),
      Expanded(child: ListView(children: [
        // Unpaid first (collection day priority)
        ...unpaid.map((s) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(s.name), subtitle: Text('Class ${s.sclass}'),
            trailing: ElevatedButton(
              onPressed: () => _collect(context, s),
              child: Text('Collect ৳${s.monthlyFee.toStringAsFixed(0)}')),
          ),
        )),
        if (unpaid.isNotEmpty && paidStudents.isNotEmpty)
          const Padding(padding: EdgeInsets.all(8),
            child: Text('— Paid —', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        ...paidStudents.map((s) {
          final st = s.feeStatus[monthKey];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              title: Text(s.name), subtitle: Text('Class ${s.sclass} • ${st?['method'] ?? ''} • ${st?['collectedBy'] ?? ''}'),
              trailing: Text('✅ ৳${st?['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ])),
    ]);
  }

  Widget _stat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }

  // ---------- Tab 2: All students ----------
  Widget _allStudentsView(BuildContext context, List<Student> students) {
    return ListView(children: students.map((s) => Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(s.name), subtitle: Text('Class ${s.sclass} • ৳${s.monthlyFee}/month'),
        trailing: s.isPaidFor(monthKey)
            ? const Text('✅', style: TextStyle(fontSize: 20))
            : const Text('❌', style: TextStyle(fontSize: 20)),
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => StudentDetailScreen(student: s))),
      ),
    )).toList());
  }
}