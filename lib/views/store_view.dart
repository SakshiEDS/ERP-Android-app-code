import 'dart:convert';

import 'package:erp/screens/login_screen.dart';
import 'package:erp/services/api_gateway.dart';
import 'package:flutter/material.dart';

// Define a class for the items in the store
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

// Create a Stateful Widget for Store View
class StoreView extends StatefulWidget {
  @override
  _StoreViewState createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  String selectedCategory = 'Raw Materials'; // Default selected category
  List<StoreItem> allItems = []; // List to hold fetched item data
  int currentPage = 0;
  final int itemsPerPage = 8;
  String searchQuery = ''; // New state variable for search query
  bool isSearchVisible = false;
  TextEditingController searchController = TextEditingController();
  // Toggle visibility of the search field

  @override
  void initState() {
    super.initState();
    fetchStoreData();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text; // Update search query
        currentPage = 0; // Reset to first page when searching
      });
    }); // Fetch data when the widget initializes
  }

  Future<void> fetchStoreData() async {
    String apiUrl;

    if (selectedCategory == 'Raw Materials') {
      apiUrl = 'api/store/getrawmaterialsdata';
    } else if (selectedCategory == 'Finished Goods') {
      apiUrl = 'api/store/getfinishedgoodsdata';
    } else if (selectedCategory == 'Semi Finished Goods') {
      apiUrl = 'api/store/getsemifinishedgoodsdata';
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
            } else if (selectedCategory == 'Finished Goods') {
              return StoreItem(
                itemNo: itemData['sno'].toString(),
                itemName: itemData['productName'] ?? 'N/A',
                partNumber: itemData['rawMaterialPartNumber'] ?? 'N/A',
                description: itemData['productDescription'] ?? 'N/A',
                category: 'Finished Goods',
                quantity: itemData['quantity'] ?? 0,
                ratingUnit: itemData['rating'] ?? 'N/A',
                dateEntry: itemData['dateEntry'] ?? 'N/A',
                entryBy: itemData['entryBy'] ?? 0,
                price: (itemData['rawMaterialPricePerPiece'] ?? 0).toDouble(),
                manufacturer: itemData['rawMaterialManufacturer'] ?? 'N/A',
                sampleQuantity: itemData['rawMaterialSampleQuantity'] ?? 0,
                samplePrice: (itemData['rawMaterialSamplePricePerPiece'] ?? 0)
                    .toDouble(),
                minQuantity: itemData['rawMaterialMinQuantity'] ?? 0,
                maxQuantity: itemData['rawMaterialMaxQuantity'] ?? 0,
              );
            } else if (selectedCategory == 'Semi Finished Goods') {
              return StoreItem(
                itemNo: itemData['sNo'].toString(),
                itemName: itemData['productName'] ?? 'N/A',
                partNumber: itemData['rawMaterialPartNumber'] ?? 'N/A',
                description: itemData['productDescription'] ?? 'N/A',
                category: 'Semi Finished Goods',
                quantity: itemData['quantity'] ?? 0,
                ratingUnit: itemData['rating'] ?? 'N/A',
                dateEntry: itemData['dateEntry'] ?? 'N/A',
                entryBy: itemData['entryBy'] ?? 0,
                price: (itemData['rawMaterialPricePerPiece'] ?? 0).toDouble(),
                manufacturer: itemData['rawMaterialManufacturer'] ?? 'N/A',
                sampleQuantity: itemData['rawMaterialSampleQuantity'] ?? 0,
                samplePrice: (itemData['rawMaterialSamplePricePerPiece'] ?? 0)
                    .toDouble(),
                minQuantity: itemData['rawMaterialMinQuantity'] ?? 0,
                maxQuantity: itemData['rawMaterialMaxQuantity'] ?? 0,
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

  // Get the filtered items based on selected category
  List<StoreItem> get filteredItems {
    // Filter items by category and search query
    return allItems.where((item) {
      final matchesCategory = item.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          item.itemName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Get the items to display on the current page
  List<StoreItem> get paginatedItems {
    int startIndex = currentPage * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    return filteredItems.sublist(startIndex,
        endIndex < filteredItems.length ? endIndex : filteredItems.length);
  }

  // Sorting logic
  void sortItems(Comparable Function(StoreItem) getField) {
    setState(() {
      filteredItems
          .sort((a, b) => Comparable.compare(getField(a), getField(b)));
    });
  }

  List<DataColumn> getDataTableColumns(double screenWidth) {
    double headingFontSize = screenWidth * 0.035;

    List<DataColumn> columns = [];

    if (selectedCategory == 'Raw Materials') {
      columns = [
        DataColumn(
          label: Center(
              child: Text('S. No',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Unique ID',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Description',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Quantity',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Price Val.',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Manufacturer',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Rating Unit',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Min Qty.',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Max Qty.',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Entry Date',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Entry By',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Sample Qty',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
        DataColumn(
          label: Center(
              child: Text('Sample Price',
                  style: TextStyle(
                      fontSize: headingFontSize, color: Colors.white))),
        ),
      ];
    } else if (selectedCategory == 'Finished Goods') {
      // Define columns for Finished Goods category
      columns = [
        DataColumn(
            label: Center(
                child: Text('S. No',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Product Name',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Description',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Quantity',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Rating Unit',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Entry Date',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Entry By',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Price Val.',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
      ];
    } else if (selectedCategory == 'Semi Finished Goods') {
      // Define columns for Semi Finished Goods category
      columns = [
        DataColumn(
            label: Center(
                child: Text('S. No',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Product Name',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Description',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Quantity',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Rating Unit',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Entry Date',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Entry By',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
        DataColumn(
            label: Center(
                child: Text('Price Val.',
                    style: TextStyle(
                        fontSize: headingFontSize, color: Colors.white)))),
      ];
    }

    return columns;
  }

  List<DataRow> getDataTableRows(double screenWidth) {
    int itemsPerPage = 8; // Number of items displayed per page
    int startingIndex = currentPage *
        itemsPerPage; // Calculate the starting index based on current page

    if (selectedCategory == 'Raw Materials') {
      return paginatedItems.asMap().entries.map((entry) {
        int index = entry.key +
            startingIndex; // Adjust index to be continuous across pages
        var item = entry.value;

        return DataRow(cells: <DataCell>[
          DataCell(Center(
              child: Text((index + 1).toString(), // Auto-incrementing S.No
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.itemName,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.description,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.quantity.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.price.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.manufacturer,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.white)))), // Placeholder for Manufacturer
          DataCell(Center(
              child: Text(item.ratingUnit,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.minQuantity.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.maxQuantity.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.dateEntry,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.entryBy.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.sampleQuantity.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.samplePrice.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.white)))), // Placeholder for Rating Unit
        ]);
      }).toList();
    } else if (selectedCategory == 'Finished Goods') {
      return paginatedItems.asMap().entries.map((entry) {
        int index =
            entry.key + startingIndex; // Adjust index for Finished Goods
        var item = entry.value;

        return DataRow(cells: <DataCell>[
          DataCell(Center(
              child: Text((index + 1).toString(), // Auto-incrementing S.No
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.itemName,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.description,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.quantity.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.ratingUnit,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.dateEntry,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.entryBy.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.price.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
        ]);
      }).toList();
    } else if (selectedCategory == 'Semi Finished Goods') {
      return paginatedItems.asMap().entries.map((entry) {
        int index =
            entry.key + startingIndex; // Adjust index for Semi Finished Goods
        var item = entry.value;

        return DataRow(cells: <DataCell>[
          DataCell(Center(
              child: Text((index + 1).toString(), // Auto-incrementing S.No
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.itemName,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.description,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.quantity.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.ratingUnit,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.dateEntry,
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.entryBy.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
          DataCell(Center(
              child: Text(item.price.toString(),
                  style: TextStyle(
                      fontSize: screenWidth * 0.035, color: Colors.white)))),
        ]);
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    int totalPages = (filteredItems.length / itemsPerPage).ceil();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/product.avif'), // Change to your background image path
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.01, // Reduce horizontal padding
          vertical: 8.0,
        ),
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
                      hintText: 'Enter item name or description',
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
              'Select Category:',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Adjust text color for visibility
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Raw Materials Radio Button
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Raw Materials',
                        groupValue: selectedCategory,
                        onChanged: (String? value) {
                          setState(() {
                            selectedCategory = value!;
                            currentPage = 0;
                          });
                          fetchStoreData(); // Fetch data when category changes
                        },
                      ),
                      Text(
                        'Raw',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Finished Goods Radio Button
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Finished Goods',
                        groupValue: selectedCategory,
                        onChanged: (String? value) {
                          setState(() {
                            selectedCategory = value!;
                            currentPage = 0;
                          });
                          fetchStoreData(); // Fetch data when category changes
                        },
                      ),
                      Text(
                        'Finished',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Semi Finished Goods Radio Button
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Semi Finished Goods',
                        groupValue: selectedCategory,
                        onChanged: (String? value) {
                          setState(() {
                            selectedCategory = value!;
                            currentPage = 0;
                          });
                          fetchStoreData(); // Fetch data when category changes
                        },
                      ),
                      Text(
                        'Semi Finished',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical, // Allow vertical scrolling
                child: SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal, // Allow horizontal scrolling
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth *
                            0.03), // Adjust the horizontal padding as needed
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF274047).withOpacity(
                            0.5), // Set background color with opacity
                        borderRadius: BorderRadius.circular(
                            10), // Optional: Add some border radius
                      ),
                      child: DataTable(
                        columnSpacing: screenWidth * 0.03,
                        columns: getDataTableColumns(screenWidth),
                        rows: getDataTableRows(screenWidth),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pagination
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
                  'Page ${currentPage + 1} of $totalPages', // Displaying current page
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
