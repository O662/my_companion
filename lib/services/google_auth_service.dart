import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn();

  /// Signs in (or signs up) with Google and ensures a Firestore user doc exists.
  /// Returns the [UserCredential] on success, or null if the user cancelled.
  static Future<UserCredential?> signInWithGoogle() async {
    late final UserCredential userCredential;

    if (kIsWeb) {
      // Web: use Firebase's built-in popup flow
      final googleProvider = GoogleAuthProvider();
      userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      // Mobile: use google_sign_in native flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
    }

    final user = userCredential.user;
    if (user != null) {
      // Create Firestore doc if it doesn't exist yet (first-time Google sign-up)
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final nameParts = (user.displayName ?? '').split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        await docRef.set({
          'first_name': firstName,
          'last_name': lastName,
          'email': user.email ?? '',
        });
      }
    }

    return userCredential;
  }
}
