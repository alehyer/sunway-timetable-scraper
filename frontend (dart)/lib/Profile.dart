import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 100, 0, 0),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo[700],
            radius: 100,
            child: Icon(Icons.person, size: 170, color: Colors.white),
          ),
          ListTile(
            leading: Icon(Icons.update),
            title: Text("Update Profile"),
            onTap: () {
              Navigator.pushNamed(context, '/updateProfile');
            },
          ),
          ListTile(leading: Icon(Icons.settings), title: Text("Settings")),
        ],
      ),
    );
  }
}
