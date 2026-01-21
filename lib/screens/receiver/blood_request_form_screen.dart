import 'package:flutter/material.dart';

class BloodRequestFormScreen extends StatefulWidget {
  const BloodRequestFormScreen({super.key});

  @override
  State<BloodRequestFormScreen> createState() =>
      _BloodRequestFormScreenState();
}

class _BloodRequestFormScreenState
    extends State<BloodRequestFormScreen> {
  String selectedGroup = 'B+';

  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-',
    'O+', 'O-', 'AB+', 'AB-',
    'AB+', 'B+', 'AB', 'AB',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Request Blood'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          /// 🔴 Bottom Curve
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 90,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          /// Content
          LayoutBuilder(
            builder: (context, constraints) {
              final double boxWidth =
                  (constraints.maxWidth - 48) / 4;
              final double boxHeight = 42;

              return SingleChildScrollView(
                padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    const Text(
                      'Post Size',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// 🔳 Blood Group Boxes (Image Style)
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: bloodGroups.map((group) {
                        final bool isSelected =
                            selectedGroup == group;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedGroup = group;
                            });
                          },
                          child: Container(
                            width: boxWidth,
                            height: boxHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.red
                                  : Colors.white,
                              borderRadius:
                              BorderRadius.circular(6),
                              border:
                              Border.all(color: Colors.red),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 3,
                                )
                              ],
                            ),
                            child: Text(
                              group,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 35),

                    /// 🔘 Button (Image Style)
                    SizedBox(
                      width: 220,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Request Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
