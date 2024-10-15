import 'package:erp/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:erp/views/attendance_view.dart';
import 'package:erp/views/task_management_view.dart';
import 'projects_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:erp/services/api_gateway.dart';
import 'dart:convert';

class StoreItem {
  final String itemNo;
  final String itemName;
  final String partNumber; // New field for part number
  final String description; // General description field for all items
  final String manufacturer; // New field for manufacturer
  final String ratingUnit; // New field for rating unit
  final double price; // Price per piece
  final int quantity; // Available quantity
  final int minQuantity; // Minimum quantity
  final int maxQuantity; // Maximum quantity
  final String dateEntry; // Entry date
  final int entryBy; // Entry by user ID
  final int sampleQuantity; // Sample quantity
  final double samplePrice;
  final String category; // Sample price per piece

  StoreItem({
    required this.itemNo,
    required this.itemName,
    required this.partNumber,
    required this.description,
    required this.manufacturer,
    required this.ratingUnit,
    required this.price,
    required this.quantity,
    required this.minQuantity,
    required this.maxQuantity,
    required this.dateEntry,
    required this.entryBy,
    required this.sampleQuantity,
    required this.samplePrice,
    required this.category,
  });
}

class DashboardView extends StatefulWidget {
  final Function(int) onCardTap;

  DashboardView({required this.onCardTap});

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<double> efficiencyData = [];
  bool isLoadingEfficiency = true;
  String? efficiencyErrorMessage;
  final List<String> todaysTasks = ['Task 1', 'Task 2', 'Task 3'];
  List<StoreItem> allItems = [];
  String selectedCategory = 'Raw Materials';
  @override
  void initState() {
    super.initState();
    _fetchEfficiency();
    fetchStoreData(); // Fetch efficiency data when the widget initializes
  }

