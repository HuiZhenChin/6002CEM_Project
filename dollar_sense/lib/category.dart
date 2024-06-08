import 'package:dollar_sense/add_category.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class CategoriesPage extends StatefulWidget {
  final String username;

  const CategoriesPage({required this.username});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<String> _expenseCategories = [];
  List<String> _budgetCategories = [];
  bool _isLoading = true;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      // Query Firestore to get the user ID from the username
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: widget.username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        Map<String, dynamic>? userData = userSnapshot.docs.first.data() as Map<String, dynamic>?;

        setState(() {
          _expenseCategories = (userData?['expense_category'] as List<dynamic>?)?.cast<String>() ?? [];
          _budgetCategories = (userData?['budget_category'] as List<dynamic>?)?.cast<String>() ?? [];
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching categories: $e')),
      );
    }
  }

  Future<void> _deleteCategory(String category, String type) async {
    try {
      // Query Firestore to get the user ID from the username
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: widget.username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;

        // Determine the field name based on the category type
        String fieldName = type == 'expenses' ? 'expense_category' : 'budget_category';

        // Retrieve the current categories array
        List<String> currentCategories = (userSnapshot.docs.first.data() as Map<String, dynamic>?)?[fieldName]?.cast<String>() ?? [];

        // Remove the category from the array
        currentCategories.remove(category);

        // Update the categories array in Firestore
        await FirebaseFirestore.instance.collection('dollar_sense').doc(userId).update({
          fieldName: currentCategories,
        });

        // Update the local state
        setState(() {
          if (type == 'expenses') {
            _expenseCategories = currentCategories;
          } else {
            _budgetCategories = currentCategories;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category successfully deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  Future<void> _renameCategory(String oldCategory, String type) async {
    TextEditingController _renameController = TextEditingController();
    _renameController.text = oldCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Category'),
          content: TextField(
            controller: _renameController,
            decoration: InputDecoration(labelText: 'New Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Query Firestore to get the user ID from the username
                  QuerySnapshot userSnapshot = await FirebaseFirestore.instance
                      .collection('dollar_sense')
                      .where('username', isEqualTo: widget.username)
                      .get();

                  if (userSnapshot.docs.isNotEmpty) {
                    String userId = userSnapshot.docs.first.id;

                    // Determine the field name based on the category type
                    String fieldName = type == 'expenses' ? 'expense_category' : 'budget_category';

                    // Retrieve the current categories array
                    List<String> currentCategories = (userSnapshot.docs.first.data() as Map<String, dynamic>?)?[fieldName]?.cast<String>() ?? [];

                    // Update the category name in the array
                    int index = currentCategories.indexOf(oldCategory);
                    if (index != -1) {
                      currentCategories[index] = _renameController.text;

                      // Update the categories array in Firestore
                      await FirebaseFirestore.instance.collection('dollar_sense').doc(userId).update({
                        fieldName: currentCategories,
                      });

                      // Update the local state
                      setState(() {
                        if (type == 'expenses') {
                          _expenseCategories = currentCategories;
                        } else {
                          _budgetCategories = currentCategories;
                        }
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Category successfully renamed')),
                      );

                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: Category not found')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: User not found')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error renaming category: $e')),
                  );
                }
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category Settings'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCategoryPage(username: widget.username),
                  ),
                );
              },
              child: Text('Add Category'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                children: [
                  Text('Expense Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildCategoryList(_expenseCategories, 'expenses'),
                  SizedBox(height: 16.0),
                  Text('Budget Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildCategoryList(_budgetCategories, 'budget'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }

  Widget _buildCategoryList(List<String> categories, String type) {
    return ListView.builder(
      shrinkWrap: true,  // To allow nested ListView within a Column
      physics: NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(categories[index]),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _renameCategory(categories[index], type);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deleteCategory(categories[index], type);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

