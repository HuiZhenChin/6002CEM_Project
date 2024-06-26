import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'invest_model.dart';
import 'package:flutter/services.dart';
import 'edit_invest.dart';
import 'transaction_history_view_model.dart';
import 'invest_view_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

//page to view list of investments
class ViewInvestPage extends StatefulWidget {
  final String username;

  const ViewInvestPage({required this.username});

  @override
  _ViewInvestPageState createState() => _ViewInvestPageState();
}

class _ViewInvestPageState extends State<ViewInvestPage> {
  int currentIndex = 0;
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 0;  //navigation bar position index
  List<Invest> invests = [];
  final viewModel = InvestViewModel();
  final historyViewModel = TransactionHistoryViewModel();
  String _currentFilter = 'None';
  bool _isFiltered = false;  //for filtering purpose


  @override
  void initState() {
    super.initState();
    _fetchInvest();  //fetch the list of investments
  }

  Future<List<Invest>> _fetchInvest() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot investSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('invest')
          .orderBy('id')
          .get();

      return investSnapshot.docs
          .map((doc) => Invest.fromDocument(doc))
          .toList();
    } else {
      //return an empty list if no investments found
      return [];
    }
  }

  //update changes after editing
  void _updateInvest(Invest editedInvest) {
    setState(() {
      //find the index of the edited expense in the invest list
      int index = invests.indexWhere((invest) => invest.id == editedInvest.id);
      if (index != -1) {
        //replace the edited expense with the new one
        invests[index] = editedInvest;
      }
    });
  }

  //edit investments
  void _editInvest(Invest invest) async {
    String documentId = await _getDocumentId(invest);

    //navigate to the edit investments page and pass the document ID
    Invest editedInvest = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvest(
          onInvestUpdated: _updateInvest,
          invest: invest,
          username: widget.username,
          documentId: documentId,
        ),
      ),
    );

    //check if a investment was edited
    if (editedInvest != null) {
      //update the UI with the edited investments
      _updateInvest(editedInvest);
    }
  }

  //get document Id of the edited investment
  Future<String> _getDocumentId(Invest invest) async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('invest')
          .where('id', isEqualTo: invest.id)
          .limit(1)
          .get();

      if (expenseSnapshot.docs.isNotEmpty) {
        return expenseSnapshot.docs.first.id;
      }
    }
    //return an empty string or handle the case where the document ID is not found
    return '';
  }

  //delete investments
  Future<void> _deleteInvest(Invest invest) async {
    bool? confirmDelete = await _showConfirmationDialog(context, 'delete', invest);
    if (confirmDelete == true) {
      String username = widget.username;
      String documentId = await _getDocumentId(invest);
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('invest')
            .doc(documentId) //specify the document ID of the investment to delete
            .delete();

        setState(() {
          //remove the deleted investment from the list
          invests.removeWhere((element) => element.id == invest.id);
        });

        //add the history record
        String specificText = "Delete Invest: ${invest.title}";
        await historyViewModel.addHistory(specificText, widget.username, context);
      }
    }
  }

  //show delete confirmation dialog
  Future<bool?> _showConfirmationDialog(BuildContext context, String action, Invest invest) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action this investment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  //filter investments
  List<Invest> _filterInvests(List<Invest> invests) {
    switch (_currentFilter) {
      case 'Title (A-Z)':
        invests.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Title (Z-A)':
        invests.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'Amount (High to Low)':
        invests.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Amount (Low to High)':
        invests.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'Date (Old to New)':
        invests.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Date (New to Old)':
        invests.sort((a, b) => b.date.compareTo(a.date));
        break;
      default:
        break;
    }
    return invests;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('View Invest'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () async {
              String? result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    backgroundColor: Colors.white,
                    title: Text('Filter Options'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Title');
                        },
                        child: Text('Title (A-Z)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Title (Z-A)');
                        },
                        child: Text('Title (Z-A)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Amount (High to Low)');
                        },
                        child: Text('Amount (High to Low)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Amount (Low to High)');
                        },
                        child: Text('Amount (Low to High)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Date (Old to New)');
                        },
                        child: Text('Date (Old to New)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Date (New to Old)');
                        },
                        child: Text('Date (New to Old)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'None');
                        },
                        child: Text('Remove Filter'),
                      ),
                    ],
                  );
                },
              );
              //show the filtered results
              if (result != null) {
                setState(() {
                  _currentFilter = result;
                  _isFiltered = _currentFilter != 'None';
                });
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
        ),
        child: FutureBuilder<List<Invest>>(
          future: _fetchInvest(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  //if no investments found
                  'No investments found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            } else {
              List<Invest> filteredInvests = _isFiltered
                  ? _filterInvests(snapshot.data!)
                  : snapshot.data!;
              return ListView.builder(
                itemCount: filteredInvests.length,
                itemBuilder: (context, index) {
                  final invest = filteredInvests[index];
                  final isOdd = index % 2 == 0; //check if the index is odd

                  return Container(
                    color: isOdd
                        ? Colors.grey[200]!.withOpacity(0.8)
                        : Colors.white!.withOpacity(
                            0.8), //set background color based on index
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(invest.title),
                          Text(
                            '${invest.date}',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Text('Amount: \ ${invest.amount}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editInvest(invest);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            //delete investments
                            onPressed: () async {
                              _deleteInvest(
                                  invest);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped:
            NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }
}
