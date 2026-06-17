//lib/pages/payments_page.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/payment.dart';
import '../models/member.dart';
import '../services/firestore_service.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final FirestoreService _firestore = FirestoreService();
  String _filterStatus = 'All'; // All, Paid, Pending
  String _filterDateRange = 'All'; // All, Today, This Week, This Month, Custom
  DateTimeRange? _customDateRange;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ============ MARK PAYMENT AS PAID ============
  Future<void> _markAsPaid(Payment payment) async {
    try {
      await _firestore.markPaymentAsPaid(payment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('âœ… Payment marked as paid!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('âŒ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============ DELETE PAYMENT ============
  void _deletePayment(Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Payment",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete payment of Rs ${payment.amount.toStringAsFixed(0)} for ${payment.memberName}?",
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
              await _firestore.deletePayment(payment.id);
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("ðŸ—‘ï¸ Payment deleted"),
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

  // ============ ADD MANUAL PAYMENT ============
  void _showAddPaymentDialog() {
    String? selectedMemberId; // FIXED: Use ID instead of Member object
    String selectedPlan = 'Basic';
    String paymentStatus = 'Paid';
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Update amount when plan changes
          if (amountCtrl.text.isEmpty) {
            amountCtrl.text = Payment.getPlanAmount(
              selectedPlan,
            ).toStringAsFixed(0);
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF2a2a2a),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Add Manual Payment',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: StreamBuilder<List<Member>>(
              stream: _firestore.getMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No members found!\nPlease add members first.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final members = snapshot.data!;

                // Set initial member if not set
                if (selectedMemberId == null && members.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setDialogState(() {
                      selectedMemberId = members.first.id;
                      selectedPlan = members.first.plan;
                      amountCtrl.text = Payment.getPlanAmount(
                        selectedPlan,
                      ).toStringAsFixed(0);
                    });
                  });
                }

                // Get selected member name for display
                String getMemberName(String? id) {
                  if (id == null) return 'Select Member';
                  final member = members.firstWhere(
                    (m) => m.id == id,
                    orElse: () => Member(
                      id: '',
                      name: 'Unknown',
                      phone: '',
                      email: '',
                      plan: 'Basic',
                      joinDate: DateTime.now(),
                      expiryDate: DateTime.now(),
                    ),
                  );
                  return member.name;
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Member Dropdown - FIXED: Using String IDs instead of Member objects
                      DropdownButtonFormField<String>(
                        initialValue: selectedMemberId,
                        dropdownColor: const Color(0xFF2a2a2a),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Select Member *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.orange,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1a1a1a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          // Add a placeholder for empty selection
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'Select Member',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ...members.map(
                            (m) => DropdownMenuItem<String>(
                              value: m.id, // Use ID as value
                              child: Text(m.name),
                            ),
                          ),
                        ],
                        onChanged: (String? v) {
                          setDialogState(() {
                            selectedMemberId = v;
                            if (v != null) {
                              final member = members.firstWhere(
                                (m) => m.id == v,
                              );
                              selectedPlan = member.plan;
                              amountCtrl.text = Payment.getPlanAmount(
                                selectedPlan,
                              ).toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Plan Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedPlan,
                        dropdownColor: const Color(0xFF2a2a2a),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Plan *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.card_membership,
                            color: Colors.orange,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1a1a1a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['Basic', 'Premium', 'VIP']
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) {
                          setDialogState(() {
                            selectedPlan = v!;
                            amountCtrl.text = Payment.getPlanAmount(
                              selectedPlan,
                            ).toStringAsFixed(0);
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Amount Field (Editable)
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Amount (Rs) *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.money,
                            color: Colors.orange,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1a1a1a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Payment Date Selector
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Colors.orange,
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF2a2a2a),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1a1a),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: paymentStatus,
                        dropdownColor: const Color(0xFF2a2a2a),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Payment Status *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: Icon(
                            paymentStatus == 'Paid'
                                ? Icons.check_circle
                                : Icons.pending,
                            color: paymentStatus == 'Paid'
                                ? Colors.green
                                : Colors.orange,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1a1a1a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['Paid', 'Pending']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => paymentStatus = v!),
                      ),
                      const SizedBox(height: 16),

                      // Summary Card
                      if (selectedMemberId != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Summary:',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Member: ${getMemberName(selectedMemberId)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Plan: $selectedPlan',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Amount: Rs ${amountCtrl.text}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  // Validation
                  if (selectedMemberId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a member'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    // Get member details
                    final members = await _firestore.getMembers().first;
                    final member = members.firstWhere(
                      (m) => m.id == selectedMemberId,
                      orElse: () => Member(
                        id: '',
                        name: 'Unknown',
                        phone: '',
                        email: '',
                        plan: 'Basic',
                        joinDate: DateTime.now(),
                        expiryDate: DateTime.now(),
                      ),
                    );

                    // Create payment
                    final payment = Payment(
                      id: const Uuid().v4(),
                      memberId: member.id,
                      memberName: member.name,
                      plan: selectedPlan,
                      amount: amount,
                      paymentDate: selectedDate,
                      dueDate: selectedDate.add(const Duration(days: 30)),
                      status: paymentStatus,
                      month: selectedDate.month,
                      year: selectedDate.year,
                    );

                    await _firestore.generatePayment(payment);
                    if (!mounted || !ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('âœ… Payment added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted || !ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('âŒ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Add Payment',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============ PAYMENT DETAILS BOTTOM SHEET ============
  void _showPaymentDetails(Payment payment) {
    final isOverdue = payment.isOverdue;
    final daysOverdue = payment.daysOverdue;

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

            // Payment Info with overdue warning
            CircleAvatar(
              radius: 40,
              backgroundColor: isOverdue
                  ? Colors.red.withValues(alpha: 0.2)
                  : payment.status == 'Paid'
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              child: Icon(
                isOverdue
                    ? Icons.warning
                    : payment.status == 'Paid'
                    ? Icons.check_circle
                    : Icons.pending,
                size: 40,
                color: isOverdue
                    ? Colors.red
                    : payment.status == 'Paid'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              payment.memberName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Status badge with overdue info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.withValues(alpha: 0.2)
                    : payment.status == 'Paid'
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOverdue
                        ? Icons.warning
                        : payment.status == 'Paid'
                        ? Icons.check_circle
                        : Icons.pending,
                    size: 16,
                    color: isOverdue
                        ? Colors.red
                        : payment.status == 'Paid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOverdue ? 'Overdue ($daysOverdue days)' : payment.status,
                    style: TextStyle(
                      color: isOverdue
                          ? Colors.red
                          : payment.status == 'Paid'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Details
            _detailRow(
              Icons.payment,
              'Amount',
              'Rs ${payment.amount.toStringAsFixed(0)}',
            ),
            _detailRow(Icons.card_membership, 'Plan', payment.plan),
            _detailRow(
              Icons.calendar_today,
              'Payment Date',
              DateFormat('dd MMM yyyy').format(payment.paymentDate),
            ),
            if (payment.status == 'Paid' && payment.paidDate != null)
              _detailRow(
                Icons.check_circle,
                'Paid Date',
                DateFormat('dd MMM yyyy').format(payment.paidDate!),
              ),
            _detailRow(
              Icons.event_busy,
              'Due Date',
              DateFormat('dd MMM yyyy').format(payment.dueDate),
            ),

            // Overdue warning
            if (isOverdue) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment is $daysOverdue days overdue',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            if (payment.status == 'Pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _markAsPaid(payment);
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Mark as Paid',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
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

  // ============ SELECT CUSTOM DATE RANGE ============
  Future<void> _selectCustomDateRange() async {
    final initialDateRange =
        _customDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Color(0xFF2a2a2a),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _customDateRange = pickedRange;
        _filterDateRange = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Payments',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddPaymentDialog,
            tooltip: 'Add Manual Payment',
          ),
        ],
      ),
      body: Column(
        children: [
          // Revenue Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Revenue (This Month)',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                StreamBuilder<double>(
                  stream: _firestore.getMonthlyRevenue(),
                  builder: (context, snapshot) {
                    final revenue = snapshot.data ?? 0.0;
                    return Text(
                      'Rs ${revenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _firestore.getPaidPaymentsCount(),
                    builder: (context, snapshot) {
                      return _buildStatBox(
                        'Paid',
                        '${snapshot.data ?? 0}',
                        Colors.green,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _firestore.getPendingPaymentsCount(),
                    builder: (context, snapshot) {
                      return _buildStatBox(
                        'Pending',
                        '${snapshot.data ?? 0}',
                        Colors.red,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filter Chips - Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  "Status: ",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(width: 8),
                _filterChip('All'),
                const SizedBox(width: 8),
                _filterChip('Paid'),
                const SizedBox(width: 8),
                _filterChip('Pending'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Date Range Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  "Date Range: ",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(width: 8),
                _dateRangeChip('All'),
                const SizedBox(width: 8),
                _dateRangeChip('Today'),
                const SizedBox(width: 8),
                _dateRangeChip('This Week'),
                const SizedBox(width: 8),
                _dateRangeChip('This Month'),
                const SizedBox(width: 8),
                _dateRangeChip('Custom'),
              ],
            ),
          ),
          if (_filterDateRange == 'Custom' && _customDateRange != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "${DateFormat('dd MMM yyyy').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}",
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Payments List
          Expanded(
            child: StreamBuilder<List<Payment>>(
              stream: _firestore.getPayments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment,
                          size: 80,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No payments yet',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add a payment',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                var payments = snapshot.data!;

                // Apply status filter
                if (_filterStatus != 'All') {
                  payments = payments
                      .where((p) => p.status == _filterStatus)
                      .toList();
                }

                // Apply date range filter
                if (_filterDateRange != 'All') {
                  payments = payments.where((p) {
                    switch (_filterDateRange) {
                      case 'Today':
                        return DateFormat('yyyy-MM-dd').format(p.paymentDate) ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                      case 'This Week':
                        final now = DateTime.now();
                        final startOfWeek = now.subtract(
                          Duration(days: now.weekday - 1),
                        );
                        final endOfWeek = startOfWeek.add(
                          const Duration(days: 6),
                        );
                        return p.paymentDate.isAfter(startOfWeek) &&
                            p.paymentDate.isBefore(
                              endOfWeek.add(const Duration(days: 1)),
                            );
                      case 'This Month':
                        final now = DateTime.now();
                        return p.paymentDate.month == now.month &&
                            p.paymentDate.year == now.year;
                      case 'Custom':
                        if (_customDateRange != null) {
                          return (p.paymentDate.isAfter(
                                    _customDateRange!.start,
                                  ) ||
                                  p.paymentDate.isAtSameMomentAs(
                                    _customDateRange!.start,
                                  )) &&
                              (p.paymentDate.isBefore(_customDateRange!.end) ||
                                  p.paymentDate.isAtSameMomentAs(
                                    _customDateRange!.end,
                                  ));
                        }
                        return true;
                      default:
                        return true;
                    }
                  }).toList();
                }

                if (payments.isEmpty) {
                  return Center(
                    child: Text(
                      'No $_filterStatus payments$_filterDateRange != "All" ? " in $_filterDateRange" : ""',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final isPaid = payment.status == 'Paid';
                    final isOverdue = payment.isOverdue;

                    return Card(
                      color: const Color(0xFF2a2a2a),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isOverdue
                              ? Colors.red.withValues(alpha: 0.5)
                              : isPaid
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                          width: isOverdue ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showPaymentDetails(payment),
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      (isOverdue
                                              ? Colors.red
                                              : isPaid
                                              ? Colors.green
                                              : Colors.orange)
                                          .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isOverdue
                                      ? Icons.warning
                                      : isPaid
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  color: isOverdue
                                      ? Colors.red
                                      : isPaid
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment.memberName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(payment.paymentDate),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Payment.getPlanColor(
                                              payment.plan,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            payment.plan,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Payment.getPlanColor(
                                                payment.plan,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isOverdue) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.warning,
                                                  size: 10,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${payment.daysOverdue}d',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.red,
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
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs ${payment.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isOverdue
                                                  ? Colors.red
                                                  : isPaid
                                                  ? Colors.green
                                                  : Colors.orange)
                                              .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isOverdue ? 'Overdue' : payment.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isOverdue
                                            ? Colors.red
                                            : isPaid
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                color: const Color(0xFF2a2a2a),
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.grey,
                                ),
                                itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'View Details',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Edit',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (payment.status == 'Pending')
                                    const PopupMenuItem<String>(
                                      value: 'mark_paid',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Mark as Paid',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showPaymentDetails(payment);
                                      break;
                                    case 'edit':
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Edit feature coming soon!",
                                          ),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                      break;
                                    case 'mark_paid':
                                      _markAsPaid(payment);
                                      break;
                                    case 'delete':
                                      _deletePayment(payment);
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _filterStatus == label;
    return InkWell(
      onTap: () => setState(() => _filterStatus = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _dateRangeChip(String label) {
    final isSelected = _filterDateRange == label;
    return InkWell(
      onTap: () {
        if (label == 'Custom') {
          _selectCustomDateRange();
        } else {
          setState(() {
            _filterDateRange = label;
            _customDateRange = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey),
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
}
