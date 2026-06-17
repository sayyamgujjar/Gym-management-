// lib/pages/attendance_page.dart - ENHANCED WITH CALENDAR
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../models/attendance_record.dart';
import '../services/firestore_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'mark'; // 'mark' or 'history'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Show Date Picker
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color(0xFF2a2a2a),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF2a2a2a),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Check if member is marked present for selected date
  Future<bool> _isMarkedPresent(String memberId) async {
    return await _firestore.isAttendanceMarked(memberId, _selectedDate);
  }

  // Mark or Unmark attendance
  Future<void> _toggleAttendance(Member member) async {
    final isPresent = await _isMarkedPresent(member.id);

    if (isPresent) {
      // Unmark attendance
      await _firestore.unmarkAttendance(member.id, _selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${member.name} marked Absent!"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Mark attendance
      await _firestore.markAttendanceForDate(
          member.id, member.name, _selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${member.name} marked Present!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // View Mode Toggle
          IconButton(
            icon: Icon(
              _viewMode == 'mark' ? Icons.history : Icons.check_circle,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'mark' ? 'history' : 'mark';
              });
            },
            tooltip: _viewMode == 'mark' ? 'View History' : 'Mark Attendance',
          ),
        ],
      ),
      body: _viewMode == 'mark'
          ? _buildMarkAttendanceView()
          : _buildHistoryView(),
    );
  }

  // ============ MARK ATTENDANCE VIEW ============
  Widget _buildMarkAttendanceView() {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      children: [
        // Date Selector + Count
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? "Today" : "Selected Date",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE').format(_selectedDate),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 16),
              // Attendance Count for Selected Date
              FutureBuilder<int>(
                future: _firestore.getAttendanceCountForDate(_selectedDate),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "$count Members Present",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search members...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _searchCtrl.clear();
                    _searchQuery = '';
                  });
                },
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFF2a2a2a),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        const SizedBox(height: 20),

        // Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                "Mark Attendance",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Members List
        Expanded(
          child: StreamBuilder<List<Member>>(
            stream: _firestore.getMembers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No members found",
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              final members = snapshot.data!;

              // Filter members based on search query
              final filteredMembers = members.where((member) {
                return member.name.toLowerCase().contains(_searchQuery) ||
                    member.phone.contains(_searchQuery);
              }).toList();

              if (filteredMembers.isEmpty) {
                return const Center(
                  child: Text(
                    "No members match your search",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  final isActive = DateTime.now().isBefore(member.expiryDate);

                  return FutureBuilder<bool>(
                    future: _isMarkedPresent(member.id),
                    builder: (context, attendanceSnapshot) {
                      final isPresent = attendanceSnapshot.data ?? false;

                      return Card(
                        color: const Color(0xFF2a2a2a),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: isPresent
                                ? Colors.green.withValues(alpha: 0.5)
                                : isActive
                                ? Colors.blue.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                            width: isPresent ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: isPresent
                                ? Colors.green.withValues(alpha: 0.2)
                                : isActive
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            child: isPresent
                                ? const Icon(Icons.check, color: Colors.green)
                                : Text(
                              member.name.isNotEmpty
                                  ? member.name[0].toUpperCase()
                                  : 'M',
                              style: TextStyle(
                                color: isActive ? Colors.blue : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            member.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "${member.phone} • ${member.plan}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.withValues(alpha: 0.2)
                                          : Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Expired',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isActive ? Colors.green : Colors
                                            .red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isPresent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle,
                                              size: 12, color: Colors.green),
                                          SizedBox(width: 4),
                                          Text(
                                            'Marked',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPresent
                                  ? Colors.orange
                                  : isActive
                                  ? Colors.green
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onPressed: isActive
                                ? () => _toggleAttendance(member)
                                : null,
                            child: Text(
                              isPresent ? "Unmark" : "Present",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ ATTENDANCE HISTORY VIEW ============
  Widget _buildHistoryView() {
    return Column(
      children: [
        // Date Range Selector
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.green, size: 40),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Attendance History",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "View past attendance records",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Select'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Selected Date Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<int>(
                  future: _firestore.getAttendanceCountForDate(_selectedDate),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$count Present",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Attendance Records List
        Expanded(
          child: FutureBuilder<List<AttendanceRecord>>(
            future: _firestore.getAttendanceForDate(_selectedDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                );
              }

              final records = snapshot.data ?? [];

              if (records.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No attendance records",
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "No one was marked present on this date",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return Card(
                    color: const Color(0xFF2a2a2a),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                        child: Text(
                          record.memberName.isNotEmpty
                              ? record.memberName[0].toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        record.memberName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Marked at: ${record.formattedTime}",
                        style: const TextStyle(color: Colors.grey,
                            fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16,
                                color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Present',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
