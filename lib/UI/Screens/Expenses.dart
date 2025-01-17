import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piwallet/Components/Expensepage/Expenseform.dart';
import 'package:piwallet/Components/Expensepage/Expensedetails.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Expenses extends StatefulWidget {
  @override
  _ExpensesState createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  Map<String, List<Map<String, dynamic>>> categorizedExpenses = {};
  bool isLoading = true;
  String errorMessage = '';
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double budgetUsedPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchExpensesAndIncome();
  }

  Future<void> fetchExpensesAndIncome() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not logged in!");
        return;
      }
      String currentUserUid = user.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();

      var data = userDoc.data() as Map<String, dynamic>?;

      if (data != null) {
        var expensesList = data['expenses'] as List<dynamic>?;
        var incomeList = data['income'] as List<dynamic>?;

        if (expensesList != null && expensesList.isNotEmpty) {
          Map<String, List<Map<String, dynamic>>> tempCategorizedExpenses = {};

          for (var expense in expensesList) {
            if (expense is Map<String, dynamic> &&
                expense.containsKey('type') &&
                expense.containsKey('amount')) {
              String category = expense['type'];
              tempCategorizedExpenses.putIfAbsent(category, () => []);
              tempCategorizedExpenses[category]?.add({
                'name': expense['name'] ?? 'Unnamed',
                'amount': expense['amount'],
                'description': expense['description'] ?? 'No description',
                'date': expense['date'] ?? '',
              });
              totalExpenses +=
                  (double.tryParse(expense['amount'].toString()) ?? 0.0);
            } else {
              print('Invalid expense data: $expense');
            }
          }

          setState(() {
            categorizedExpenses = tempCategorizedExpenses;
          });
        }

        if (incomeList != null && incomeList.isNotEmpty) {
          for (var income in incomeList) {
            if (income is Map<String, dynamic> &&
                income.containsKey('amount')) {
              totalIncome +=
                  (double.tryParse(income['amount'].toString()) ?? 0.0);
            } else {
              print('Invalid income data: $income');
            }
          }
        }

        // Calculate budget used percentage
        if (totalIncome > 0) {
          budgetUsedPercentage = (totalExpenses / totalIncome) * 100;
        }

        // Ensure percentage doesn't exceed 100%
        if (budgetUsedPercentage > 100) {
          budgetUsedPercentage = 100;
        }

        setState(() {
          isLoading = false;
        });
      } else {
        print('User document missing expenses or income field.');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching expenses and income: $e');
      setState(() {
        errorMessage = 'Failed to load expenses and income: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 171, 249, 184),
      body: Column(
        children: [
          // Upper Section with Gradient
          Container(
            width: double.infinity,
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 182, 229, 190),
                  const Color.fromARGB(255, 182, 229, 190),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        "${budgetUsedPercentage.toStringAsFixed(2)}% used",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 6),
                isLoading
                    ? const SizedBox.shrink()
                    : const Text(
                        "from your Total Budget",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
              ],
            ),
          ),

          // Middle Section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 209, 208, 208),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.only(left: 18),
                    child: Text(
                      "Expense Categories",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: const Color.fromARGB(255, 182, 229, 190),
                        ),
                      ),
                    )
                  else if (errorMessage.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: categorizedExpenses.isEmpty
                            ? 1
                            : categorizedExpenses.length,
                        itemBuilder: (context, index) {
                          if (categorizedExpenses.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "Add expenses to display",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 185, 185, 185),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            String category =
                                categorizedExpenses.keys.elementAt(index);
                            List<Map<String, dynamic>> categoryExpenses =
                                categorizedExpenses[category]!;
                            double totalAmount = categoryExpenses.fold(
                              0.0,
                              (sum, expense) =>
                                  sum +
                                  (double.tryParse(
                                          expense['amount'].toString()) ??
                                      0.0),
                            );
                            return _buildExpenseCard(
                              category,
                              'Rs ${totalAmount.toStringAsFixed(2)}',
                              categoryExpenses,
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            print("User is not logged in!");
            Navigator.pushReplacementNamed(context, '/login');
            return;
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: ExpenseForm(
                        onExpenseAdded: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await fetchExpensesAndIncome();
                            Navigator.of(context).pop();
                          } else {
                            print(
                                "User is not logged in after expense submission!");
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      ),
                    ),
                    Positioned(
                      right: -5,
                      top: -3,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red, size: 30),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        backgroundColor: const Color.fromARGB(255, 182, 229, 190),
        child: const Icon(Icons.add, size: 32, color: Colors.black),
      ),
    );
  }

  Widget _buildExpenseCard(String expenseType, String amount,
      List<Map<String, dynamic>> categoryExpenses) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseDetailPage(
              category: expenseType,
              expenses: categoryExpenses,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        color: Colors.grey[100],
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color.fromARGB(255, 182, 229, 190),
            child: const Icon(Icons.monetization_on, color: Colors.black),
          ),
          title: Text(
            expenseType,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          trailing: Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 186, 186, 186),
            ),
          ),
        ),
      ),
    );
  }
}