  // Your fetch efficiency method
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
          if (mounted) {
            setState(() {
              // Since efficiency is a single value, store it as a single double
              efficiencyData = [
                data['efficiency'].toDouble()
              ]; // Store it in a list
            });
          }
        } else {
          throw Exception('Unexpected data format: "efficiency" not found');
        }
      } else {
        throw Exception('Failed to load efficiency: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          efficiencyErrorMessage = e.toString(); // Store the error message
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingEfficiency = false; // Update loading state
        });
      }
    }
  }

  Future<void> fetchStoreData() async {
    String apiUrl;

    if (selectedCategory == 'Raw Materials') {
      apiUrl = 'api/store/getrawmaterialsdata';
    } else {
      return; // Handle unexpected category
    }

    try {
      // Fetch data using your ApiGateway (assuming it handles token authentication)
      String? token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('No token found. Please login again.');
      }

      final response = await ApiGateway().getRequest(apiUrl, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          allItems = (data as List).map((itemData) {
            // Handle the different types of responses based on the category
            if (selectedCategory == 'Raw Materials') {
              return StoreItem(
                itemNo: itemData['sno']
                    .toString(), // Use 'sno' from your raw material data
                itemName: itemData['rawMaterialUniqueId'] ?? 'N/A',
                partNumber: itemData['rawMaterialPartNumber'] ?? 'N/A',
                description: itemData['rawMaterialDescription'] ?? 'N/A',
                manufacturer: itemData['rawMaterialManufacturer'] ?? 'N/A',
                ratingUnit: itemData['rawMaterialRatingUnit'] ?? 'N/A',
                category: 'Raw Materials',
                quantity: itemData['rawMaterialQuantity'] ?? 0,
                minQuantity: itemData['rawMaterialMinQuantity'] ?? 0,
                maxQuantity: itemData['rawMaterialMaxQuantity'] ?? 0,
                dateEntry: itemData['rawMaterialDateEntry'] ?? 'N/A',
                entryBy: itemData['rawMaterialEntryBy'] ?? 0,
                sampleQuantity: itemData['rawMaterialSampleQuantity'] ?? 0,
                price: (itemData['rawMaterialPricePerPiece'] ?? 0).toDouble(),
                samplePrice: (itemData['rawMaterialSamplePricePerPiece'] ?? 0)
                    .toDouble(),
              );
            }
            throw Exception('Unknown category');
          }).toList();
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e, stackTrace) {
      print('Error fetching data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFF274047),
          image: DecorationImage(
            image: AssetImage('assets/images/product.avif'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.count(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: screenSize.width < 600
                            ? 2
                            : 4, // Adjust number of columns based on screen width
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 1.5,
                        children: [
                          _buildCard(
                            'Today\'s In Time',
                            '9:00 AM',
                            Icons.access_time,
                            Colors.blue,
                            onCardTap: () => widget.onCardTap(1),
                          ),
                          _buildCard(
                            'Today\'s Out Time',
                            '5:00 PM',
                            Icons.exit_to_app,
                            Colors.green,
                            onCardTap: () => widget.onCardTap(1),
                          ),
                          _buildTaskCard('Today\'s Tasks', todaysTasks),
                          _buildProjectsCard(),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: screenSize.height *
                            0.05), // Use screen height for padding
                    _buildHorizontalScroll(),
                    SizedBox(height: screenSize.height * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalScroll() {
    return Container(
      height: 220,
      color: Color(0xFF274047).withOpacity(0.5),
      child: PageView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildLineChartWithHeader(),
          _buildPieChartWithHeader(),
        ],
      ),
    );
  }

  Widget _buildLineChartWithHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.center, // Align the heading to the left
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 20.0, bottom: 0.0), // Adjust padding for the heading
          child: Text(
            'Efficiency Over the time', // Heading text
            style: TextStyle(
              fontSize: 12, // Heading size
              fontWeight: FontWeight.bold, // Bold for emphasis
              color: Colors.white, // Heading color
            ),
          ),
        ),
        _buildLineChart(), // Call the existing chart building method
      ],
    );
  }

  Widget _buildPieChartWithHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.center, // Align the heading to the left
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 20.0, bottom: 0.0), // Adjust padding for the heading
          child: Text(
            'Store', // Heading text
            style: TextStyle(
              fontSize: 12, // Heading size
              fontWeight: FontWeight.bold, // Bold for emphasis
              color: Colors.white, // Heading color
            ),
          ),
        ),
        _buildPieChart(), // Call the existing chart building method
      ],
    );
  }

  Widget _buildLineChart() {
    if (isLoadingEfficiency) {
      return Center(child: CircularProgressIndicator());
    }

    if (efficiencyErrorMessage != null) {
      return Center(
          child: Text(efficiencyErrorMessage!,
              style: TextStyle(color: Colors.red)));
    }

    // Check if the efficiencyData is empty
    if (efficiencyData.isEmpty) {
      return Center(
          child: Text('No efficiency data available',
              style: TextStyle(color: Colors.white)));
    }

    // Generate month labels dynamically for the last three months
    List<String> months = [];
    for (int i = 2; i >= 0; i--) {
      DateTime date = DateTime.now()
          .subtract(Duration(days: 30 * i)); // Get past three months
      months.add('${_getMonthName(date.month)} ${date.year}');
    }

    // Ensure we have three data points
    while (efficiencyData.length < 3) {
      efficiencyData.insert(
          0, 0.0); // Default to 0 if we have less than 3 months of data
    }

    // Generate spots from the fetched data
    List<FlSpot> spots = efficiencyData.asMap().entries.map((entry) {
      int index = entry.key;
      double value = entry.value;
      return FlSpot(index.toDouble(), value); // (X, Y) coordinates
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 15.0), // Adjust left padding here
      child: Container(
        width: 350,
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false, // Disable vertical grid lines
              horizontalInterval: 20, // Adjust for percentage grid
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.5),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50, // Add space on the left side
                  interval: 20, // Display every 20% on Y-axis
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          right: 8.0), // Extra space between label and Y-axis
                      child: Text(
                        '${value.toInt()}%', // Y-axis label
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      months[value.toInt()], // Month labels for the X-axis
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                  interval: 1, // Show each month
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 1),
                left: BorderSide(color: Colors.white, width: 1),
              ),
            ),
            minX: 0,
            maxX: (efficiencyData.length - 1)
                .toDouble(), // Set maxX based on the number of data points
            minY: 0,
            maxY: 100, // Efficiency as a percentage
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false, // Ensure straight lines
                dotData: FlDotData(
                  show: true, // Show dots
                  checkToShowDot: (spot, barData) {
                    return true; // Show dot on every data point
                  },
                ),
                belowBarData:
                    BarAreaData(show: false), // No fill below the line
                color: Colors.white, // Line color
                barWidth: 2, // Thickness of the line
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper method to get month names
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  Widget _buildPieChart() {
    if (allItems.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Initialize pie chart sections
    List<PieChartSectionData> sections = [];
    int normalCount = 0;
    int highCount = 0;
    int lowCount = 0;
    int noRangeCount = 0;

    for (var item in allItems) {
      if (item.minQuantity == 0 && item.maxQuantity == 0) {
        // No min and max quantity
        noRangeCount++;
      } else if (item.quantity < item.minQuantity) {
        // Below min quantity
        lowCount++;
      } else if (item.quantity > item.maxQuantity) {
        // Above max quantity
        highCount++;
      } else {
        // Within the range
        normalCount++;
      }
    }

    // Prepare the pie chart data based on counts without titles
    if (normalCount > 0) {
      sections.add(
        PieChartSectionData(
          value: normalCount.toDouble(),
          color: Colors.green,
          title: '', // Removed title
        ),
      );
    }
    if (highCount > 0) {
      sections.add(
        PieChartSectionData(
          value: highCount.toDouble(),
          color: Colors.red,
          title: '', // Removed title
        ),
      );
    }
    if (lowCount > 0) {
      sections.add(
        PieChartSectionData(
          value: lowCount.toDouble(),
          color: Colors.orange,
          title: '', // Removed title
        ),
      );
    }
    if (noRangeCount > 0) {
      sections.add(
        PieChartSectionData(
          value: noRangeCount.toDouble(),
          color: Colors.blue,
          title: '', // Removed title
        ),
      );
    }

    return Row(
      children: [
        // Pie Chart
        Expanded(
          child: Container(
            width: 300,
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 0, // No space between sections
              ),
            ),
          ),
        ),
        // Legend
        SizedBox(width: 20), // Add space between the chart and legend
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (normalCount > 0) _buildLegendItem('Normal', Colors.green),
            if (highCount > 0) _buildLegendItem('High', Colors.red),
            if (lowCount > 0) _buildLegendItem('Low', Colors.orange),
            if (noRangeCount > 0)
              _buildLegendItem(
                'No Range',
                Colors.blue,
              )
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Add padding between items
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            color: color,
          ),
          SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsCard() {
    return GestureDetector(
      onTap: () {
        widget.onCardTap(4);
      },
      child: Card(
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Color(0xFF274047).withOpacity(0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(6),
                child: Icon(Icons.folder, color: Colors.orange, size: 20),
              ),
              SizedBox(height: 8),
              Text(
                'Projects',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage Your Projects',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String data, IconData icon, Color iconColor,
      {required VoidCallback onCardTap}) {
    return GestureDetector(
      onTap: onCardTap,
      child: Card(
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Color(0xFF274047).withOpacity(0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(6),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                data,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(String title, List<String> tasks) {
    return GestureDetector(
      onTap: () {
        widget.onCardTap(2);
      },
      child: Card(
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Color(0xFF274047).withOpacity(0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(6),
                child: Icon(Icons.assignment, color: Colors.red, size: 20),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your tasks.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
