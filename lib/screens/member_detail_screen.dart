import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import 'member_form_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  final Member member;
  const MemberDetailScreen({super.key, required this.member});

  String get _currentMonth => DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> _markPaid(String monthKey, double amount) async {
    await FirebaseFirestore.instance.collection('members').doc(member.id).update({
      'monthlyStatus.$monthKey': {
        'paid': true, 'amount': amount,
        'date': DateTime.now().toIso8601String(),
      }
    });
  }

  Future<void> _unmark(String monthKey) async {
    await FirebaseFirestore.instance.collection('members').doc(member.id).update({
      'monthlyStatus.$monthKey': FieldValue.delete()
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(member.name), actions: [
        IconButton(icon: const Icon(Icons.edit),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MemberFormScreen(member: member)))),
      ]),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('members').doc(member.id).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final m = Member.fromDoc(snap.data!.id, snap.data!.data() as Map<String, dynamic>);
          return Column(children: [
            Card(margin: const EdgeInsets.all(12), child: ListTile(
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${m.address}\n${m.phone}'),
              isThreeLine: true,
              trailing: Text('৳${m.monthlyAmount}/mo', style: const TextStyle(fontSize: 16, color: Colors.green)),
            )),
            Expanded(child: _buildMonthList(m)),
          ]);
        },
      ),
    );
  }

  Widget _buildMonthList(Member m) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return DateFormat('yyyy-MM').format(d);
    });

    return ListView.builder(
      itemCount: months.length,
      itemBuilder: (ctx, i) {
        final key = months[i];
        final paid = m.isPaidFor(key);
        final amount = (m.monthlyStatus[key]?['amount'] ?? 0).toString();
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(DateFormat('MMMM yyyy').format(DateTime.parse('$key-01'))),
            trailing: paid
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('✅ Donated ৳$amount', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.undo, size: 20), onPressed: () => _unmark(key)),
                  ])
                : ElevatedButton(
                    onPressed: () => _markPaid(key, m.monthlyAmount),
                    child: Text('Mark Paid ৳${m.monthlyAmount}')),
          ),
        );
      },
    );
  }
}