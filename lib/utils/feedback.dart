import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class AppFeedback {
  static String message(Object error) {
    if (error is TimeoutException) {
      return 'The request timed out. Check your connection and try again.';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'not-found':
          return 'This service or record is currently unavailable. Please retry later or contact support.';
        case 'internal':
        case 'unknown':
          return 'We could not complete this request. Please try again shortly.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Connection unavailable. Check your internet and retry.';
        case 'permission-denied':
          return 'Your account cannot perform this action. Sign in again or contact the administrator.';
        case 'requires-recent-login':
          return 'Please sign in again before this security change.';
        default:
          final message = error.message;
          if (message == null || message.contains('#0') || message.contains('package:') || message.length > 300) {
            return 'The request failed. Please try again.';
          }
          return message;
      }
    }
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }

  static void error(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message(error)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
