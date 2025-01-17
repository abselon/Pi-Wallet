import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:piwallet/Components/Homepage/StatCard.dart';

class HeaderSection extends StatefulWidget {
  final Widget middleSection;

  const HeaderSection({Key? key, required this.middleSection})
      : super(key: key);

  @override
  _HeaderSectionState createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection>
    with WidgetsBindingObserver {
  String name = '';
  double incomeAmount = 0.0;
  double expensesAmount = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // Add observer to detect app lifecycle changes
    _fetchUserData(); // Fetch data on first load
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refetch data when the app is resumed
      _fetchUserData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up observer
    super.dispose();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          setState(() {
            name = userDoc['name'] ?? '';
            // Check if income exists and is a list before processing
            if (userDoc['income'] != null && userDoc['income'] is List) {
              incomeAmount = _calculateIncome(userDoc['income']);
            } else {
              incomeAmount = 0.0;
              print("No income array found in user document.");
            }

            // Handle expenses (already correctly parsed as numbers)
            expensesAmount = _calculateExpenses(userDoc['expenses']);
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  // Calculate total income (amount can be string or number)
  double _calculateIncome(List<dynamic> income) {
    double total = 0.0;
    for (var item in income) {
      if (item['amount'] != null) {
        double amount = 0.0;
        // If the amount is a string, try to parse it
        if (item['amount'] is String) {
          amount = double.tryParse(item['amount']) ?? 0.0;
        } else if (item['amount'] is num) {
          amount = item['amount'].toDouble();
        }
        total += amount;
      }
    }
    return total;
  }

  // Calculate total expenses (amount is a number)
  double _calculateExpenses(List<dynamic> expenses) {
    double total = 0.0;
    for (var item in expenses) {
      if (item['amount'] != null) {
        double? amount = double.tryParse(item['amount'].toString());
        total += amount ?? 0.0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 176, 226, 184),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Content
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 35),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      name.isEmpty ? "Loading..." : name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Monthly Cash Flow",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatCard(
                      title: "Income",
                      amount: "Rs ${incomeAmount.toStringAsFixed(2)}",
                      color: const Color.fromARGB(255, 48, 122, 49),
                    ),
                    SizedBox(height: 10.0),
                    StatCard(
                      title: "Expenses",
                      amount: "Rs ${expensesAmount.toStringAsFixed(2)}",
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Middle Section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: widget.middleSection,
            ),
          ),
        ],
      ),
    );
  }
}
