import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/member.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Active, Expired
  String _filterPlan = 'All'; // All, Basic, Premium, VIP
  String _sortBy = 'name_asc'; // name_asc, name_desc, expiry_asc, expiry_desc, join_asc, join_desc

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ============ ADD MEMBER DIALOG ============
  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedPlan = 'Basic';
    int planDuration = 1; // months
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Add New Member",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name Field
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Full Name *",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Phone Field
                TextField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number *",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Email Field
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email (optional)",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Plan Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedPlan,
                  dropdownColor: const Color(0xFF2a2a2a),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Membership Plan",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.card_membership, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Basic', 'Premium', 'VIP']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedPlan = v!),
                ),
                const SizedBox(height: 12),
                // Duration Dropdown
                DropdownButtonFormField<int>(
                  initialValue: planDuration,
                  dropdownColor: const Color(0xFF2a2a2a),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Duration",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.calendar_month, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [1, 3, 6, 12]
                      .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text('$m Month${m > 1 ? "s" : ""}'),
                  ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => planDuration = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name and Phone are required!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final member = Member(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  plan: selectedPlan,
                  joinDate: DateTime.now(),
                  expiryDate: DateTime.now().add(Duration(days: 30 * planDuration)),
                );
                await _firestore.addMember(member);
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("âœ… Member added successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                "Add Member",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ EDIT MEMBER DIALOG ============
  void _showEditMemberDialog(Member member) {
    final nameCtrl = TextEditingController(text: member.name);
    final phoneCtrl = TextEditingController(text: member.phone);
    final emailCtrl = TextEditingController(text: member.email);
    String selectedPlan = member.plan;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Edit Member",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlan,
                  dropdownColor: const Color(0xFF2a2a2a),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Membership Plan",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.card_membership, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Basic', 'Premium', 'VIP']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedPlan = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name and Phone are required!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final updatedMember = Member(
                  id: member.id,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  plan: selectedPlan,
                  joinDate: member.joinDate,
                  expiryDate: member.expiryDate,
                );
                await _firestore.updateMember(updatedMember);
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("âœ… Member updated successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                "Update",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ EXTEND MEMBERSHIP DIALOG ============
  void _showExtendMembershipDialog(Member member) {
    int extendMonths = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Extend Membership",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.name,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Current Expiry: ${DateFormat('dd MMM yyyy').format(member.expiryDate)}",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: extendMonths,
                dropdownColor: const Color(0xFF2a2a2a),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Extend By",
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.calendar_month, color: Colors.green),
                  filled: true,
                  fillColor: const Color(0xFF1a1a1a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [1, 3, 6, 12]
                    .map((m) => DropdownMenuItem(
                  value: m,
                  child: Text('$m Month${m > 1 ? "s" : ""}'),
                ))
                    .toList(),
                onChanged: (v) => setDialogState(() => extendMonths = v!),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "New Expiry: ${DateFormat('dd MMM yyyy').format(member.expiryDate.add(Duration(days: 30 * extendMonths)))}",
                  style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final newExpiry = member.expiryDate.add(Duration(days: 30 * extendMonths));
                await _firestore.extendMembership(member.id, newExpiry);
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("âœ… Membership extended by $extendMonths month${extendMonths > 1 ? 's' : ''}!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                "Extend",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ MEMBER DETAILS BOTTOM SHEET ============
  void _showMemberDetails(Member member) {
    final isActive = DateTime.now().isBefore(member.expiryDate);
    final daysLeft = member.expiryDate.difference(DateTime.now()).inDays;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2a2a2a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            // Avatar & Name
            CircleAvatar(
              radius: 40,
              backgroundColor: isActive ? Colors.blue.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
              child: Text(
                member.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  color: isActive ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              member.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Expired',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Details
            _detailRow(Icons.phone, "Phone", member.phone),
            if (member.email.isNotEmpty) _detailRow(Icons.email, "Email", member.email),
            _detailRow(Icons.card_membership, "Plan", member.plan),
            _detailRow(Icons.calendar_today, "Join Date", DateFormat('dd MMM yyyy').format(member.joinDate)),
            _detailRow(Icons.event_busy, "Expiry Date", DateFormat('dd MMM yyyy').format(member.expiryDate)),
            if (isActive)
              _detailRow(
                Icons.timer,
                "Days Left",
                "$daysLeft days",
                valueColor: daysLeft < 7 ? Colors.orange : Colors.green,
              ),
            const SizedBox(height: 20),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditMemberDialog(member);
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Edit", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showExtendMembershipDialog(member);
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: const Text("Extend", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ============ DELETE MEMBER ============
  void _deleteMember(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Member",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete $name? This action cannot be undone.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await _firestore.deleteMember(id);
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("ðŸ—‘ï¸ Member deleted"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Members Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2a2a2a),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone or email...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
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
                    fillColor: const Color(0xFF1a1a1a),
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
                const SizedBox(height: 12),
                // Status Filter Chips
                Row(
                  children: [
                    const Text(
                      "Status: ",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    _filterChip('All', isPlan: false),
                    const SizedBox(width: 8),
                    _filterChip('Active', isPlan: false),
                    const SizedBox(width: 8),
                    _filterChip('Expired', isPlan: false),
                  ],
                ),
                const SizedBox(height: 12),
                // Plan Filter Chips
                Row(
                  children: [
                    const Text(
                      "Plan: ",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    _filterChip('All', isPlan: true),
                    const SizedBox(width: 8),
                    _filterChip('Basic', isPlan: true),
                    const SizedBox(width: 8),
                    _filterChip('Premium', isPlan: true),
                    const SizedBox(width: 8),
                    _filterChip('VIP', isPlan: true),
                  ],
                ),
                const SizedBox(height: 12),
                // Sort Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  dropdownColor: const Color(0xFF2a2a2a),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Sort By",
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.sort, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'name_asc', child: Text('Name (A-Z)')),
                    const DropdownMenuItem(value: 'name_desc', child: Text('Name (Z-A)')),
                    const DropdownMenuItem(value: 'expiry_asc', child: Text('Expiry (Soonest First)')),
                    const DropdownMenuItem(value: 'expiry_desc', child: Text('Expiry (Latest First)')),
                    const DropdownMenuItem(value: 'join_asc', child: Text('Join Date (Oldest First)')),
                    const DropdownMenuItem(value: 'join_desc', child: Text('Join Date (Newest First)')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v!),
                ),
              ],
            ),
          ),
          // Members List
          Expanded(
            child: StreamBuilder<List<Member>>(
              stream: _firestore.getMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final allMembers = snapshot.data ?? [];
                if (allMembers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No members yet",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Tap + to add your first member",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                // Apply filters
                var filteredMembers = allMembers.where((member) {
                  // Search filter (enhanced to include email)
                  final matchesSearch = member.name.toLowerCase().contains(_searchQuery) ||
                      member.phone.contains(_searchQuery) ||
                      member.email.toLowerCase().contains(_searchQuery);
                  // Status filter
                  final isActive = DateTime.now().isBefore(member.expiryDate);
                  final matchesStatus = _filterStatus == 'All' ||
                      (_filterStatus == 'Active' && isActive) ||
                      (_filterStatus == 'Expired' && !isActive);
                  // Plan filter
                  final matchesPlan = _filterPlan == 'All' || member.plan == _filterPlan;
                  return matchesSearch && matchesStatus && matchesPlan;
                }).toList();
                // Apply sorting
                switch (_sortBy) {
                  case 'name_asc':
                    filteredMembers.sort((a, b) => a.name.compareTo(b.name));
                    break;
                  case 'name_desc':
                    filteredMembers.sort((a, b) => b.name.compareTo(a.name));
                    break;
                  case 'expiry_asc':
                    filteredMembers.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
                    break;
                  case 'expiry_desc':
                    filteredMembers.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
                    break;
                  case 'join_asc':
                    filteredMembers.sort((a, b) => a.joinDate.compareTo(b.joinDate));
                    break;
                  case 'join_desc':
                    filteredMembers.sort((a, b) => b.joinDate.compareTo(a.joinDate));
                    break;
                }
                if (filteredMembers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No members match your filters",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }
                // Count active and expired
                final activeCount = allMembers.where((m) => DateTime.now().isBefore(m.expiryDate)).length;
                final expiredCount = allMembers.length - activeCount;
                return RefreshIndicator(
                  onRefresh: () async {
                    // Trigger rebuild by setting state (Firestore stream will handle updates)
                    setState(() {});
                  },
                  child: Column(
                    children: [
                      // Stats Summary
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statBadge("Total", "${allMembers.length}", Colors.blue),
                            _statBadge("Active", "$activeCount", Colors.green),
                            _statBadge("Expired", "$expiredCount", Colors.red),
                          ],
                        ),
                      ),
                      // Members List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];
                            final isActive = DateTime.now().isBefore(member.expiryDate);
                            final daysLeft = member.expiryDate.difference(DateTime.now()).inDays;
                            final isExpiringSoon = isActive && daysLeft <= 7;
                            return Card(
                              color: const Color(0xFF2a2a2a),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: isExpiringSoon
                                      ? Colors.orange.withValues(alpha: 0.5)
                                      : isActive
                                      ? Colors.blue.withValues(alpha: 0.3)
                                      : Colors.red.withValues(alpha: 0.3),
                                  width: isExpiringSoon ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _showMemberDetails(member),
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: isActive
                                            ? Colors.blue.withValues(alpha: 0.2)
                                            : Colors.red.withValues(alpha: 0.2),
                                        child: Text(
                                          member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                                          style: TextStyle(
                                            fontSize: 24,
                                            color: isActive ? Colors.blue : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Member Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              member.phone,
                                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                // Plan Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    member.plan,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.purple,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isExpiringSoon
                                                        ? Colors.orange.withValues(alpha: 0.2)
                                                        : isActive
                                                        ? Colors.green.withValues(alpha: 0.2)
                                                        : Colors.red.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isExpiringSoon
                                                            ? Icons.warning
                                                            : isActive
                                                            ? Icons.check_circle
                                                            : Icons.cancel,
                                                        size: 12,
                                                        color: isExpiringSoon
                                                            ? Colors.orange
                                                            : isActive
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isExpiringSoon
                                                            ? '$daysLeft days left'
                                                            : isActive
                                                            ? 'Active'
                                                            : 'Expired',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: isExpiringSoon
                                                              ? Colors.orange
                                                              : isActive
                                                              ? Colors.green
                                                              : Colors.red,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions Menu
                                      PopupMenuButton<String>(
                                        color: const Color(0xFF2a2a2a),
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(Icons.visibility, color: Colors.blue, size: 20),
                                                SizedBox(width: 8),
                                                Text('View Details', style: TextStyle(color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, color: Colors.orange, size: 20),
                                                SizedBox(width: 8),
                                                Text('Edit', style: TextStyle(color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'extend',
                                            child: Row(
                                              children: [
                                                Icon(Icons.add_circle, color: Colors.green, size: 20),
                                                SizedBox(width: 8),
                                                Text('Extend', style: TextStyle(color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red, size: 20),
                                                SizedBox(width: 8),
                                                Text('Delete', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'view':
                                              _showMemberDetails(member);
                                              break;
                                            case 'edit':
                                              _showEditMemberDialog(member);
                                              break;
                                            case 'extend':
                                              _showExtendMembershipDialog(member);
                                              break;
                                            case 'delete':
                                              _deleteMember(member.id, member.name);
                                              break;
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Filter Chip Widget (enhanced to handle both status and plan)
  Widget _filterChip(String label, {required bool isPlan}) {
    final isSelected = isPlan ? _filterPlan == label : _filterStatus == label;
    return InkWell(
      onTap: () {
        setState(() {
          if (isPlan) {
            _filterPlan = label;
          } else {
            _filterStatus = label;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Stat Badge Widget
  Widget _statBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}