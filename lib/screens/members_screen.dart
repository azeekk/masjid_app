import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';
import 'member_form_screen.dart';
import 'member_detail_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MemberFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('members').orderBy('name').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final members = snap.data!.docs
              .map((d) => Member.fromDoc(d.id, d.data() as Map<String, dynamic>)).toList();
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (ctx, i) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(members[i].name),
              subtitle: Text('${members[i].phone} • ৳${members[i].monthlyAmount}/mo'),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MemberDetailScreen(member: members[i]))),
            ),
          );
        },
      ),
    );
  }
}