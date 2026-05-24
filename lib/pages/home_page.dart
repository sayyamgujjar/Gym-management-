import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'members_page.dart';
import 'payments_page.dart';
import 'trainers_page.dart';
import 'reports_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(

        backgroundColor: const Color(0xFF1E293B),

        elevation: 0,

        title: const Text(
          'GYM POWER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        actions: [

          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },

            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // TOP BLUE HEADER

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(

                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF6366F1),
                  ],
                ),

                borderRadius: BorderRadius.circular(25),

                boxShadow: [

                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Welcome Back 👋",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Manage your gym easily",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      dashboardMiniCard(
                        "Members",
                        Icons.people,
                      ),

                      dashboardMiniCard(
                        "Payments",
                        Icons.payment,
                      ),

                      dashboardMiniCard(
                        "Reports",
                        Icons.bar_chart,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(

              "Quick Access",

              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            GridView.count(

              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              crossAxisCount: 2,

              crossAxisSpacing: 18,

              mainAxisSpacing: 18,

              childAspectRatio: 1,

              children: [

                menuCard(
                  context,
                  'Members',
                  Icons.people,
                  const Color(0xFF6366F1),
                  const MembersPage(),
                ),

                menuCard(
                  context,
                  'Payments',
                  Icons.payment,
                  const Color(0xFF8B5CF6),
                  const PaymentsPage(),
                ),

                menuCard(
                  context,
                  'Trainers',
                  Icons.fitness_center,
                  const Color(0xFF0EA5E9),
                  const TrainersPage(),
                ),

                menuCard(
                  context,
                  'Reports',
                  Icons.bar_chart,
                  const Color(0xFF14B8A6),
                  const ReportsPage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= MENU CARD =================

  Widget menuCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      Widget page,
      ) {

    return InkWell(

      borderRadius: BorderRadius.circular(25),

      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },

      child: Container(

        decoration: BoxDecoration(

          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),

          borderRadius: BorderRadius.circular(25),

          boxShadow: [

            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 18),

            Text(

              title,

              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MINI CARD =================

  Widget dashboardMiniCard(String title, IconData icon) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),

      decoration: BoxDecoration(

        color: Colors.white.withOpacity(0.15),

        borderRadius: BorderRadius.circular(15),
      ),

      child: Column(

        children: [

          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),

          const SizedBox(height: 5),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}