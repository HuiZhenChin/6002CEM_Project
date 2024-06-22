import 'package:dollar_sense/add_category.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

//page to display list of expenses and budget categories
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _bottomNavIndex = 0; //navigation bar position index

  @override
  void initState() {
    super.initState();
    _fetchCategories(); //fetch the list of categories to display
  }

  Future<void> _fetchCategories() async {
    try {
      //get the user ID from the username
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: widget.username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        Map<String, dynamic>? userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>?;

        //fetch expense and budget categories
        setState(() {
          _expenseCategories = (userData?['expense_category'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];
          _budgetCategories = (userData?['budget_category'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];
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
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: widget.username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;

        // determine the field name based on the category type
        String fieldName = type == 'expenses' ? 'expense_category' : 'budget_category';

        // retrieve the current categories array
        List<String> currentCategories = (userSnapshot.docs.first.data() as Map<String, dynamic>?)?[fieldName]?.cast<String>() ?? [];

        QuerySnapshot snapshotToDelete;
        String dialogContent;

        if (type == 'expenses') {
          // check if there are any expenses under the deleted category
          snapshotToDelete = await FirebaseFirestore.instance
              .collection('dollar_sense')
              .doc(userId)
              .collection('expenses')
              .where('category', isEqualTo: category)
              .get();
          dialogContent = 'There are expenses under this category. Are you sure you want to delete it? It will also remove all the expenses under the category.';
        } else {
          // check if there are any budgets under the deleted category
          snapshotToDelete = await FirebaseFirestore.instance
              .collection('dollar_sense')
              .doc(userId)
              .collection('budget')
              .where('budget_category', isEqualTo: category)
              .get();
          dialogContent = 'There are budgets under this category. Are you sure you want to delete it? It will also remove all the budgets under the category.';
        }

        if (snapshotToDelete.docs.isNotEmpty) {
          // show a dialog informing the user about existing entries under the category
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: Text('Warning'),
                content: Text(dialogContent),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // delete the entries under the category
                      for (QueryDocumentSnapshot doc in snapshotToDelete.docs) {
                        await doc.reference.delete();
                      }
                      // proceed with deleting the category
                      await _deleteCategoryAndExpenses(userId, category, type, currentCategories);
                      Navigator.of(context).pop();
                    },
                    child: Text('Delete'),
                  ),
                ],
              );
            },
          );
        } else {
          // if no entries under the category, proceed with deleting the category
          await _deleteCategoryAndExpenses(userId, category, type, currentCategories);
        }
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

// function to delete both category and its stored entries
  Future<void> _deleteCategoryAndExpenses(String userId, String category, String type, List<String> currentCategories) async {
    // remove the category from the array
    currentCategories.remove(category);

    // update the categories array
    await FirebaseFirestore.instance.collection('dollar_sense')
        .doc(userId)
        .update({
      type == 'expenses' ? 'expense_category' : 'budget_category': currentCategories,
    });

    // update the local state
    setState(() {
      if (type == 'expenses') {
        _expenseCategories = currentCategories;
      } else {
        _budgetCategories = currentCategories;
      }
    });

    // show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category successfully deleted')),
    );
  }

  //function to rename a created category
  Future<void> _renameCategory(String oldCategory, String type) async {
    TextEditingController _renameController = TextEditingController();
    _renameController.text = oldCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
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
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue, // Button text color
                  ),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      //check if the new category name already exists in the appropriate collection
                      bool categoryExists = await checkCategoryExists(
                        widget.username,
                        _renameController.text,
                        type,
                      );

                      if (categoryExists) {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Category Exists'),
                              content: Text('The category already exists.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            );
                          },
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoriesPage(username: widget.username),
                          ),
                        );
                      } else {
                        //proceed with renaming the category
                        QuerySnapshot userSnapshot = await FirebaseFirestore
                            .instance
                            .collection('dollar_sense')
                            .where('username', isEqualTo: widget.username)
                            .get();

                        if (userSnapshot.docs.isNotEmpty) {
                          String userId = userSnapshot.docs.first.id;

                          //determine the field name based on the category type
                          String fieldName = type == 'expenses'
                              ? 'expense_category'
                              : 'budget_category';

                          //retrieve the current categories array
                          List<String> currentCategories =
                              (userSnapshot.docs.first.data()
                                          as Map<String, dynamic>?)?[fieldName]
                                      ?.cast<String>() ??
                                  [];

                          //update the category name in the array
                          int index = currentCategories.indexOf(oldCategory);
                          if (index != -1) {
                            currentCategories[index] = _renameController.text;

                            //update the categories array in Firestore
                            await FirebaseFirestore.instance
                                .collection('dollar_sense')
                                .doc(userId)
                                .update({
                              fieldName: currentCategories,
                            });

                            //update the local state
                            setState(() {
                              if (type == 'expenses') {
                                _expenseCategories = currentCategories;
                              } else {
                                _budgetCategories = currentCategories;
                              }
                            });

                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CategoriesPage(username: widget.username),
                              ),
                            );

                            //message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Category successfully renamed')),
                            );
                          } else {
                            Navigator.of(context)
                                .pop(); // Close the rename dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error: Category not found')),
                            );
                          }
                        } else {
                          Navigator.of(context)
                              .pop(); // Close the rename dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: User not found')),
                          );
                        }
                      }
                    } catch (e) {
                      Navigator.of(context).pop(); // Close the rename dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error renaming category: $e')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red, // Button text color
                  ),
                  child: Text('Rename'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //function to check if the category exists/ already created
  Future<bool> checkCategoryExists(
      String username, String category, String type) async {
    try {
      QuerySnapshot userSnapshot = await _firestore
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        String fieldName =
            type == 'expenses' ? 'expense_category' : 'budget_category';

        DocumentSnapshot userDoc =
            await _firestore.collection('dollar_sense').doc(userId).get();
        List<String> categories =
            (userDoc[fieldName] as List<dynamic>).cast<String>();

        return categories.contains(category);
      } else {
        return false; // User not found
      }
    } catch (e) {
      print('Error checking category existence: $e');
      return true; // Assume category exists to prevent adding duplicate budgets
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Category Settings'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFF547FA3),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddCategoryPage(username: widget.username),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                    SizedBox(height: 16.0),
                    Expanded(
                      child: ListView(
                        children: [
                          Text('Expense Categories',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          _buildCategoryList(_expenseCategories, 'expenses'),
                          SizedBox(height: 16.0),
                          Text('Budget Categories',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          _buildCategoryList(_budgetCategories, 'budget'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      //navigation bar
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped:
            NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }

  //list view to display categories
  Widget _buildCategoryList(List<String> categories, String type) {
    //display message if no expense or budget category found
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          type == 'expenses'
              ? 'No expense categories found'
              : 'No budget categories found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true, // To allow nested ListView within a Column
      physics: NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(categories[index]),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              //rename category
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _renameCategory(categories[index], type);
                },
              ),
              IconButton(
                //delete category
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
