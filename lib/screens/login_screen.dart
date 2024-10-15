import 'package:erp/services/api_gateway.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'dashboard_screen.dart'; // Make sure you have this screen implemented

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  // String _password = '';

  // Function to handle login
  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, String> loginData = {
        'LoginId': _username,
        'Password': _password,
      };

      try {
        // Send POST request to the API
        final response =
            await ApiGateway().postRequest('api/Login/', loginData);

        // Check if the response was successful
        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);

          // Assuming successful login returns a token and user data
          if (jsonResponse.containsKey('token') &&
              jsonResponse.containsKey('user')) {
            String token = jsonResponse['token'];
            var user = jsonResponse['user'];
            String employeeName = user['empName'] ?? 'No Name'; // Default value
            String employeeDesignation =
                user['empDesignation'] ?? 'No Designation';
            // Store token securely
            await _storeToken(
                token, _username, employeeName, employeeDesignation);

            // Print the user data in the console
            // print('User Data:');
            // print('Employee ID: ${user['empId']}');
            // print('Name: ${user['empName']}');
            // print('Gender: ${user['empGender']}');
            // print('Email: ${user['empEmail']}');
            // print('Designation: ${user['empDesignation']}');
            // print('Department: ${user['empDepart']}');
            // print('Manager ID: ${user['empManager']}');
            // print('Aadhar No: ${user['empAadharNo']}');
            // print('PAN No: ${user['empPanNo']}');
            // print('Mobile: ${user['empMobile']}');
            // print('Date of Joining: ${user['empDateOfJoining']}');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome to the ERP!'),
                backgroundColor: Colors.green, // Success color
                duration: Duration(seconds: 0),
              ),
            );

            // Delay navigation to the Dashboard after the message
            Future.delayed(Duration(seconds: 0), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            });
          } else {
            // Show error message if login fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed. Please check your credentials.'),
                backgroundColor: Colors.red, // Error color
              ),
            );
          }
        } else {
          // Show error message if API call fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.reasonPhrase}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (error) {
        // Handle any errors that may occur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _storeToken(String token, String username, String employeeName,
      String employeeDesignation) async {
    try {
      await storage.write(key: 'token', value: token);
      await storage.write(key: 'username', value: username);
      await storage.write(key: 'employeeName', value: employeeName);
      await storage.write(
          key: 'employeeDesignation',
          value: employeeDesignation); // Store the username
      print('Token stored securely: $token');
      print('Username stored securely: $username');
    } catch (error) {
      print('Error storing login data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF274047), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/EDS_L.png",
                      width: 90, // Adjust this as needed
                      height: 90, // Adjust this as needed
                      fit:
                          BoxFit.cover, // Scale to cover the entire widget area
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 40),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.black),
                        hintText: 'Username',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: TextStyle(color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _username = value!;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock, color: Colors.black),
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: TextStyle(color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.white),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _password = value!;
                      },
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
