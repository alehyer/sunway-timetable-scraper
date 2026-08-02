import 'package:flutter/material.dart';
import 'package:flutter_test_app/AI.dart';
import 'package:flutter_test_app/IcheckIn.dart';
import 'package:flutter_test_app/UpdateProfile.dart';
import 'package:flutter_test_app/TimeTable.dart';

class SkeletonPage extends StatefulWidget {
  SkeletonPage({super.key});

  @override
  State<SkeletonPage> createState() => _SkeletonPageState();
}

class _SkeletonPageState extends State<SkeletonPage> {
  //pages i want to navigate to
  final List<Widget> navigationPages = [
    Timetable(),
    AI(),
    Icheckin(),
    Updateprofile(),
  ];

  int selectedIndex = 0;

  //method to update the new selected index
  void navigateBottomBar(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sunway"),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
      ),

      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              child: Image.asset(
                'assets/sunwaylogo.png',
                color: Colors.white,
                colorBlendMode: BlendMode.multiply,
              ),
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text("About"),
              onTap: () {
                Navigator.pop(
                  context,
                ); //for it to go back to normal screen not the drawer
                Navigator.pushNamed(context, '/about');
              },
            ),
            ListTile(leading: Icon(Icons.school_sharp), title: Text("Izone")),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: navigateBottomBar,
        backgroundColor: Colors.indigo[900],
        selectedItemColor: Colors.white,
        items: [
          //TimeTable(home)
          BottomNavigationBarItem(icon: Icon(Icons.tab), label: "Timetable"),

          //AI
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "AI"),

          //IcheckIn
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "IcheckIn",
          ),

          //Profile
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      body: IndexedStack(index: selectedIndex, children: navigationPages),
    );
  }
}
