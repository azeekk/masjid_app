import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/staff.dart';
import 'staff_detail_screen.dart';

class StaffScreen extends StatelessWidget {
  final String role;       // "teacher", "imam", "khatheeb"
  final String title;      // "Teachers", "Imam", "Khatheeb"
  const StaffScreen({super.key, required this.role, required this.title});

  String get monthKey => DateFormat('yyyy-MM').format(DateTime.now());
  String get monthLabel => DateFormat('MMMM yyyy').format(DateTime.now());

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

  Future<void> _paySalary(BuildContext context, Staff s) async {
    final amount = TextEditingController(text: s.monthlySalary.toStringAsFixed(0));
    final note = TextEditingController();
    String method = 'Cash';
    final payer = FirebaseAuth.instance.currentUser?.email ?? 'admin';

    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Pay Salary — ${s.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(monthLabel, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: method,
            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
            items: ['Cash', 'Bank Transfer', 'bKash', 'Nagad']
                .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => method = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('staff').doc(s.id).update({
              'salaryStatus.$monthKey': {
                'paid': true,
                'amount': double.tryParse(amount.text) ?? 0,
                'date': DateTime.now().toIso8601String(),
                'method': method,
                'paidBy': payer,
                'note': note.text,
              }
            });
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('✅ Salary paid to ${s.name}: ৳${amount.text} ($method)')));
            }
          }, child: const Text('Pay')),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text('$title — Salaries'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.calendar_month), text: 'This Month'),
            Tab(icon: Icon(Icons.people), text: 'All Staff'),
          ])),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addStaff(context), child: const Icon(Icons.add)),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('staff')
              .where('role', isEqualTo: role).orderBy('name').snapshots(),
          builder: (ctx, snap) {
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final staff = snap.data!.docs
                .map((d) => Staff.fromDoc(d.id, d.data() as Map<String, dynamic>)).toList();
            return TabBarView(children: [
              _thisMonthView(context, staff),
              _allStaffView(context, staff),
            ]);
          },
        ),
      ),
    );
  }

  Widget _thisMonthView(BuildContext context, List<Staff> staff) {
    final paidList = staff.where((s) => s.isPaidFor(monthKey)).toList();
    final unpaid = staff.where((s) => !s.isPaidFor(monthKey)).toList();
    final paidTotal = paidList.fold<double>(0,
        (sum, s) => sum + (s.salaryStatus[monthKey]?['amount'] ?? 0).toDouble());
    final expected = staff.fold<double>(0, (sum, s) => sum + s.monthlySalary);

    return Column(children: [
      Card(margin: const EdgeInsets.all(12), color: Colors.green[50],
        child: Padding(padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Paid', '৳$paidTotal', Colors.green),
            _stat('Expected', '৳$expected', Colors.grey[700]!),
            _stat('Unpaid', '${unpaid.length}', Colors.red),
          ])),
      ),
      Expanded(child: ListView(children: [
        // 👇 Unpaid shown FIRST — this is your "who still needs paying" list
        ...unpaid.map((s) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(s.name), subtitle: Text(monthLabel),
            trailing: ElevatedButton(
              onPressed: () => _paySalary(context, s),
              child: Text('Pay ৳${s.monthlySalary.toStringAsFixed(0)}')),
          ),
        )),
        if (unpaid.isNotEmpty && paidList.isNotEmpty)
          const Padding(padding: EdgeInsets.all(8),
            child: Text('— Paid —', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        ...paidList.map((s) {
          final st = s.salaryStatus[monthKey];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              title: Text(s.name),
              subtitle: Text('${st?['method']} • by ${st?['paidBy'] ?? 'admin'}'
                  '${(st?['note'] ?? '').toString().isNotEmpty ? '\n📝 ${st?['note']}' : ''}'),
              isThreeLine: (st?['note'] ?? '').toString().isNotEmpty,
              trailing: Text('✅ ৳${st?['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ])),
    ]);
  }

  Widget _stat(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  ]);

  Widget _allStaffView(BuildContext context, List<Staff> staff) {
    return ListView(children: staff.map((s) => Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(s.name), subtitle: Text('৳${s.monthlySalary}/month'),
        trailing: s.isPaidFor(monthKey)
            ? const Text('✅', style: TextStyle(fontSize: 20))
            : const Text('❌', style: TextStyle(fontSize: 20)),
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => StaffDetailScreen(staff: s, title: title))),
      ),
    )).toList());
  }
}