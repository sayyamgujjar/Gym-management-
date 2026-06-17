// lib/pages/reports_page.dart - UPDATED WITHOUT PDF OPTION
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final FirestoreService _firestore = FirestoreService();
  String _selectedPeriod = 'Month'; // Week, Month, Year
  final DateTime _selectedDate = DateTime.now();

  // Get date range based on selected period
  Map<String, DateTime> _getDateRange() {
    DateTime start, end;

    switch (_selectedPeriod) {
      case 'Week':
        start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case 'Year':
        start = DateTime(_selectedDate.year, 1, 1);
        end = DateTime(_selectedDate.year, 12, 31);
        break;
      case 'Month':
      default:
        start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        break;
    }

    return {'start': start, 'end': end};
  }

  // Calculate attendance statistics
  Future<Map<String, dynamic>> _getAttendanceStats() async {
    final range = _getDateRange();
    return await _firestore.getAttendanceStats(
      startDate: range['start']!,
      endDate: range['end']!,
    );
  }

  // Calculate payment statistics
  Future<Map<String, dynamic>> _getPaymentStats() async {
    return await _firestore.getMonthlyPaymentStats(
      _selectedDate.month,
      _selectedDate.year,
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _getDateRange();

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Refresh the page
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPeriodButton('Week'),
                        _buildPeriodButton('Month'),
                        _buildPeriodButton('Year'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(range['start']!)} - ${DateFormat('dd MMM yyyy').format(range['end']!)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Member Overview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Member Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<int>(
                          stream: _firestore.getTotalMembersCount(),
                          builder: (context, snapshot) {
                            return _buildMiniStat('Total', '${snapshot.data ?? 0}');
                          },
                        ),
                        StreamBuilder<int>(
                          stream: _firestore.getActiveMembersCount(),
                          builder: (context, snapshot) {
                            return _buildMiniStat('Active', '${snapshot.data ?? 0}');
                          },
                        ),
                        StreamBuilder<int>(
                          stream: _firestore.getExpiredMembersCount(),
                          builder: (context, snapshot) {
                            return _buildMiniStat('Expired', '${snapshot.data ?? 0}');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Revenue Stats
              FutureBuilder<Map<String, dynamic>>(
                future: _getPaymentStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    );
                  }

                  final stats = snapshot.data ?? {};
                  final revenue = stats['totalRevenue'] ?? 0.0;
                  final pending = stats['pendingAmount'] ?? 0.0;
                  final paidCount = stats['paidCount'] ?? 0;
                  final collectionRate = stats['collectionRate'] ?? 0.0;

                  return Column(
                    children: [
                      // Revenue Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.greenAccent],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Revenue This Month',
                                  style: TextStyle(fontSize: 14, color: Colors.white70),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${collectionRate.toStringAsFixed(0)}% Collected',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Rs ${revenue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Paid Payments',
                                      style: TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                    Text(
                                      '$paidCount',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Pending Amount',
                                      style: TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                    Text(
                                      'Rs ${pending.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Attendance Stats
              FutureBuilder<Map<String, dynamic>>(
                future: _getAttendanceStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    );
                  }

                  final stats = snapshot.data ?? {};
                  final totalAttendance = stats['totalAttendance'] ?? 0;
                  final uniqueMembers = stats['uniqueMembers'] ?? 0;
                  final avgPerDay = stats['averagePerDay'] ?? '0';

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Attendance Statistics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStat('Total Check-ins', '$totalAttendance'),
                            _buildMiniStat('Unique Members', '$uniqueMembers'),
                            _buildMiniStat('Avg/Day', avgPerDay),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _firestore.getTotalMembersCount(),
                      builder: (context, snapshot) {
                        return _buildStatCard(
                          'Total Members',
                          '${snapshot.data ?? 0}',
                          Icons.people,
                          Colors.blue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _firestore.getActiveMembersCount(),
                      builder: (context, snapshot) {
                        return _buildStatCard(
                          'Active Plans',
                          '${snapshot.data ?? 0}',
                          Icons.card_membership,
                          Colors.purple,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<double>(
                      stream: _firestore.getMonthlyRevenue(),
                      builder: (context, snapshot) {
                        final revenue = snapshot.data ?? 0.0;
                        return _buildStatCard(
                          'Revenue',
                          'Rs ${(revenue / 1000).toStringAsFixed(1)}K',
                          Icons.payment,
                          Colors.green,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _firestore.getTodayAttendanceCount(),
                      builder: (context, snapshot) {
                        return _buildStatCard(
                          'Today',
                          '${snapshot.data ?? 0}',
                          Icons.today,
                          Colors.red,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Top Members by Attendance
              FutureBuilder<Map<String, dynamic>>(
                future: _getAttendanceStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  final stats = snapshot.data ?? {};
                  final memberAttendance = stats['memberAttendance'] as Map<String, int>? ?? {};

                  if (memberAttendance.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Sort by attendance count
                  final sortedMembers = memberAttendance.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Members (Attendance)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ...sortedMembers.take(5).map((entry) {
                        final name = entry.key;
                        final count = entry.value;
                        final maxCount = sortedMembers.first.value;
                        final percentage = (count / maxCount * 100).toInt();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2a2a2a),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$count days',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  color: Colors.green,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String text) {
    final isSelected = _selectedPeriod == text;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildReportCard(
      String title,
      String action,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    action,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}