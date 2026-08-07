import 'package:flutter/material.dart';

import 'ai_page.dart';
import 'checkin_page.dart';
import 'timetable_page.dart';
import 'update_profile_page.dart';
import 'about_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    TimetablePage(),

    AIPage(),

    CheckinPage(),

    UpdateProfilePage(),
  ];

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sunway"),

        centerTitle: true,
      ),

      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo[900],
              ),

              child: Center(
                child: Image.asset(
                  'assets/sunwaylogo.png',

                  height: 90,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.info_outline,
              ),

              title: const Text("About"),

              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        const AboutPage(),
                  ),
                );
              },
            ),

            const ListTile(
              leading: Icon(Icons.school),

              title: Text("iZone"),
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: selectedIndex,

        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,

        onDestinationSelected: changePage,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month),

            label: "Timetable",
          ),

          NavigationDestination(
            icon: Icon(Icons.auto_awesome),

            label: "AI",
          ),

          NavigationDestination(
            icon: Icon(Icons.check_circle),

            label: "Check-in",
          ),

          NavigationDestination(
            icon: Icon(Icons.person),

            label: "Profile",
          ),
        ],
      ),
    );
  }
}
