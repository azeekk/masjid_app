import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationsScreen extends StatelessWidget {
  final String type; // "general" or "nikah"
  const DonationsScreen({super.key, required this.type});

  Future<void> _addDonation(BuildContext context) async {
    final name = TextEditingController(), address = TextEditingController(), amount = TextEditingController();
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Add ${type == 'nikah' ? 'Nikah ' : ''}Donation'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
        TextField(controller: amount, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await FirebaseFirestore.instance.collection('donations').add({
            'name': name.text, 'address': address.text,
            'amount': double.tryParse(amount.text) ?? 0,
            'type': type, 'date': DateTime.now().toIso8601String(),
          });
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type == 'nikah' ? 'Nikah Donations' : 'Donations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDonation(context), child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('donations')
            .where('type', isEqualTo: type).orderBy('date', descending: true).snapshots(),
        builder: (ctx, snap) {
            if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snap.error}', textAlign: TextAlign.center),
            ));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          double total = 0;
          for (var d in snap.data!.docs) { total += (d['amount'] ?? 0); }
          return Column(children: [
            Padding(padding: const EdgeInsets.all(12),
              child: Text('Total: ৳$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))),
            Expanded(child: ListView(children: snap.data!.docs.map((d) => ListTile(
              title: Text(d['name']), subtitle: Text('${d['address']} • ${(d['date'] as String).substring(0, 10)}'),
              trailing: Text('৳${d['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            )).toList())),
          ]);
        },
      ),
    );
  }
}