import 'dart:convert';
import 'package:erp/screens/login_screen.dart';
import 'package:erp/services/api_gateway.dart';
import 'package:flutter/material.dart';

class TaskManagementView extends StatefulWidget {
  @override
  _TaskManagementViewState createState() => _TaskManagementViewState();
}

class _TaskManagementViewState extends State<TaskManagementView> {
  List<Map<String, String>> tasks = [];
  bool isLoading = true;
  String errorMessage = '';
  int totalTaskCount = 0; // Total tasks
  int totalClosedTasks = 0; // Total closed tasks
  int totalPendingTasks = 0; // Total pending tasks
  int totalFailedTasks = 0; // Total failed tasks
  int totalRejectedTasks = 0;
  int totalDropTasks = 0;
  int totalAssignedTasks = 0;
  int totalExecuteTasks = 0; // Total rejected tasks
  int efficiency = 0; // Initialize efficiency
  bool isLoadingEfficiency = true; // Loading state for efficiency
  String efficiencyErrorMessage = ''; // Error message for efficiency

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _fetchEfficiency();
  }

  Future<void> _fetchEfficiency() async {
    try {
      String? token = await storage.read(key: 'token'); // Get the stored token
      String? employeeId =
          await storage.read(key: 'username'); // Get the employee ID

      if (token == null || employeeId == null) {
        throw Exception('No token or employee ID found. Please login again.');
      }

      final apiUrl =
          'api/tasks/getefficiency/$employeeId?session=2024-25'; // Your API endpoint
      final response = await ApiGateway().getRequest(apiUrl, token); // Call API

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['efficiency'] != null) {
          efficiency = data['efficiency']; // Set efficiency
        } else {
          throw Exception('Unexpected data format: "efficiency" not found');
        }
      } else {
        throw Exception('Failed to load efficiency: ${response.statusCode}');
      }
    } catch (e) {
      efficiencyErrorMessage = e.toString(); // Store the error message
    } finally {
      setState(() {
        isLoadingEfficiency = false; // Update loading state
      });
    }
  }

  Future<void> _fetchTasks() async {
    try {
      String? token = await storage.read(key: 'token');
      String? employeeId = await storage.read(key: 'username');

      if (token == null || employeeId == null) {
        throw Exception('No token or employee ID found. Please login again.');
      }

      final apiUrl = 'api/tasks/tasksdetails/$employeeId';
      final response = await ApiGateway().getRequest(apiUrl, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['taskAssigns'] is List) {
          tasks = (data['taskAssigns'] as List)
              .map((task) {
                return {
                  'title': task['projectTask'].toString(),
                  'startDate': task['projectTaskStartDate'].toString(),
                  'targetDate': task['projectTaskTargetDate'].toString(),
                  'status': task['projectTaskStatus'].toString(),
                };
              })
              .toList()
              .cast<Map<String, String>>();

          // Set the total task count and status counts
          totalTaskCount = tasks.length;
          _countTasksByStatus();

          // Call the onDataFetched callback to update parent state
        } else {
          throw Exception(
              'Unexpected data format: "taskAssigns" is not a list');
        }
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _countTasksByStatus() {
    totalClosedTasks = 0;
    totalPendingTasks = 0;
    totalFailedTasks = 0;
    totalRejectedTasks = 0;
    totalDropTasks = 0;
    totalAssignedTasks = 0;
    totalExecuteTasks = 0;

    for (var task in tasks) {
      switch (task['status']) {
        case 'Closed':
          totalClosedTasks++;
          break;
        case 'Pending Closure':
          totalPendingTasks++;
          break;
        case 'Task Failed':
          totalFailedTasks++;
          break;
        case 'Task Rejected':
          totalRejectedTasks++;
          break;
        case 'Drop':
          totalDropTasks++;
          break;
        case 'Assigned':
          totalAssignedTasks++;
          break;
        case 'Executing':
          totalExecuteTasks++;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Use a background image
          image: DecorationImage(
            image:
                AssetImage('assets/images/product.avif'), // Add your image path
            fit: BoxFit.cover, // Cover the whole container
          ),
          gradient: LinearGradient(
            colors: [
              Colors.lightBlue.withOpacity(0.6), // Light Blue with opacity
              Color(0xFF274047), // White with opacity
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GridView.count(
          crossAxisCount:
              _getCrossAxisCount(context), // Responsive cross-axis count
          childAspectRatio: 1.15, // Adjust aspect ratio if needed
          mainAxisSpacing: 5.0,
          crossAxisSpacing: 5.0,
          padding: EdgeInsets.all(10), // Add some padding around the grid
          children: [
            GestureDetector(
              onTap: () {
                // Show the popup when this card is clicked
                _showTaskListPopup(context);
              },
              child: _buildTaskCard(
                context,
                'Total Tasks\n(Assigned to you)',
                totalTaskCount,
                totalTaskCount > 0
                    ? 100.0
                    : 0.0, // Set progress based on total count
                Color(0xFF274047).withOpacity(0.8),
              ),
            ),
            _buildTaskCard(
              context,
              'Successful Tasks',
              totalClosedTasks,
              (totalTaskCount > 0
                  ? double.parse(((totalClosedTasks / totalTaskCount) * 100)
                      .toStringAsFixed(1))
                  : 0.0),
              Color(0xFF274047).withOpacity(0.8),
            ),
            _buildTaskCard(
              context,
              'Pending Tasks',
              totalPendingTasks,
              (totalTaskCount > 0
                  ? double.parse(((totalPendingTasks / totalTaskCount) * 100)
                      .toStringAsFixed(1))
                  : 0.0),
              Color(0xFF274047).withOpacity(0.8),
            ),
            _buildTaskCard(
              context,
              'Failed Tasks',
              totalFailedTasks,
              (totalTaskCount > 0
                  ? double.parse(((totalFailedTasks / totalTaskCount) * 100)
                      .toStringAsFixed(1))
                  : 0.0),
              Color(0xFF274047).withOpacity(0.8),
            ),
            _buildVerticalStatCard(
              context,
              'Drop Tasks',
              totalDropTasks,
              (totalTaskCount > 0
                  ? double.parse(((totalDropTasks / totalTaskCount) * 100)
                      .toStringAsFixed(1))
                  : 0.0),
              Color(0xFF274047).withOpacity(0.8),
            ),
            _buildVerticalStatCard(
              context,
              'Currently Assigned/Executing',
              totalExecuteTasks + totalAssignedTasks,
              (totalTaskCount > 0
                  ? double.parse((((totalExecuteTasks + totalAssignedTasks) /
                              totalTaskCount) *
                          100)
                      .toStringAsFixed(1))
                  : 0.0),
              Color(0xFF274047).withOpacity(0.8),
            ),
            _buildVerticalStatCard(
              context,
              'Rejected Tasks',
              totalRejectedTasks,
              (totalTaskCount > 0
                  ? double.parse(((totalRejectedTasks / totalTaskCount) * 100)
                      .toStringAsFixed(1))
                  : 0.0),
              Color(0xFF274047).withOpacity(0.8),
            ),
            _buildEfficiencyCard(
              context,
              efficiency,
              Color(0xFF274047).withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskListPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;

        return Dialog(
          backgroundColor: Color(0xFF274047), // Match the theme background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            width: screenWidth < 600 ? screenWidth * 0.85 : screenWidth * 0.6,
            height: screenHeight * 0.6, // Set the height to be responsive
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Match text color
                    ),
                  ),
                  SizedBox(height: 10),
                  // Task details list, wrapped inside a scrollable widget
                  SingleChildScrollView(
                    scrollDirection:
                        Axis.horizontal, // Allow horizontal scrolling
                    child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: screenWidth),
                        child: TaskListWidget(
                          onDataFetched: (int totalTasks,
                              int closedTasks,
                              int pendingTasks,
                              int failedTasks,
                              int rejectedTasks,
                              int droptasks,
                              int assignTasks,
                              int executeTasks) {
                            setState(() {
                              totalTaskCount = totalTasks;
                              totalClosedTasks = closedTasks;
                              totalPendingTasks = pendingTasks;
                              totalFailedTasks = failedTasks;
                              totalRejectedTasks = rejectedTasks;
                              totalDropTasks = droptasks;
                              totalAssignedTasks = assignTasks;
                              totalExecuteTasks = executeTasks;
                            });
                          },
                        )
                        // Task list content
                        ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: Text(
                        'Close',
                        style: TextStyle(
                            color: Colors.white), // Match button text color
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    // Responsive design for different screen sizes
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return 2; // 2 columns for small screens
    } else if (screenWidth < 1200) {
      return 3; // 3 columns for medium screens
    } else {
      return 4; // 4 columns for large screens
    }
  }

  Widget _buildTaskCard(BuildContext context, String title, int count,
      double percentage, Color color) {
    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize =
        screenWidth * 0.03; // Base font size based on screen width

    return Card(
      elevation: 4.0,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$count',
                    style: TextStyle(
                        fontSize: baseFontSize, // Responsive font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                Icon(
                  Icons.task,
                  size: baseFontSize * 1.5,
                  color: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 4), // Adjust spacing
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontSize: baseFontSize * 1.2, color: Colors.white),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(height: 4), // Adjust spacing
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white,
              color: Colors.teal,
            ),
            SizedBox(height: 4), // Adjust spacing
            Text(
              '$percentage%',
              style: TextStyle(
                color: Colors.white,
                fontSize: baseFontSize * 0.9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalStatCard(BuildContext context, String title, int count,
      double percentage, Color color) {
    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize =
        screenWidth * 0.03; // Base font size based on screen width

    return Card(
      elevation: 4.0,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$count',
                    style: TextStyle(
                        fontSize: baseFontSize, // Responsive font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                Icon(
                  Icons.pause,
                  size: baseFontSize * 1.5,
                  color: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 4), // Adjust spacing
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontSize: baseFontSize * 1.1, color: Colors.white),
              ),
            ),
            SizedBox(height: 4), // Adjust spacing
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white,
              color: Colors.teal,
            ),
            SizedBox(height: 4), // Adjust spacing
            Text(
              '$percentage%',
              style: TextStyle(
                color: Colors.white,
                fontSize: baseFontSize * 0.9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard(
      BuildContext context, int efficiency, Color color) {
    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize =
        screenWidth * 0.03; // Base font size based on screen width

    return Card(
      elevation: 4.0,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Efficiency',
              style:
                  TextStyle(fontSize: baseFontSize * 1.2, color: Colors.white),
            ),
            SizedBox(height: 4), // Adjust spacing
            Text(
              '$efficiency%',
              style: TextStyle(
                fontSize: baseFontSize * 1.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4), // Adjust spacing
            LinearProgressIndicator(
              value: efficiency / 100,
              backgroundColor: Colors.white,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}

class TaskListWidget extends StatefulWidget {
  final Function(
      int totalTasks,
      int closedTasks,
      int pendingTasks,
      int failedTasks,
      int rejectedTasks,
      int droptasks,
      int assignTasks,
      int executeTasks) onDataFetched;

  TaskListWidget({required this.onDataFetched});
  @override
  _TaskListWidgetState createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  List<Map<String, String>> tasks = [];
  bool isLoading = true;
  String errorMessage = '';
  int totalTaskCount = 0; // Total tasks
  int totalClosedTasks = 0; // Total closed tasks
  int totalPendingTasks = 0; // Total pending tasks
  int totalFailedTasks = 0; // Total failed tasks
  int totalRejectedTasks = 0;
  int totalDropTasks = 0;
  int totalAssignedTasks = 0;
  int totalExecuteTasks = 0; // Total rejected tasks

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      String? token = await storage.read(key: 'token');
      String? employeeId = await storage.read(key: 'username');

      if (token == null || employeeId == null) {
        throw Exception('No token or employee ID found. Please login again.');
      }

      final apiUrl = 'api/tasks/tasksdetails/$employeeId';
      final response = await ApiGateway().getRequest(apiUrl, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['taskAssigns'] is List) {
          tasks = (data['taskAssigns'] as List)
              .map((task) {
                return {
                  'title': task['projectTask'].toString(),
                  'startDate': task['projectTaskStartDate'].toString(),
                  'targetDate': task['projectTaskTargetDate'].toString(),
                  'status': task['projectTaskStatus'].toString(),
                };
              })
              .toList()
              .cast<Map<String, String>>();

          // Set the total task count and status counts
          totalTaskCount = tasks.length;
          _countTasksByStatus();

          // Call the onDataFetched callback to update parent state
          widget.onDataFetched(
              totalTaskCount,
              totalClosedTasks,
              totalPendingTasks,
              totalFailedTasks,
              totalRejectedTasks,
              totalDropTasks,
              totalAssignedTasks,
              totalExecuteTasks);
        } else {
          throw Exception(
              'Unexpected data format: "taskAssigns" is not a list');
        }
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _countTasksByStatus() {
    totalClosedTasks = 0;
    totalPendingTasks = 0;
    totalFailedTasks = 0;
    totalRejectedTasks = 0;
    totalDropTasks = 0;

    for (var task in tasks) {
      switch (task['status']) {
        case 'Closed':
          totalClosedTasks++;
          break;
        case 'Pending Closure':
          totalPendingTasks++;
          break;
        case 'Task Failed':
          totalFailedTasks++;
          break;
        case 'Task Rejected':
          totalRejectedTasks++;
          break;
        case 'Drop':
          totalDropTasks++;
          break;
        case 'Assigned':
          totalAssignedTasks++;
          break;
        case 'Executing':
          totalExecuteTasks++;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
            ? Center(
                child: Text(errorMessage, style: TextStyle(color: Colors.red)))
            : _buildTaskList();
  }

  Widget _buildTaskList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Total Tasks: $totalTaskCount',
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Closed Tasks: $totalClosedTasks',
            style: TextStyle(fontSize: 16, color: Colors.green),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Pending Tasks: $totalPendingTasks',
            style: TextStyle(fontSize: 16, color: Colors.orange),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Failed Tasks: $totalFailedTasks',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Rejected Tasks: $totalRejectedTasks',
            style: TextStyle(fontSize: 16, color: Colors.redAccent),
          ),
        ),
        ...tasks.asMap().entries.map((entry) {
          int index = entry.key; // Get the index of the current task
          Map<String, String> task = entry.value; // Get the task data

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task ${index + 1}: ${task['title']}',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                Text(
                  'Start Date: ${task['startDate']}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  'Target Date: ${task['targetDate']}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  'Status: ${task['status']}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                Divider(color: Colors.white),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
