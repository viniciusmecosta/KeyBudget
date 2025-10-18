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
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  Future<void> _ensureGoogleSignInInitialized({String? serverClientId}) async {
    if (_isInitialized) return;

    try {
      await _googleSignIn.initialize(
        serverClientId: serverClientId,
      );
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing Google Sign-In: $e");
      }
      rethrow;
    }
  }

  Stream<User?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return await getUserProfile(firebaseUser.uid);
    });
  }

  Future<User?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting user profile: $e");
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
    try {
      final categoriesCollection =
          _firestore.collection('users').doc(userId).collection('categories');
      final existingCategories = await categoriesCollection.limit(1).get();

      if (existingCategories.docs.isNotEmpty) {
        return;
      }

      final List<ExpenseCategory> defaultCategories = [
        ExpenseCategory(
            name: 'Alimentação',
            iconCodePoint: Icons.restaurant.codePoint,
            colorValue: AppTheme.chartColors[0].toARGB32()),
        ExpenseCategory(
            name: 'Lazer',
            iconCodePoint: Icons.shopping_bag.codePoint,
            colorValue: AppTheme.chartColors[1].toARGB32()),
        ExpenseCategory(
            name: 'Roupa',
            iconCodePoint: Icons.checkroom.codePoint,
            colorValue: AppTheme.chartColors[2].toARGB32()),
        ExpenseCategory(
            name: 'Farmácia',
            iconCodePoint: Icons.medication_rounded.codePoint,
            colorValue: AppTheme.chartColors[3].toARGB32()),
        ExpenseCategory(
            name: 'Transporte',
            iconCodePoint: Icons.directions_bus.codePoint,
            colorValue: AppTheme.chartColors[4].toARGB32()),
        ExpenseCategory(
            name: 'Outros',
            iconCodePoint: Icons.category_rounded.codePoint,
            colorValue: AppTheme.chartColors[5].toARGB32()),
      ];

      final batch = _firestore.batch();
      for (final category in defaultCategories) {
        final docRef = categoriesCollection.doc();
        batch.set(docRef, category.toMap());
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print("Error ensuring categories exist: $e");
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

  Future<User?> signInWithGoogle({String? serverClientId}) async {
    try {
      await _ensureGoogleSignInInitialized(serverClientId: serverClientId);

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final firebase.AuthCredential credential =
          firebase.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final userId = userCredential.user!.uid;
      User? userProfile = await getUserProfile(userId);

      if (userProfile == null) {
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
      }

      await ensureCategoriesExist(userId);

      return userProfile;
    } catch (e) {
      if (kDebugMode) {
        print("Error during Google sign-in: $e");
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
