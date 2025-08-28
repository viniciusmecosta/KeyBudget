import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/user_model.dart';

class AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        if (kDebugMode) {
          print("[AuthRepository] AuthStateChanged: User is null.");
        }
        return null;
      }
      if (kDebugMode) {
        print(
            "[AuthRepository] AuthStateChanged: Firebase user detected. Fetching profile for UID: ${firebaseUser.uid}");
      }
      return await getUserProfile(firebaseUser.uid);
    });
  }

  Future<User?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        if (kDebugMode) {
          print("[AuthRepository] getUserProfile: Profile found for UID: $uid");
        }
        return User.fromMap(doc.data()!);
      }
      if (kDebugMode) {
        print(
            "[AuthRepository] getUserProfile: Profile NOT found for UID: $uid");
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
            "[AuthRepository] getUserProfile: Error getting user profile: $e");
      }
      return null;
    }
  }

  Future<firebase.UserCredential> signInWithEmail(
      String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> ensureCategoriesExist(String userId) async {
    if (kDebugMode) {
      print(
          '[AuthRepository] ensureCategoriesExist: Checking for user: $userId');
    }
    try {
      final categoriesCollection =
          _firestore.collection('users').doc(userId).collection('categories');
      final existingCategories = await categoriesCollection.limit(1).get();

      if (existingCategories.docs.isNotEmpty) {
        if (kDebugMode) {
          print(
              '[AuthRepository] ensureCategoriesExist: Categories already exist.');
        }
        return;
      }

      if (kDebugMode) {
        print(
            '[AuthRepository] ensureCategoriesExist: Creating default categories...');
      }
      final List<ExpenseCategory> defaultCategories = [
        ExpenseCategory(
            name: 'Alimentação',
            iconCodePoint: Icons.restaurant.codePoint,
            colorValue: AppTheme.chartColors[0].value),
        ExpenseCategory(
            name: 'Lazer',
            iconCodePoint: Icons.shopping_bag.codePoint,
            colorValue: AppTheme.chartColors[1].value),
        ExpenseCategory(
            name: 'Roupa',
            iconCodePoint: Icons.checkroom.codePoint,
            colorValue: AppTheme.chartColors[2].value),
        ExpenseCategory(
            name: 'Farmácia',
            iconCodePoint: Icons.medication_rounded.codePoint,
            colorValue: AppTheme.chartColors[3].value),
        ExpenseCategory(
            name: 'Transporte',
            iconCodePoint: Icons.directions_bus.codePoint,
            colorValue: AppTheme.chartColors[4].value),
        ExpenseCategory(
            name: 'Outros',
            iconCodePoint: Icons.category_rounded.codePoint,
            colorValue: AppTheme.chartColors[5].value),
      ];

      final batch = _firestore.batch();
      for (final category in defaultCategories) {
        final docRef = categoriesCollection.doc();
        batch.set(docRef, category.toMap());
      }
      await batch.commit();
      if (kDebugMode) {
        print(
            '[AuthRepository] ensureCategoriesExist: Successfully created default categories.');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            '[AuthRepository] ensureCategoriesExist: Error creating categories: $e');
      }
    }
  }

  Future<firebase.UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatarPath,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final userId = userCredential.user!.uid;

    final newUser = User(
      id: userId,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      avatarPath: avatarPath,
    );

    await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
    await ensureCategoriesExist(userId);

    return userCredential;
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print("[AuthRepository] signInWithGoogle: Initiating Google Sign-In.");
      }
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) {
          print(
              "[AuthRepository] signInWithGoogle: User cancelled the sign-in.");
        }
        return null;
      }

      if (kDebugMode) {
        print(
            "[AuthRepository] signInWithGoogle: Google user selected. Authenticating with Firebase.");
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase.AuthCredential credential =
          firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final userId = userCredential.user!.uid;
      if (kDebugMode) {
        print(
            "[AuthRepository] signInWithGoogle: Firebase authenticated. Checking for profile for UID: $userId");
      }
      User? userProfile = await getUserProfile(userId);

      if (userProfile == null) {
        if (kDebugMode) {
          print(
              "[AuthRepository] signInWithGoogle: Profile not found. Creating new user profile.");
        }
        final newUser = User(
          id: userId,
          name: userCredential.user!.displayName ?? '',
          email: userCredential.user!.email ?? '',
          avatarPath: userCredential.user!.photoURL,
        );
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());
        userProfile = newUser;
      } else {
        if (kDebugMode) {
          print(
              "[AuthRepository] signInWithGoogle: Existing user profile found.");
        }
      }

      await ensureCategoriesExist(userId);

      if (kDebugMode) {
        print(
            "[AuthRepository] signInWithGoogle: Process complete. Returning user profile.");
      }
      return userProfile;
    } catch (e) {
      if (kDebugMode) {
        print("[AuthRepository] signInWithGoogle: An error occurred: $e");
      }
      rethrow;
    }
  }

  Future<void> updateUserProfile(User user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  firebase.User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }
}
