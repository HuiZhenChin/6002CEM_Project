import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';
import 'dart:math';

class GraphPage extends StatefulWidget {
  final String username;

  GraphPage({required this.username});

  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 2;
  List<Map<String, dynamic>> currentMonthData = [];
  List<String> availableMonths = [];
  String selectedMonth = '';

  @override
  void initState() {
    super.initState();
    fetchAvailableMonths(widget.username);
  }

  //fetch the months available in the current_month_data collection
  Future<void> fetchAvailableMonths(String username) async {
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot monthsSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('current_month_data')
          .get();

      List<String> months = monthsSnapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        availableMonths = months;
        if (months.isNotEmpty) {
          selectedMonth = months.first;
          fetchCurrentMonthData(widget.username, selectedMonth);
        }
      });
    }
  }

  //fetch the current month data
  Future<void> fetchCurrentMonthData(String username, String month) async {
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      DocumentSnapshot monthDataSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('current_month_data')
          .doc(month)
          .get();

      if (monthDataSnapshot.exists) {
        setState(() {
          currentMonthData = [monthDataSnapshot.data() as Map<String, dynamic>];
        });
      }
    }
  }

  //find highest value
  double findHighestValue(List<Map<String, dynamic>> data) {
    double highest = double.negativeInfinity;
    data.forEach((entry) {
      double maxEntryValue = [
        entry['total_budget']?.toDouble() ?? 0.0,
        entry['total_expenses']?.toDouble() ?? 0.0,
        entry['total_income']?.toDouble() ?? 0.0,
        entry['total_invest']?.toDouble() ?? 0.0,
      ].reduce((a, b) => a > b ? a : b);
      if (maxEntryValue > highest) {
        highest = maxEntryValue;
      }
    });
    return highest;
  }

  //find lowest value
  double findLowestValue(List<Map<String, dynamic>> data) {
    double lowest = double.infinity;
    data.forEach((entry) {
      double minEntryValue = [
        entry['total_budget']?.toDouble() ?? 0.0,
        entry['total_expenses']?.toDouble() ?? 0.0,
        entry['total_income']?.toDouble() ?? 0.0,
        entry['total_invest']?.toDouble() ?? 0.0,
      ].reduce((a, b) => a < b ? a : b);
      if (minEntryValue < lowest) {
        lowest = minEntryValue;
      }
    });
    return lowest;
  }

  //calculate bar chart y-axis range interval
  double calculateInterval(double highest, double lowest) {
    double range = highest - lowest;
    if (range == 0) {
      return 1.0; //return a default interval if all values are the same
    }

    double roughInterval = range / 4;
    double magnitude = pow(10, (log(roughInterval) / log(10)).floor().toDouble()).toDouble();
    double normalizedInterval = roughInterval / magnitude;

    if (normalizedInterval < 1.5) {
      return magnitude * 1;
    } else if (normalizedInterval < 3) {
      return magnitude * 2;
    } else if (normalizedInterval < 7) {
      return magnitude * 5;
    } else {
      return magnitude * 10;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Report Page'),
      ),
      body: currentMonthData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Container(
        color: Color(0xFFEEF4F8),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
              value: selectedMonth,
              onChanged: (newValue) {
                setState(() {
                  selectedMonth = newValue!;
                  fetchCurrentMonthData(widget.username, selectedMonth);
                });
              },
              items: availableMonths.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height:16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: buildDataTable(),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: buildPieChart(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Bottom row with BarChart
            Expanded(
              child: buildBarChartWithLegend(),
            ),
            SizedBox(height: 16),
            // No data recorded message
            if (currentMonthData.every((data) =>
            (data['total_budget'] ?? 0.0) == 0.0 &&
                (data['total_expenses'] ?? 0.0) == 0.0 &&
                (data['total_income'] ?? 0.0) == 0.0 &&
                (data['total_invest'] ?? 0.0) == 0.0))
              Center(
                child: Text(
                  'No data recorded',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
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


  //graph in bar chart
  Widget buildBarChartWithLegend() {
    if (currentMonthData.isEmpty) {
      return Center(
        child: Text('No data available'),
      );
    }

    double highestValue = findHighestValue(currentMonthData);
    double lowestValue = findLowestValue(currentMonthData);
    double interval = calculateInterval(highestValue, lowestValue);

    return Column(
      children: [
        //bar chart
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: BarChart(
              BarChartData(
                barGroups: currentMonthData.asMap().entries.map((entry) {
                  int index = entry.key;
                  var data = entry.value;

                  // create BarChartGroupData for each category
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 16,
                    barRods: [
                      BarChartRodData(
                        y: data['total_budget']?.toDouble() ?? 0.0,
                        colors: [Color(0xFFC8F5EC)],
                        width: 32,
                        borderRadius: BorderRadius.zero,
                        rodStackItems: [
                          BarChartRodStackItem(
                            0,
                            data['total_budget']?.toDouble() ?? 0.0,
                            Color(0xFFC8F5EC),
                          ),
                        ],
                      ),
                      if (data['total_expenses']?.toDouble() != 0.0)
                        BarChartRodData(
                          y: data['total_expenses']?.toDouble() ?? 0.0,
                          colors: [Color(0xFF98EDE1)],
                          width: 32,
                          borderRadius: BorderRadius.zero,
                          rodStackItems: [
                            BarChartRodStackItem(
                              0,
                              data['total_expenses']?.toDouble() ?? 0.0,
                              Color(0xFF98EDE1),
                            ),
                          ],
                        ),
                      if (data['total_income']?.toDouble() != 0.0)
                        BarChartRodData(
                          y: data['total_income']?.toDouble() ?? 0.0,
                          colors: [Color(0xFF63CBC6)],
                          width: 32,
                          borderRadius: BorderRadius.zero,
                          rodStackItems: [
                            BarChartRodStackItem(
                              0,
                              data['total_income']?.toDouble() ?? 0.0,
                              Color(0xFF63CBC6),
                            ),
                          ],
                        ),
                      if (data['total_invest']?.toDouble() != 0.0)
                        BarChartRodData(
                          y: data['total_invest']?.toDouble() ?? 0.0,
                          colors: [Color(0xFF3B979B)],
                          width: 32,
                          borderRadius: BorderRadius.zero,
                          rodStackItems: [
                            BarChartRodStackItem(
                              0,
                              data['total_invest']?.toDouble() ?? 0.0,
                              Color(0xFF3B979B),
                            ),
                          ],
                        ),
                      // add a default BarChartRodData with height 0 if all values are 0
                      if (data['total_budget']?.toDouble() == 0.0 &&
                          data['total_expenses']?.toDouble() == 0.0 &&
                          data['total_income']?.toDouble() == 0.0 &&
                          data['total_invest']?.toDouble() == 0.0)
                        BarChartRodData(
                          y: 0.0,
                          colors: [Colors.transparent],
                          width: 32,
                          borderRadius: BorderRadius.zero,
                          rodStackItems: [
                            BarChartRodStackItem(
                              0,
                              0.0,
                              Colors.transparent,
                            ),
                          ],
                        ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitles: (value) {
                      return '${(value ~/ 1000).toInt()}k';
                    },
                    margin: 10,
                    interval: interval,
                  ),
                  bottomTitles: SideTitles(
                    showTitles: true,
                    getTitles: (double value) {
                      if (value.toInt() < currentMonthData.length) {
                        return currentMonthData[value.toInt()]['month'] ?? '';
                      } else {
                        return '';
                      }
                    },
                    margin: 10,
                  ),
                ),
                axisTitleData: FlAxisTitleData(
                  leftTitle: AxisTitle(
                    showTitle: true,
                    titleText: 'Amount',
                    textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    margin: 5,
                  ),
                  bottomTitle: AxisTitle(
                    showTitle: true,
                    titleText: 'Month',
                    textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    margin: 5,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LegendItem(color: Color(0xFFC8F5EC), text: 'Budget'),
              SizedBox(width: 16),
              LegendItem(color: Color(0xFF98EDE1), text: 'Expenses'),
              SizedBox(width: 16),
              LegendItem(color: Color(0xFF63CBC6), text: 'Income'),
              SizedBox(width: 16),
              LegendItem(color: Color(0xFF3B979B), text: 'Invest'),
            ],
          ),
        ),
      ],
    );
  }


  //graph in pie chart
  Widget buildPieChart() {
    double totalBudget = currentMonthData.fold(
        0, (sum, item) => sum + (item['total_budget']?.toDouble() ?? 0.0));
    double totalExpenses = currentMonthData.fold(
        0, (sum, item) => sum + (item['total_expenses']?.toDouble() ?? 0.0));
    double totalIncome = currentMonthData.fold(
        0, (sum, item) => sum + (item['total_income']?.toDouble() ?? 0.0));
    double totalInvest = currentMonthData.fold(
        0, (sum, item) => sum + (item['total_invest']?.toDouble() ?? 0.0));

    List<PieChartSectionData> pieSections = [];
    List<Widget> zeroValueMessages = [];

    if (totalBudget != 0.0) {
      pieSections.add(PieChartSectionData(
        value: totalBudget,
        color: Color(0xFF9DC3E2),
        title: 'Budget',
        radius: 120,
        titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black),
      ));
    } else {
      zeroValueMessages.add(Text('Total Budget = 0.00'));
    }

    if (totalExpenses != 0.0) {
      pieSections.add(PieChartSectionData(
        value: totalExpenses,
        color: Color(0xFF9DD2DB),
        title: 'Expenses',
        radius: 120,
        titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black),
      ));
    } else {
      zeroValueMessages.add(Text('Total Expenses = 0.00'));
    }

    if (totalIncome != 0.0) {
      pieSections.add(PieChartSectionData(
        value: totalIncome,
        color: Color(0xFFFADCE4),
        title: 'Income',
        radius: 120,
        titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black),
      ));
    } else {
      zeroValueMessages.add(Text('Total Income = 0.00'));
    }

    if (totalInvest != 0.0) {
      pieSections.add(PieChartSectionData(
        value: totalInvest,
        color: Color(0xFFFFB5CC),
        title: 'Invest',
        radius: 120,
        titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black),
      ));
    } else {
      zeroValueMessages.add(Text('Total Invest = 0.00'));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: pieSections,
              ),
            ),
          ),
          Column(
            children: zeroValueMessages,
          ),
        ],
      ),
    );
  }

  //graph in table view
  Widget buildDataTable() {
    //extracts the data for table view
    var rowData = currentMonthData.isNotEmpty ? currentMonthData[0] : {};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.only(left: 180.0),
        child: DataTable(
          headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.blue[50]!,
          ),
          dataRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.grey[100]!,
          ),
          columns: <DataColumn>[
            DataColumn(
              label: Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Amount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: <DataRow>[
            DataRow(
              cells: <DataCell>[
                DataCell(Text('Total Budget')),
                DataCell(Text((rowData['total_budget'] ?? 0.0).toString())),
              ],
              color: MaterialStateColor.resolveWith(
                    (states) => Colors.blue[50]!,
              ),
            ),
            DataRow(
              cells: <DataCell>[
                DataCell(Text('Total Expenses')),
                DataCell(Text((rowData['total_expenses'] ?? 0.0).toString())),
              ],
              color: MaterialStateColor.resolveWith(
                    (states) => Colors.blue[100]!,
              ),
            ),
            DataRow(
              cells: <DataCell>[
                DataCell(Text('Total Income')),
                DataCell(Text((rowData['total_income'] ?? 0.0).toString())),
              ],
              color: MaterialStateColor.resolveWith(
                    (states) => Colors.blue[200]!,
              ),
            ),
            DataRow(
              cells: <DataCell>[
                DataCell(Text('Total Invest')),
                DataCell(Text((rowData['total_invest'] ?? 0.0).toString())),
              ],
              color: MaterialStateColor.resolveWith(
                    (states) => Colors.blue[300]!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({
    Key? key,
    required this.color,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
