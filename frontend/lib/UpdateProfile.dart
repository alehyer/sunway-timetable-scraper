import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test_app/RefreshSignal.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Updateprofile extends StatefulWidget {
  Updateprofile({super.key});

  @override
  State<Updateprofile> createState() => _UpdateprofileState();
}

class _UpdateprofileState extends State<Updateprofile> {
  final TextEditingController studentId = TextEditingController();
  final TextEditingController studentPassword = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  static const int expiryDays = 7;

  String? loggedInAsId;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  // Shows "Logged in as <id>" if there's a still-valid session, and
  // silently clears the saved studentId if it's past the 7-day mark.
  // This never touches the saved timetableData — that stays untouched
  // until the next successful login overwrites it.
  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt('loginTimestamp');
    final String? savedId = prefs.getString('studentId');

    if (timestamp != null && savedId != null) {
      final DateTime loginTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final bool expired =
          DateTime.now().difference(loginTime).inDays >= expiryDays;

      if (expired) {
        await prefs.remove('studentId');
        await prefs.remove('loginTimestamp');
        // timetableData is intentionally left alone here
        setState(() => loggedInAsId = null);
      } else {
        setState(() => loggedInAsId = savedId);
      }
    }
  }

  Future<void> login() async {
    final String id = studentId.text.trim();
    final String password = studentPassword.text;

    if (id.isEmpty || password.isEmpty) {
      _showError("Please enter both Student ID and Password.");
      return;
    }

    setState(() => isLoading = true);

    // Same endpoint used to verify credentials and scrape the timetable.
    final url = Uri.parse('http://10.0.2.2:8020/api/timetable/scrape');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"studentId": id, "password": password}),
      );

      if (response.statusCode != 200) {
        _showError("Server error. Please try again later.");
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      // Backend quirk: on wrong ID/password, Selenium times out and the
      // service still returns HTTP 200, but the body is the plain String
      // "Failed to scrape data" instead of a List. So we check the type,
      // not just the status code.
      if (decoded is! List) {
        _showError("Invalid Student ID or Password.");
        return;
      }

      // Save the new session + freshly scraped timetable. This overwrites
      // whatever timetable was saved from a previous login.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentId', id);
      await prefs.setInt(
        'loginTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setString('timetableData', response.body);

      // Tell the Timetable tab (kept alive in the background by
      // IndexedStack) that fresh data is ready to be loaded.
      timetableRefreshSignal.value++;

      if (!mounted) return;
      setState(() => loggedInAsId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful. Timetable updated.")),
      );
      studentPassword.clear();
    } catch (e) {
      _showError("Something went wrong: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    studentId.dispose();
    studentPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold/AppBar here — this widget is now embedded directly as
    // the Profile tab inside SkeletonPage, which already provides the
    // "Sunway" AppBar and bottom nav bar around it.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.indigo[900],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/sunwaylogo.png',
                height: 80,
                color: Colors.indigo[900],
                colorBlendMode: BlendMode.multiply,
              ),
              const SizedBox(height: 20),
              if (loggedInAsId != null) ...[
                Text(
                  "Logged in as $loggedInAsId",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Log in again anytime to refresh your timetable",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ] else
                const Text(
                  "Enter your iZone credentials to load your timetable",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: studentId,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Student ID",
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: studentPassword,
                obscureText: obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
                onSubmitted: (_) => login(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Save",
                        style: TextStyle(color: Colors.indigo),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
