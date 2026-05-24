import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/member.dart';
import '../services/firestore_service.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final FirestoreService _firestore = FirestoreService();

  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ================= ADD MEMBER =================

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    String selectedPlan = 'Basic';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),

              title: const Text(
                "Add Member",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // NAME

                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Full Name",
                        hintStyle: const TextStyle(color: Colors.white54),

                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF8B5CF6),
                        ),

                        filled: true,
                        fillColor: const Color(0xFF0F172A),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // PHONE

                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        hintText: "Phone Number",
                        hintStyle: const TextStyle(color: Colors.white54),

                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Color(0xFF8B5CF6),
                        ),

                        filled: true,
                        fillColor: const Color(0xFF0F172A),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // EMAIL

                    TextField(
                      controller: emailCtrl,
                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: const TextStyle(color: Colors.white54),

                        prefixIcon: const Icon(
                          Icons.email,
                          color: Color(0xFF8B5CF6),
                        ),

                        filled: true,
                        fillColor: const Color(0xFF0F172A),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // PLAN

                    DropdownButtonFormField<String>(
                      value: selectedPlan,

                      dropdownColor: const Color(0xFF1E293B),

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFF8B5CF6),
                        ),

                        filled: true,
                        fillColor: const Color(0xFF0F172A),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),

                      items: ['Basic', 'Premium', 'VIP']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),

                      onChanged: (v) {
                        setStateDialog(() {
                          selectedPlan = v!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  onPressed: () async {

                    if (nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill required fields"),
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
                      expiryDate: DateTime.now().add(
                        const Duration(days: 30),
                      ),
                    );

                    await _firestore.addMember(member);

                    if (!mounted) return;

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Member Added Successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },

                  child: const Text(
                    "ADD",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= DELETE =================

  void _deleteMember(String id) async {

    await _firestore.deleteMember(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Member Deleted"),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(

        backgroundColor: const Color(0xFF1E293B),

        elevation: 0,

        title: const Text(
          "Gym Members",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(
            onPressed: _showAddMemberDialog,
            icon: const Icon(
              Icons.add,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),

      body: Column(

        children: [

          // SEARCH BAR

          Padding(

            padding: const EdgeInsets.all(15),

            child: TextField(

              controller: _searchCtrl,

              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(

                hintText: "Search Members",

                hintStyle: const TextStyle(
                  color: Colors.white54,
                ),

                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF8B5CF6),
                ),

                filled: true,

                fillColor: const Color(0xFF1E293B),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
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

          // MEMBERS LIST

          Expanded(

            child: StreamBuilder<List<Member>>(

              stream: _firestore.getMembers(),

              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                    ),
                  );
                }

                final members = snapshot.data ?? [];

                final filteredMembers = members.where((member) {

                  return member.name
                      .toLowerCase()
                      .contains(_searchQuery);

                }).toList();

                if (filteredMembers.isEmpty) {

                  return const Center(

                    child: Text(

                      "No Members Found",

                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  );
                }

                return ListView.builder(

                  padding: const EdgeInsets.all(15),

                  itemCount: filteredMembers.length,

                  itemBuilder: (context, index) {

                    final member = filteredMembers[index];

                    final isActive = DateTime.now()
                        .isBefore(member.expiryDate);

                    return Container(

                      margin: const EdgeInsets.only(bottom: 15),

                      decoration: BoxDecoration(

                        color: const Color(0xFF1E293B),

                        borderRadius: BorderRadius.circular(22),

                        boxShadow: [

                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: ListTile(

                        contentPadding: const EdgeInsets.all(15),

                        leading: CircleAvatar(

                          radius: 28,

                          backgroundColor:
                          const Color(0xFF8B5CF6),

                          child: Text(

                            member.name[0].toUpperCase(),

                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),

                        title: Text(

                          member.name,

                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        subtitle: Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const SizedBox(height: 8),

                            Text(
                              member.phone,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              member.plan,
                              style: const TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(

                              "Expiry: ${DateFormat('dd MMM yyyy').format(member.expiryDate)}",

                              style: TextStyle(

                                color: isActive
                                    ? Colors.green
                                    : Colors.red,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        trailing: PopupMenuButton(

                          color: const Color(0xFF1E293B),

                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),

                          itemBuilder: (context) => [

                            const PopupMenuItem(

                              value: 'delete',

                              child: Row(

                                children: [

                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),

                                  SizedBox(width: 10),

                                  Text(
                                    "Delete",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          onSelected: (value) {

                            if (value == 'delete') {

                              _deleteMember(member.id);
                            }
                          },
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

      floatingActionButton: FloatingActionButton(

        backgroundColor: const Color(0xFF8B5CF6),

        onPressed: _showAddMemberDialog,

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}