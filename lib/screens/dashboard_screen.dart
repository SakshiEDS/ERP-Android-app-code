import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import the image picker package
import 'package:erp/views/Dashboard_view.dart';
import 'package:erp/views/projects_view.dart';
import '../views/attendance_view.dart';
import '../views/task_management_view.dart';
import '../views/store_view.dart';
import 'login_screen.dart';
import 'dart:io'; // Import for File
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isDetailView = false; // Track if we are in a detail view

  // Dummy Employee Details
  String employeeName = '';
  String employeeDesignation = '';
  String?
      profileImagePath; // Can be null if no image is set // Default image path

  // List of views corresponding to the drawer items
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
    _loadImagePath();
    _views = [
      DashboardView(onCardTap: (index) {
        setState(() {
          _selectedIndex = index;
          _isDetailView = true; // Set to true when navigating to detail view
        });
      }),
      AttendanceView(),
      TaskManagementView(),
      StoreView(),
      ProjectsView(),
    ];
  }

  void _loadImagePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      profileImagePath = prefs.getString('profileImagePath');
    });
  }

  Future<void> _fetchEmployeeData() async {
    try {
      // Read employee data from storage
      employeeName = await storage.read(key: 'employeeName') ??
          'No Name'; // Default value if null
      employeeDesignation = await storage.read(key: 'employeeDesignation') ??
          'No Designation'; // Default value if null

      // Trigger a UI update
      setState(() {});
    } catch (e) {
      print('Error fetching employee data from storage: $e');
    }
  }

  Future<void> _pickImage() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    if (await Permission.storage.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          profileImagePath = image.path;
        });

        // Save the image path to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('profileImagePath', image.path);
      }
    } else {
      print('Storage permission denied');
    }
  }

  void _removeImage() async {
    setState(() {
      profileImagePath = null;
    });

    // Remove the image path from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('profileImagePath');
  }

  // List of titles corresponding to each view
  final List<String> _titles = [
    'Dashboard',
    'Attendance',
    'Task Details',
    'Store',
    'Projects',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: Color(0xFF274047),
        leading: _isDetailView // Conditionally show the close icon
            ? IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isDetailView = false; // Set back to false
                    _selectedIndex = 0; // Go back to the dashboard
                  });
                },
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          GestureDetector(
            onTap: _pickImage, // Add the image picker on tap
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: profileImagePath != null
                    ? FileImage(File(
                        profileImagePath!)) // Use FileImage to display the selected image
                    : null, // Use FileImage to display the selected image
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _views,
      ),
    );
  }

  // Function to build the drawer
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF274047),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF274047)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap:
                          _pickImage, // Allow changing the image from the drawer
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: profileImagePath != null
                            ? FileImage(File(
                                profileImagePath!)) // Use FileImage to display the selected image
                            : null, // Use FileImage for the selected image
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      employeeName,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '($employeeDesignation)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            // Main Navigation Header
            ListTile(
              title: Text(
                'Main Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.blue),
              title: Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                  _isDetailView = false; // Reset detail view flag
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.access_time, color: Colors.blue),
              title: Text('Attendance', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                  _isDetailView = false; // Reset detail view flag
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment, color: Colors.orange),
              title: Text('Task Management',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                  _isDetailView = false; // Reset detail view flag
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.store, color: Colors.green),
              title: Text('Store', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                  _isDetailView = false; // Reset detail view flag
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: Colors.purple),
              title: Text('Projects', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                  _isDetailView = false; // Reset detail view flag
                });
                Navigator.pop(context);
              },
            ),

            Divider(color: Colors.white),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.grey),
              title: Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
