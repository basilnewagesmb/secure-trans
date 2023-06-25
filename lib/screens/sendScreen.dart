import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import '../widgets/vertical_spacer.dart';

class EnterRecipientDetailsScreen extends StatefulWidget {
  String userSeed = "";
  bool isLoading = false; // Flag to track loading state

  @override
  State<EnterRecipientDetailsScreen> createState() =>
      _EnterRecipientDetailsScreenState();
}

class _EnterRecipientDetailsScreenState
    extends State<EnterRecipientDetailsScreen> {
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController bankDetailsController = TextEditingController();
  late DatabaseReference _userRef;
  Object userData = {};
  @override
  void initState() {
    super.initState();
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    _userRef = FirebaseDatabase.instance.ref().child('users');
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        getUserById(user.uid);
      } else {
        print("error$user");
      }
    } catch (e) {
      print("error$e");
    }
  }

  void getUserById(String userId) {
    _userRef.orderByChild('user_id').equalTo(userId).once().then((event) {
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          userData = snapshot.value!;
          final Map<dynamic, dynamic> userMap =
              userData as Map<dynamic, dynamic>;
          widget.userSeed = userMap.values.first['user_seed'];
        });
      }
    }).catchError((error) {
      print('Error retrieving user: $error');
    });
  }

  void updateSeedByUserId(String userId, String newSeed, String type) {
    _userRef.orderByChild('user_id').equalTo(userId).once().then((event) {
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        final Map<dynamic, dynamic> userMap =
            snapshot.value as Map<dynamic, dynamic>;
        final userKey = userMap.keys.first;
        final userUpdate = {type: newSeed};
        _userRef.child(userKey).update(userUpdate).then((resp) {
          return resp;
        }).catchError((error) {
          print('Error updating user seed: $error');
        });
      }
    }).catchError((error) {
      print('Error retrieving user: $error');
    });
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Generate PIN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  try {
                    String user_pin = generatePin(widget.userSeed);
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      _userRef
                          .orderByChild('user_id')
                          .equalTo(user.uid)
                          .once()
                          .then((event) {
                        final DataSnapshot snapshot = event.snapshot;
                        if (snapshot.value != null) {
                          final Map<dynamic, dynamic> userMap =
                              snapshot.value as Map<dynamic, dynamic>;
                          ;
                          final userKey = userMap.keys.first;
                          final userUpdate = {"user_seed": user_pin};
                          _userRef
                              .child(userKey)
                              .update(userUpdate)
                              .then((resp) {
                            _userRef
                                .orderByChild('user_id')
                                .equalTo(user.uid)
                                .once()
                                .then((event) {
                              final DataSnapshot snapshot = event.snapshot;
                              if (snapshot.value != null) {
                                userData = snapshot.value!;
                                final Map<dynamic, dynamic> userMap =
                                    userData as Map<dynamic, dynamic>;
                                String user_seed =
                                    userMap.values.first['user_seed'];
                                String bank_seed =
                                    userMap.values.first['bank_seed'];
                                if (user_seed == bank_seed) {
                                  _showConfirmationDialog(context);
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Error'),
                                        content: Text('Seed mismatch'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('OK'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            }).catchError((error) {
                              print('Error retrieving user: $error');
                            });
                          }).catchError((error) {
                            print('Error updating user seed: $error');
                          });
                        }
                      }).catchError((error) {
                        print('Error retrieving user: $error');
                      });
                    }
                  } catch (e) {
                    print("pin----error$e");
                  }
                },
                child: const Text('Generate PIN'),
              ),
            ],
          ),
        );
      },
    );
  }

  void sendFun() {
    setState(() {
      widget.isLoading = true; // Start loading state
    });
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userRef.orderByChild('user_id').equalTo(user.uid).once().then((event) {
          final DataSnapshot snapshot = event.snapshot;
          if (snapshot.value != null) {
            userData = snapshot.value!;
            final Map<dynamic, dynamic> userMap =
                userData as Map<dynamic, dynamic>;
            String userSeed = userMap.values.first['user_seed'];
            String bank_pin = generatePin(userSeed);
            updateSeedByUserId(user.uid, bank_pin, 'bank_seed');
            setState(() {
              widget.isLoading = false; // Start loading state
            });
            _showBottomSheet(context);
          }
        }).catchError((error) {
          print('Error retrieving user: $error');
        });
      } else {
        print("error$user");
      }
    } catch (e) {
      print("error$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Recipient Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recipient Account Number:'),
            TextField(
              controller: accountNumberController,
              decoration: const InputDecoration(
                hintText: 'Enter account number',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Amount to Send:'),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                hintText: 'Enter amount',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('IFSC code:'),
            TextField(
              controller: bankDetailsController,
              decoration: const InputDecoration(
                hintText: 'Enter IFSC details',
              ),
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: sendFun,
              child: Text(widget.isLoading ? "Loading..." : 'Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.w),
        ),
        child: SizedBox(
          height: 430.h,
          width: 327.w,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
            ),
            child: Column(
              children: [
                const VerticalSpacer(height: 40),
                SizedBox(
                  width: 240.w,
                  height: 180.h,
                  child: FittedBox(
                    child:
                        SvgPicture.asset('assets/images/sent_illustration.svg'),
                    fit: BoxFit.fill,
                  ),
                ),
                const VerticalSpacer(height: 35),
                Text(
                  "The amount has been sent successfully!",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 20.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                const VerticalSpacer(height: 40),
                ElevatedButton(
                  child: Text("Ok, Thanks"),
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return HomeScreen();
                    }));
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String generatePin(String seed) {
  // Apply customized cellular automaton rules here
  // Modify this logic to match your desired rules
  // This example generates a PIN of 6 digits containing digits from 0 to 9

  List<int> automatonRule = [
    7,
    2,
    4,
    8,
    1,
    5,
    9,
    3,
    6,
    0
  ]; // Cellular automaton rule (mapping of 0-9 digits)

  String pin = seed;
  for (int i = 0; i < 9; i++) {
    int left = int.parse(pin[(i + pin.length - 1) % pin.length]);
    int center = int.parse(pin[i]);
    int right = int.parse(pin[(i + 1) % pin.length]);

    int ruleIndex = (left << 2) +
        (center << 1) +
        right; // Convert neighboring digits to a rule index
    ruleIndex %=
        automatonRule.length; // Ensure the rule index is within the valid range

    int newDigit =
        automatonRule[ruleIndex]; // Apply the cellular automaton rule

    pin += newDigit.toString();
  }
  return pin.substring(pin.length - 9); // Extract the last 6 digits as the PIN
}
