import 'package:dollar_sense/category.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';
import 'add_expense_custom_input_view.dart';

class AddCategoryPage extends StatefulWidget {
  final String username;

  const AddCategoryPage({required this.username});

  @override
  _AddCategoryPageState createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  String _selectedType = 'expenses';
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> saveCategoryToFirestore(String username, String newCategory,
      BuildContext context) async {
    // Query Firestore to get the user ID from the username
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;

      // Determine the field name based on the selected type
      String fieldName = _selectedType == 'expenses'
          ? 'expense_category'
          : 'budget_category';

      // Retrieve the current categories array or create an empty array if it doesn't exist
      List<String> currentCategories = (userSnapshot.docs.first.data() as Map<
          String,
          dynamic>?)?[fieldName]?.cast<String>() ?? [];

      // Check if the new category already exists in the current categories
      if (currentCategories.contains(newCategory)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category already exists')),
        );
      } else {
        // Add the new category to the existing categories array
        currentCategories.add(newCategory);

        // Update the categories array in Firestore
        await FirebaseFirestore.instance.collection('dollar_sense')
            .doc(userId)
            .update({
          fieldName: currentCategories,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New category successfully added')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }
  }

  void _addCategory(BuildContext context) {
    final newCategory = _categoryController.text.trim();
    if (newCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category name cannot be empty')),
      );
      return;
    }

    saveCategoryToFirestore(widget.username, newCategory, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Add Category'),
        actions: [
          IconButton(
            icon: Icon(Icons.view_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoriesPage(username: widget.username),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white, // Background color for the input field
                ),
                child: CustomInputField(
                  controller: _categoryController,
                  labelText: 'Category Name',
                  inputFormatters: [],
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFE1E3E7),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF39383D)),
                ),
                child: DropdownButton<String>(
                  value: _selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                  items: <String>['expenses', 'budget']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  isExpanded: true,
                  underline: Container(),
                  // Remove the underline
                  iconEnabledColor: Color(0xFF004F9B),
                  dropdownColor: Colors.white,
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(), // Empty container to occupy space
                  ),
                  SizedBox(
                    height: 50,
                    // Adjust the height of the SizedBox for the button
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFF547FA3),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _addCategory(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          // Transparent background color
                          elevation: 0,
                          // No shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Rounded corners
                          ),
                        ),
                        child: Text(
                          'Add Category',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(
            context, widget.username),
      ).build(),
    );
  }
}