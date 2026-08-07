import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        100,
        0,
        0,
      ),

      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo[700],

            radius: 100,

            child: const Icon(
              Icons.person,

              size: 170,

              color: Colors.white,
            ),
          ),

          ListTile(
            leading: const Icon(Icons.update),

            title: const Text("Update Profile"),

            onTap: () {
              Navigator.pushNamed(
                context,
                '/updateProfile',
              );
            },
          ),

          const ListTile(
            leading: Icon(Icons.settings),

            title: Text("Settings"),
          ),
        ],
      ),
    );
  }
}
