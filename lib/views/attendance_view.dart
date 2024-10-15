import 'dart:convert';

import 'package:erp/screens/login_screen.dart';
import 'package:erp/services/api_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:http/http.dart' as http;

class AttendanceView extends StatefulWidget {
  @override
  _AttendanceViewState createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<DateTime, Map<String, String>> attendanceData = {};
  late DateTime selectedDay;
  LeaveBalance leaveBalance = LeaveBalance(
    medicalLeave: 0,
    paidLeave: 0,
    casualLeave: 0,
    emergencyLeave: 0,
    shortLeavesRemainingMonth: 0,
    shortLeavesRemainingYear: 0,
    overtime: 0,
  );

  List<LeaveRequest> leaveRequests = [];
  List<OnSiteRequest> onSiteRequests = [];

  int leaveCurrentPage = 0;
  int onSiteCurrentPage = 0;
  final int itemsPerPage = 8; // Updated to 8 entries per page

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Sample attendance data
    _fetchAttendanceData();
    _fetchLeaveBalanceData();
    _fetchLeaveAndOnsiteRequests();

    selectedDay = DateTime.now();
  }

  Future<void> _fetchAttendanceData() async {
    try {
      // Read the token and employee ID from storage
      String? token = await storage.read(key: 'token');
      String? employeeId =
          await storage.read(key: 'username'); // Read the employee ID

      // Check if token or employee ID is available
      if (token == null || employeeId == null) {
        throw Exception('No token or employee ID found. Please login again.');
      }

      // Print the retrieved token and employee ID for debugging
      print('Token retrieved: $token');
      print('Employee ID retrieved: $employeeId');

      // Construct the URL dynamically with the employee ID
      final apiUrl = 'api/Attendance/currentmonth/$employeeId';

      // Call the ApiGateway's getRequest method to fetch attendance data
      final response = await ApiGateway().getRequest(apiUrl, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body); // Parse the JSON response

        // Check if the data is a list (multiple attendance records)
        if (data is List) {
          // Clear existing attendance data
          attendanceData.clear();

          // Iterate over each attendance record and store it in a map
          for (var record in data) {
            DateTime date = DateTime.parse(record['attDate']); // Parse the date
            String inTime =
                record['attInTime'] ?? 'No In Time'; // Use a fallback if null
            String outTime =
                record['attOutTime'] ?? 'No Out Time'; // Use a fallback if null
            String attstatus = record['attStatus'] ?? 'No Attendance Status';

            // Store the attendance data in the map
            attendanceData[date] = {
              'in': inTime,
              'out': outTime,
              'status': attstatus
            };

            print(
                'Fetched attendance for $date: $inTime, $outTime,$attstatus'); // Log the fetched data
          }

          setState(() {}); // Refresh UI after data is fetched
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      print('Error: $e'); // Handle errors as needed
    }
  }

  Future<void> _fetchLeaveBalanceData() async {
    try {
      String? token = await storage.read(key: 'token');
      String? employeeId = await storage.read(key: 'username');

      if (token == null || employeeId == null) {
        throw Exception('No token or employee ID found. Please login again.');
      }

      final apiUrl = 'api/Attendance/empleaves/$employeeId';
      final response = await ApiGateway().getRequest(apiUrl, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Print the entire API response to check its structure
        print('API Response: $data');

        // Assuming the data is in the format you provided
        setState(() {
          leaveBalance = LeaveBalance(
            medicalLeave: data['balanceML'] ?? 0, // Medical Leave balance
            paidLeave: data['balancePL'] ?? 0, // Paid Leave balance
            casualLeave: data['balanceCL'] ?? 0, // Casual Leave balance
            emergencyLeave: data['balanceEL'] ?? 0, // Emergency Leave balance
            shortLeavesRemainingMonth: 0, // Example value (if not in response)
            shortLeavesRemainingYear: 0, // Example value (if not in response)
            overtime: 0, // Example value for overtime hours
          );
        });

        print('Leave balance fetched: $leaveBalance');
      } else {
        throw Exception('Failed to load leave balance data');
      }
    } catch (e) {
      print('Error fetching leave balance: $e');
    }
  }

  Future<void> _fetchLeaveAndOnsiteRequests() async {
    try {
      String? token = await storage.read(key: 'token');
      String? employeeId = await storage.read(key: 'username');

      if (token == null || employeeId == null) {
        throw Exception('No token or employee ID found. Please login again.');
      }

      final apiUrl = 'api/Attendance';

      // Fetch leave details first
      Map<String, String> leaveRequestBody = {
        'id': employeeId,
        'LeaveType': 'leave'
      };

      print('Leave Request Body: $leaveRequestBody'); // Debugging line
      final leaveResponse = await ApiGateway()
          .postRequest(apiUrl, leaveRequestBody, token: token);

      print(
          'Leave Response Status: ${leaveResponse.statusCode}'); // Debugging line

      if (leaveResponse.statusCode == 200) {
        final leaveData = json.decode(leaveResponse.body);
        print(
            'Leave Response Data: $leaveData'); // Print the entire leave response for debugging

        if (leaveData['leaveDetails'] is List) {
          leaveRequests.clear(); // Clear existing leave requests

          for (var leave in leaveData['leaveDetails']) {
            print('Leave Item: $leave'); // Log each leave item

            try {
              LeaveRequest leaveRequest = LeaveRequest(
                leaveRequestNumber: leave['leaveRequestNumber'],
                leaveType: leave['leaveType'],
                leaveReason: leave['leaverReason'],
                leaveFromDate: DateTime.parse(leave['leaveFromDate']),
                leaveToDate: DateTime.parse(leave['leaveToDate']),
                leaveStatus: leave['leaveStatus'],
              );

              leaveRequests.add(leaveRequest);
              print(
                  'Fetched leave request: ${leaveRequest.leaveRequestNumber}, ${leaveRequest.leaveType}, ${leaveRequest.leaveFromDate}, ${leaveRequest.leaveToDate}, ${leaveRequest.leaveStatus}');
            } catch (e) {
              print('Error creating LeaveRequest: $e'); // Log any errors
            }
          }
        } else {
          throw Exception('Unexpected data format for leaveDetails.');
        }
      } else {
        print('Failed to load leave requests: ${leaveResponse.reasonPhrase}');
      }

      // Now fetch onsite details
      Map<String, String> onsiteRequestBody = {
        'id': employeeId,
        'LeaveType': 'onsite'
      };

      print('Onsite Request Body: $onsiteRequestBody'); // Debugging line
      final onsiteResponse = await ApiGateway()
          .postRequest(apiUrl, onsiteRequestBody, token: token);

      print(
          'Onsite Response Status: ${onsiteResponse.statusCode}'); // Debugging line

      if (onsiteResponse.statusCode == 200) {
        final onsiteData = json.decode(onsiteResponse.body);
        print(
            'Onsite Response Data: $onsiteData'); // Print the entire onsite response for debugging

        if (onsiteData['onSiteDetails'] is List) {
          onSiteRequests.clear(); // Clear existing onsite requests

          for (var onsite in onsiteData['onSiteDetails']) {
            print('Onsite Item: $onsite'); // Log each onsite item

            try {
              OnSiteRequest onsiteRequest = OnSiteRequest(
                onsiteRequestNumber: onsite['onSiteRequestNumber'],
                onsiteLocation: onsite['workSite'],
                onsiteReason: onsite['onSiteProject'],
                onsiteFromDate: DateTime.parse(onsite['onSiteFromDate']),
                onsiteToDate: DateTime.parse(onsite['onSiteToDate']),
                onsiteStatus: onsite['onSiteStatus'],
              );

              onSiteRequests.add(onsiteRequest);
              print(
                  'Fetched onsite request: ${onsiteRequest.onsiteRequestNumber}, ${onsiteRequest.onsiteLocation}, ${onsiteRequest.onsiteFromDate}, ${onsiteRequest.onsiteToDate}, ${onsiteRequest.onsiteStatus}');
            } catch (e) {
              print('Error creating OnsiteRequest: $e'); // Log any errors
            }
          }
        } else {
          throw Exception('Unexpected data format for onSiteDetails.');
        }
      } else {
        print('Failed to load onsite requests: ${onsiteResponse.reasonPhrase}');
      }

      setState(() {}); // Refresh the UI after both data are fetched
    } catch (e) {
      print('Error: $e'); // Handle errors as needed
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(screenSize.height * 0.04),
          child: TabBar(
            controller: _tabController,
            tabs: [
              const Tab(icon: Icon(Icons.check_circle), text: 'Attendance'),
              const Tab(icon: Icon(Icons.request_page), text: 'Leaves'),
              const Tab(icon: Icon(Icons.business_center), text: 'On-Site'),
            ],
            labelColor: Colors.white,
            indicatorColor: Colors.blue,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/images/product.avif'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAttendanceTab(screenSize),
            _buildLeaveRequestTab(screenSize),
            _buildOnSiteRequestTab(screenSize),
          ],
        ),
      ),
    );
  }

  void _showLeaveBalance(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF274047),
          title: Text('Leave Balance', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeaveRow('Casual Leave', leaveBalance.casualLeave),
              _buildLeaveRow('Paid Leave', leaveBalance.paidLeave),
              _buildLeaveRow('Medical Leave', leaveBalance.medicalLeave),
              _buildLeaveRow('Emergency Leave', leaveBalance.emergencyLeave),
              _buildLeaveRow('Short Leaves (Month)',
                  leaveBalance.shortLeavesRemainingMonth),
              _buildLeaveRow(
                  'Short Leaves (Year)', leaveBalance.shortLeavesRemainingYear),
              _buildLeaveRow('Overtime Hours', leaveBalance.overtime),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaveRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestTab(screensize) {
    int totalPages = (leaveRequests.length / itemsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildLeaveRequestTable(screensize)),
                _buildPaginationControls(leaveCurrentPage, totalPages,
                    (newPage) {
                  setState(() {
                    leaveCurrentPage = newPage;
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnSiteRequestTab(screenSize) {
    int totalPages = (onSiteRequests.length / itemsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On-Site Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildOnSiteRequestTable(screenSize)),
                _buildPaginationControls(onSiteCurrentPage, totalPages,
                    (newPage) {
                  setState(() {
                    onSiteCurrentPage = newPage;
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestTable(screenSize) {
    List<LeaveRequest> paginatedLeaveRequests = leaveRequests
        .skip(leaveCurrentPage * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: Color(0xFF274047).withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: screenSize.width * 0.04,
            columns: const [
              DataColumn(
                  label: Text('S.No', style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Leave Req Id',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Leave Type',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Leave Reason',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Dates', style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Status', style: TextStyle(color: Colors.white))),
            ],
            rows: paginatedLeaveRequests.asMap().entries.map((entry) {
              int index = entry.key;
              LeaveRequest leave = entry.value;
              return DataRow(cells: [
                DataCell(Text(
                  (index + 1 + leaveCurrentPage * itemsPerPage).toString(),
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
                DataCell(Text(
                  leave.leaveRequestNumber.toString(),
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
                DataCell(Text(
                  leave.leaveType,
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
                DataCell(Text(
                  leave.leaveReason ?? 'No reason provided',
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
                DataCell(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0), // Adds equal top and bottom padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.leaveFromDate.toString().split(' ')[0],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.03,
                          ),
                        ),
                        Text(
                          leave.leaveToDate.toString().split(' ')[0],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.03,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(Text(
                  leave.leaveStatus,
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOnSiteRequestTable(screenSize) {
    List<OnSiteRequest> paginatedOnSiteRequests = onSiteRequests
        .skip(onSiteCurrentPage * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: Color(0xFF274047).withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: screenSize.width * 0.04,
            columns: const [
              DataColumn(
                  label: Text('S.No', style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Onsite Req Id',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Onsite Location',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Dates', style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Status', style: TextStyle(color: Colors.white))),
            ],
            rows: paginatedOnSiteRequests.asMap().entries.map((entry) {
              int index = entry.key;
              OnSiteRequest onsite = entry.value;
              return DataRow(cells: [
                DataCell(Text(
                  (index + 1 + onSiteCurrentPage * itemsPerPage).toString(),
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
                DataCell(Text(
                  onsite.onsiteRequestNumber.toString(),
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
                DataCell(Text(
                  onsite.onsiteLocation,
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
                DataCell(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0), // Adds equal top and bottom padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          onsite.onsiteFromDate.toString().split(' ')[0],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.03,
                          ),
                        ),
                        Text(
                          onsite.onsiteToDate.toString().split(' ')[0],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.03,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(Text(
                  onsite.onsiteStatus,
                  style: TextStyle(
                      color: Colors.white, fontSize: screenSize.width * 0.03),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(
      int currentPage, int totalPages, Function(int) onPageChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back,
              color: currentPage > 0 ? Colors.white : Colors.grey),
          onPressed:
              currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
        ),
        Text(
          'Page ${currentPage + 1} of $totalPages', // Displaying current page
          style: TextStyle(color: Colors.white),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward,
              color: currentPage < totalPages - 1 ? Colors.white : Colors.grey),
          onPressed: currentPage < totalPages - 1
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }

  _buildAttendanceTab(Size screenSize) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance',
                  style: TextStyle(
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () => _showLeaveBalance(context),
                ),
              ],
            ),
            SizedBox(
              height: screenSize.height * 0.5,
              child: CalendarCarousel(
                onDayPressed: (DateTime date, List events) {
                  setState(() {
                    selectedDay = date;
                    _markSelectedDate(selectedDay);
                  });
                },
                weekendTextStyle: TextStyle(
                  color: Colors
                      .blue, // Default for Saturday, will change below for Sunday
                ),
                daysTextStyle: TextStyle(
                  color: Colors.white, // Default color for weekdays
                ),
                thisMonthDayBorderColor: Colors.transparent,
                selectedDayButtonColor: Colors.orangeAccent,
                selectedDayTextStyle: TextStyle(color: Colors.white),
                todayButtonColor: Colors.orangeAccent,
                todayTextStyle: TextStyle(color: Colors.white),
                daysHaveCircularBorder: true,

                // Custom dayBuilder to apply different colors for weekends
                customDayBuilder: (
                  bool isSelectable,
                  int index,
                  bool isSelectedDay,
                  bool isToday,
                  bool isPrevMonthDay,
                  TextStyle textStyle,
                  bool isNextMonthDay,
                  bool isThisMonthDay,
                  DateTime day,
                ) {
                  // Check if it's a weekend
                  if (day.weekday == DateTime.sunday) {
                    // Return Sunday with red color
                    return Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(color: Colors.purple),
                      ),
                    );
                  } else if (day.weekday == DateTime.saturday) {
                    // Return Saturday with a different color (e.g., blue)
                    return Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(color: Colors.purple),
                      ),
                    );
                  }

                  // Default behavior for other days
                  return null; // Uses the default daysTextStyle
                },

                markedDatesMap: EventList<Event>(
                  events: {
                    selectedDay: [
                      Event(date: selectedDay)
                    ] // Highlight selected date
                  },
                ),
                markedDateWidget: Container(
                  width: 30.0, // Fixed width to ensure consistent size
                  height: 30.0, // Fixed height to ensure consistent size
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5), // Semi-transparent box
                    border: Border.all(
                        color: Colors.orangeAccent,
                        width: 2.0), // Border for symmetry
                    borderRadius: BorderRadius.circular(
                        8.0), // Symmetrical box with rounded corners
                  ),
                  alignment: Alignment.center, // Center the text inside the box
                  child: Text(
                    "${selectedDay.day}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0, // Set a consistent font size
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildAttendanceDetails(selectedDay, screenSize),
          ],
        ),
      ),
    );
  }

  void _markSelectedDate(DateTime date) {
    if (date != null) {
      setState(() {
        selectedDay = date;
      });
    }
  }

  Widget _buildAttendanceDetails(DateTime date, Size screenSize) {
    // Normalize the selected day to avoid time conflicts (set time to 00:00:00)
    final normalizedSelectedDay = DateTime(date.year, date.month, date.day);
    final attendance = attendanceData[normalizedSelectedDay];

    if (attendance != null) {
      // If attendance data is available for the selected day
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Details for ${_formatDate(date)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center vertically
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center horizontally
                children: [
                  Text(
                    'In Time: ${attendance['in'] ?? 'No In Time'}', // Fallback for missing in time
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Out Time: ${attendance['out'] ?? 'No Out Time'}', // Fallback for missing out time
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Status: ${attendance['status'] ?? 'Absent'}', // Fallback for missing out time
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // If no attendance data is available for the selected day
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red[800], // Different color to indicate missing data
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'No attendance data available for ${_formatDate(date)}.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

// Helper method to format the date in a more readable way
  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }
}

class LeaveRequest {
  final int leaveRequestNumber;
  final String leaveType;
  final String leaveReason;
  final DateTime leaveFromDate;
  final DateTime leaveToDate;
  final String leaveStatus;

  LeaveRequest({
    required this.leaveRequestNumber,
    required this.leaveType,
    required this.leaveReason,
    required this.leaveFromDate,
    required this.leaveToDate,
    required this.leaveStatus,
  });
}

class OnSiteRequest {
  final int onsiteRequestNumber;

  final String onsiteLocation;
  final String onsiteReason;
  final DateTime onsiteFromDate;
  final DateTime onsiteToDate;
  final String onsiteStatus;

  OnSiteRequest({
    required this.onsiteRequestNumber,
    required this.onsiteLocation,
    required this.onsiteReason,
    required this.onsiteFromDate,
    required this.onsiteToDate,
    required this.onsiteStatus,
  });
}

class LeaveBalance {
  final int medicalLeave;
  final int paidLeave;
  final int casualLeave;
  final int emergencyLeave;
  final int shortLeavesRemainingMonth;
  final int shortLeavesRemainingYear;
  final int overtime;

  LeaveBalance({
    required this.medicalLeave,
    required this.paidLeave,
    required this.casualLeave,
    required this.emergencyLeave,
    required this.shortLeavesRemainingMonth,
    required this.shortLeavesRemainingYear,
    required this.overtime,
  });
}

extension DateTimeExtensions on DateTime {
  String toShortDateString() {
    return "${this.day}/${this.month}/${this.year}";
  }
}
