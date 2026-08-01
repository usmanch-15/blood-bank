import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';



/// ✅ NEW — generic reader screen for a block of legal/plain text.

/// Used for both Terms of Service and Privacy Policy so we don't need

/// two near-identical screens.

class LegalDocumentScreen extends StatelessWidget {

  final String title;

  final String content;



  const LegalDocumentScreen({

    super.key,

    required this.title,

    required this.content,

  });



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.backgroundLight,

      appBar: AppBar(

        title: Text(title),

        backgroundColor: AppColors.primaryRed,

        foregroundColor: Colors.white,

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Container(

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.circular(14),

            boxShadow: [

              BoxShadow(

                color: Colors.black.withOpacity(0.05),

                blurRadius: 8,

                offset: const Offset(0, 2),

              ),

            ],

          ),

          child: SelectableText(

            content,

            style: const TextStyle(

              fontSize: 14,

              height: 1.6,

              color: AppColors.textPrimary,

            ),

          ),

        ),

      ),

    );

  }

}