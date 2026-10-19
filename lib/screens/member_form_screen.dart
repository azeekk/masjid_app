import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';

class MemberFormScreen extends StatefulWidget {
  final Member? member;
  const MemberFormScreen({super.key, this.member});
  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.member?.name);
  late final _address = TextEditingController(text: widget.member?.address);
  late final _phone = TextEditingController(text: widget.member?.phone);
  late final _amount = TextEditingController(text: widget.member?.monthlyAmount.toString());

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = {
      'name': _name.text.trim(), 'address': _address.text.trim(),
      'phone': _phone.text.trim(),
      'monthlyAmount': double.tryParse(_amount.text) ?? 0,
      'monthlyStatus': widget.member?.monthlyStatus ?? {},
    };
    final col = FirebaseFirestore.instance.collection('members');
    if (widget.member == null) {
      await col.add(data);
    } else {
      await col.doc(widget.member!.id).update(data);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.member == null ? 'Add Member' : 'Edit Member')),
      body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
        const SizedBox(height: 12),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
        const SizedBox(height: 12),
        TextFormField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Amount')),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ])),
    );
  }
}