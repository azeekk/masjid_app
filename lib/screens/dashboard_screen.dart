import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'members_screen.dart';
import 'donations_screen.dart';
import 'students_screen.dart';
import 'staff_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masjid Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.logout),
          onPressed: () => FirebaseAuth.instance.signOut()),
      ]),
      body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
        _tile(context, Icons.people, 'Members', const MembersScreen()),
        _tile(context, Icons.volunteer_activism, 'Donations', const DonationsScreen(type: 'general')),
        _tile(context, Icons.favorite, 'Nikah Donations', const DonationsScreen(type: 'nikah')),
        _tile(context, Icons.menu_book, 'Madrasa Students', const StudentsScreen()),
        _tile(context, Icons.school, 'Staff', const StaffScreen(role: 'staff', title: 'Staff')),
      ]),
    );
  }

  Widget _tile(BuildContext ctx, IconData icon, String label, Widget screen) {
    return Card(elevation: 3, child: InkWell(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 48, color: Colors.green),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    ));
  }
}