import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart'; // Ensure this import matches your project structure

final storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that the Flutter binding is initialized before using async methods
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Hides the debug banner
      home: FutureBuilder(
        future: _checkUserAuthorization(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator()); // Show loading indicator while checking
          } else if (snapshot.hasData && snapshot.data == true) {
            return DashboardScreen(); // User is authorized
          } else {
            return LoginScreen(); // User is not authorized
          }
        },
      ),
    );
  }

  Future<bool> _checkUserAuthorization() async {
    // Check if the user is authorized by looking for a token
    String? token = await storage.read(key: 'token');
    return token != null; // Return true if the token exists, false otherwise
  }
}
