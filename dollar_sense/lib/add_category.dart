import 'package:dollar_sense/category.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: 'Category Name'),
            ),
            SizedBox(height: 16.0),
            DropdownButton<String>(
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
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _addCategory(context);
              },
              child: Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}