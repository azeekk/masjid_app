
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'members_screen.dart';
import 'donations_screen.dart';
import 'students_screen.dart';
import 'staff_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color primaryGreen = Color(0xFF14532D);
  static const Color lightGreen = Color(0xFF22A06B);
  static const Color backgroundColor = Color(0xFFF5F8F5);

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final displayName = email.contains('@')
        ? email.split('@').first
        : 'Administrator';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, displayName),
            ),

            // Financial tracker
            SliverToBoxAdapter(
              child: _buildFinancialOverview(),
            ),

            // Management section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Management',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF183629),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Manage your masjid in one place',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: primaryGreen,
                        size: 23,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _buildTile(
                    context,
                    icon: Icons.people_alt_rounded,
                    title: 'Members',
                    subtitle: 'Community members',
                    color: const Color(0xFF1976D2),
                    background: const Color(0xFFE8F2FF),
                    screen: const MembersScreen(),
                  ),
                  _buildTile(
                    context,
                    icon: Icons.volunteer_activism_rounded,
                    title: 'Donations',
                    subtitle: 'General contributions',
                    color: const Color(0xFF16865B),
                    background: const Color(0xFFE1F5E9),
                    screen: const DonationsScreen(type: 'general'),
                  ),
                  _buildTile(
                    context,
                    icon: Icons.favorite_rounded,
                    title: 'Nikah Donations',
                    subtitle: 'Marriage contributions',
                    color: const Color(0xFFDB4C74),
                    background: const Color(0xFFFFE8EF),
                    screen: const DonationsScreen(type: 'nikah'),
                  ),
                  _buildTile(
                    context,
                    icon: Icons.menu_book_rounded,
                    title: 'Madrasa Students',
                    subtitle: 'Student records and fees',
                    color: const Color(0xFF8B5BC7),
                    background: const Color(0xFFF0E8FF),
                    screen: const StudentsScreen(),
                  ),
                  _buildTile(
                    context,
                    icon: Icons.school_rounded,
                    title: 'Staff',
                    subtitle: 'Staff management',
                    color: const Color(0xFFCB8524),
                    background: const Color(0xFFFFF0D9),
                    screen: const StaffScreen(
                      role: 'staff',
                      title: 'Staff',
                    ),
                  ),
                ]),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.94,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF14532D),
                        Color(0xFF217A4D),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.mosque_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Serving Our Community',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Everything your masjid needs, together.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // FINANCIAL OVERVIEW
  // --------------------------------------------------

  Widget _buildFinancialOverview() {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();

    final monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('donations').snapshots(),
      builder: (context, donationSnap) {
        if (donationSnap.hasError) {
          return _financeError('Unable to load donations.');
        }

        if (!donationSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        double donationIncome = 0;

        for (final doc in donationSnap.data!.docs) {
          final amount = doc.data()['amount'];

          if (amount is num) {
            donationIncome += amount.toDouble();
          }
        }

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('students').snapshots(),
          builder: (context, studentSnap) {
            if (studentSnap.hasError) {
              return _financeError('Unable to load student fees.');
            }

            if (!studentSnap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            double feeIncome = 0;
            double pendingFees = 0;

            for (final doc in studentSnap.data!.docs) {
              final data = doc.data();

              final rawMonthlyFee = data['monthlyFee'];
              final monthlyFee = rawMonthlyFee is num
                  ? rawMonthlyFee.toDouble()
                  : 0.0;

              final rawStatus = data['feeStatus'];
              final statuses =
                  rawStatus is Map ? rawStatus : <String, dynamic>{};

              // All recorded student fee payments
              for (final entry in statuses.values) {
                if (entry is Map && entry['paid'] == true) {
                  final amount = entry['amount'];

                  if (amount is num) {
                    feeIncome += amount.toDouble();
                  }
                }
              }

              // Current month's outstanding fees
              final currentStatus = statuses[monthKey];

              final currentPaidAmount =
                  currentStatus is Map &&
                          currentStatus['paid'] == true &&
                          currentStatus['amount'] is num
                      ? (currentStatus['amount'] as num).toDouble()
                      : 0.0;

              pendingFees +=
                  (monthlyFee - currentPaidAmount)
                      .clamp(0.0, double.infinity)
                      .toDouble();
            }

            final totalIncome = donationIncome + feeIncome;

            return StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('expenses').snapshots(),
              builder: (context, expenseSnap) {
                if (expenseSnap.hasError) {
                  return _financeError('Unable to load expenses.');
                }

                if (!expenseSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                double totalExpenses = 0;

                for (final doc in expenseSnap.data!.docs) {
                  final amount = doc.data()['amount'];

                  if (amount is num) {
                    totalExpenses += amount.toDouble();
                  }
                }

                final netBalance = totalIncome - totalExpenses;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section heading
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5E9),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Financial Overview',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF183629),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your masjid financial summary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.sync_rounded,
                            color: lightGreen,
                            size: 21,
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Income and expense cards
                      Row(
                        children: [
                          Expanded(
                            child: _financeCard(
                              title: 'Total Income',
                              amount: totalIncome,
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF16865B),
                              background: const Color(0xFFE1F5E9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _financeCard(
                              title: 'Total Expenses',
                              amount: totalExpenses,
                              icon: Icons.trending_down_rounded,
                              color: const Color(0xFFD94848),
                              background: const Color(0xFFFFE8E8),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Net balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0B3D24),
                              Color(0xFF217A4D),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Net Balance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatMoney(netBalance),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Income minus expenses',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              netBalance >= 0
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Pending student fees
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0D9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFE4B4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFFCB8524),
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Student Fees',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF654817),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Outstanding this month',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF806B48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatMoney(pendingFees),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9A6110),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Income includes all recorded donations and paid student fees.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _financeError(String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFFB42318)),
        ),
      ),
    );
  }

  // Financial amount card
  Widget _financeCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatMoney(amount),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bangladeshi-style comma grouping, matching the ৳ currency
  String _formatMoney(double amount) {
    final formatted = amount.abs().toStringAsFixed(2);
    final parts = formatted.split('.');
    final digits = parts[0];

    String grouped = '';

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        grouped += ',';
      }
      grouped += digits[i];
    }

    return '${amount < 0 ? '-' : ''}৳$grouped.${parts[1]}';
  }

  // --------------------------------------------------
  // DASHBOARD HEADER
  // --------------------------------------------------

  Widget _buildHeader(BuildContext context, String displayName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B3D24),
            Color(0xFF14532D),
            Color(0xFF22A06B),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MASJID MANAGEMENT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Community Administration',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                child: IconButton(
                  tooltip: 'Logout',
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Assalamu Alaikum 👋',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName.isEmpty
                ? 'Welcome, Administrator'
                : 'Welcome, ${_capitalize(displayName)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Manage your masjid activities with ease.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFA7F3C1),
                  size: 25,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Administration Hub',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All your essential tools in one place',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // MANAGEMENT CARDS
  // --------------------------------------------------

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color background,
    required Widget screen,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8EEE9)),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color, size: 29),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF183629),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() +
        value.substring(1).replaceAll('.', ' ');
  }

  // --------------------------------------------------
  // LOGOUT CONFIRMATION
  // --------------------------------------------------

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          size: 36,
          color: primaryGreen,
        ),
        title: const Text(
          'Logout?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
