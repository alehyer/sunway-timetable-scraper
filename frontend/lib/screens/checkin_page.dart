import 'package:flutter/material.dart';

class CheckinPage extends StatelessWidget {
  const CheckinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.check_circle_outline,

              size: 80,

              color: Colors.indigo,
            ),

            const SizedBox(height: 20),

            const Text(
              "ICheckIn",

              style: TextStyle(
                fontSize: 24,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Check-in features coming soon.",

              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
