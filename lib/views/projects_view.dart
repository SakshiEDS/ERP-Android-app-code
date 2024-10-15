import 'dart:convert'; // For JSON decoding
import 'package:erp/screens/login_screen.dart';
import 'package:erp/services/api_gateway.dart';
import 'package:flutter/material.dart';

class Project {
  final int projectNumber;
  final String projectName;
  final String projectManager;
  final String projectStatus;
  final double efficiency;

  Project({
    required this.projectNumber,
    required this.projectName,
    required this.projectManager,
    required this.projectStatus,
    required this.efficiency,
  });
}

class ProjectsView extends StatefulWidget {
  @override
  _ProjectsViewState createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  String filterStatus = 'All'; // Default filter option
  static const Color myCustomColor = Color(0xFF274047);
  static const Color appBarColor = Colors.teal;

  int currentPage = 0; // Current page index
  final int entriesPerPage = 8; // Number of entries per page

  List<Project> allProjects = []; // List to hold fetched project data

  // New code for search functionality
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isSearchVisible = false; // Track visibility of search field

  @override
  void initState() {
    super.initState();
    _fetchProjectsData(); // Fetch data on widget load
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text; // Update search query
        currentPage = 0; // Reset to first page when searching
      });
    });
  }

  String getEmployeeName(int empId, List<dynamic> employees) {
    final employee = employees.firstWhere(
      (emp) => emp['empId'] == empId,
      orElse: () => null,
    );
    return employee != null ? employee['empName'] : 'Unknown';
  }

  Future<List<dynamic>> _fetchProjectEfficiencyData() async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('No token found. Please login again.');
    }

    final efficiencyApiUrl = 'api/projects/projectsefficiency';
    final efficiencyResponse =
        await ApiGateway().getRequest(efficiencyApiUrl, token);
    if (efficiencyResponse.statusCode == 200) {
      return json.decode(efficiencyResponse.body);
    } else {
      throw Exception(
          'Failed to load efficiency data with status: ${efficiencyResponse.statusCode}');
    }
  }

  Future<void> _fetchProjectsData() async {
    try {
      String? token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('No token found. Please login again.');
      }

      final apiUrl = 'api/projects/projectsdata';
      final response = await ApiGateway().getRequest(apiUrl, token);
      print('Full Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response Data: $data');

        List<dynamic> efficiencyData = await _fetchProjectEfficiencyData();

        if (data.containsKey('projectsName') &&
            data['projectsName'] is List &&
            data.containsKey('employees')) {
          List<dynamic> employees = data['employees'];

          allProjects = (data['projectsName'] as List).map((projectData) {
            print('Mapping project data: $projectData');

            String projectManagerName =
                getEmployeeName(projectData['projectManager'], employees);

            var matchingEfficiency = efficiencyData.firstWhere(
              (eff) => eff['projectName'] == projectData['projectName'],
              orElse: () => {'efficiency': 0},
            );

            return Project(
              projectNumber: projectData['projectNumber'] ?? 0,
              projectName: projectData['projectName'] ?? 'N/A',
              projectManager: projectManagerName,
              projectStatus: projectData['projectStatus'] ?? 'Unknown',
              efficiency: matchingEfficiency['efficiency'].toDouble(),
            );
          }).toList();

          setState(() {});
        } else {
          throw Exception(
              'Unexpected data format: projectsName or employees key is missing or not a list');
        }
      } else {
        throw Exception(
            'Failed to load project data with status: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('Error: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  // Modify the filteredProjects to consider search query
  List<Project> get filteredProjects {
    List<Project> filtered = allProjects;

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        return project.projectName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            project.projectManager
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply the filter status logic after search filtering
    if (filterStatus == 'Complete') {
      filtered = filtered
          .where((project) => project.projectStatus == 'Closed')
          .toList();
    } else if (filterStatus == 'Pending') {
      filtered = filtered
          .where((project) => project.projectStatus != 'Closed')
          .toList();
    }

    return filtered;
  }

  List<Project> get paginatedProjects {
    int start = currentPage * entriesPerPage;
    int end = start + entriesPerPage;
    return filteredProjects.sublist(
      start,
      end > filteredProjects.length ? filteredProjects.length : end,
    );
  }

  int get totalPages {
    return (filteredProjects.length / entriesPerPage).ceil();
  }

  void changePage(int newPage) {
    setState(() {
      currentPage = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: myCustomColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/product.avif'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), BlendMode.darken),
          ),
        ),
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isSearchVisible =
                          !isSearchVisible; // Toggle search field visibility
                    });
                  },
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min, // Ensures button width fits content
                    children: [
                      Icon(
                        isSearchVisible
                            ? Icons.close
                            : Icons.search, // Toggle icons
                        // Set icon color
                      ),
                      SizedBox(
                          width: 8), // Add some space between icon and text
                      Text(
                        isSearchVisible ? 'Close' : 'Search',
                        // Set text color
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSearchVisible) // Only show the search field when visible
              Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    controller: searchController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter project name or manager',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            SizedBox(height: screenHeight * 0.02),

            Text(
              'Filter by Status:',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: ['All', 'Pending', 'Complete'].map((status) {
                return Row(
                  children: [
                    Radio<String>(
                      value: status,
                      groupValue: filterStatus,
                      onChanged: (String? value) {
                        setState(() {
                          filterStatus = value!;
                          currentPage = 0;
                        });
                      },
                      activeColor: Colors.teal,
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: screenHeight * 0.02),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          color: myCustomColor.withOpacity(0.5),
                          child: DataTable(
                            columnSpacing: screenWidth * 0.02,
                            columns: <DataColumn>[
                              DataColumn(
                                label: Center(
                                  child: Text(
                                    'S.No',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Center(
                                  child: Text(
                                    'Project Details',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Center(
                                  child: Text(
                                    'Project Manager',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Center(
                                  child: Text(
                                    'Efficiency',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            rows:
                                paginatedProjects.asMap().entries.map((entry) {
                              int index = (currentPage * entriesPerPage) +
                                  entry.key +
                                  1;
                              Project project = entry.value;
                              return DataRow(
                                cells: <DataCell>[
                                  DataCell(
                                    Center(
                                      child: Text(
                                        index.toString(),
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.03,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        project.projectName,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.03,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        project.projectManager,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.03,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        project.projectStatus == 'Closed'
                                            ? '100%'
                                            : '${project.efficiency}%',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.03,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // Responsive spacing

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: currentPage > 0 ? Colors.white : Colors.grey),
                  onPressed: currentPage > 0
                      ? () {
                          setState(() {
                            currentPage--;
                          });
                        }
                      : null,
                ),
                Text(
                  'Page ${currentPage + 1} of $totalPages',
                  style: TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward,
                      color: currentPage < totalPages - 1
                          ? Colors.white
                          : Colors.grey),
                  onPressed: currentPage < totalPages - 1
                      ? () {
                          setState(() {
                            currentPage++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
