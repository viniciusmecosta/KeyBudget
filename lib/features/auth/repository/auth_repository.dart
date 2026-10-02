import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/utils/string_extensions.dart';
import 'package:key_budget/core/models/user_model.dart';

class ProfileSetupException implements Exception {
  const ProfileSetupException();
}

class AuthRepository {
  final firebase.FirebaseAuth? _customFirebaseAuth;
  final FirebaseFirestore? _customFirestore;
  final GoogleSignIn? _customGoogleSignIn;

  AuthRepository({
    firebase.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _customFirebaseAuth = firebaseAuth,
       _customFirestore = firestore,
       _customGoogleSignIn = googleSignIn;

  firebase.FirebaseAuth get _firebaseAuth =>
      _customFirebaseAuth ?? firebase.FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn =>
      _customGoogleSignIn ?? GoogleSignIn.instance;

  bool _isInitialized = false;

  Future<void> _ensureGoogleSignInInitialized({String? serverClientId}) async {
    if (_isInitialized) return;

    try {
      await _googleSignIn.initialize(serverClientId: serverClientId);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing Google Sign-In: $e");
      }
      rethrow;
    }
  }

  Stream<firebase.User?> get firebaseAuthStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  Stream<User?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Future<User?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (doc.exists) {
      return User.fromMap(doc.data()!);
    }
    return null;
  }

  Future<firebase.UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> ensureCategoriesExist(String userId) async {
    try {
      final categoriesCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('categories');
      final existingCategories = await categoriesCollection.get();
      final existingNames = existingCategories.docs
          .map((doc) => (doc.data()['name'] as String?) ?? '')
          .map((name) => name.withoutDiacritics.trim().toLowerCase())
          .toSet();
      final existingIds = existingCategories.docs.map((doc) => doc.id).toSet();

      final defaults = <({String id, ExpenseCategory category})>[
        (
          id: 'default_alimentacao',
          category: ExpenseCategory(
            name: 'Alimentação',
            iconCodePoint: Icons.restaurant.codePoint,
            colorValue: AppTheme.chartColors[0].toARGB32(),
          ),
        ),
        (
          id: 'default_lazer',
          category: ExpenseCategory(
            name: 'Lazer',
            iconCodePoint: Icons.shopping_bag.codePoint,
            colorValue: AppTheme.chartColors[1].toARGB32(),
          ),
        ),
        (
          id: 'default_roupa',
          category: ExpenseCategory(
            name: 'Roupa',
            iconCodePoint: Icons.checkroom.codePoint,
            colorValue: AppTheme.chartColors[2].toARGB32(),
          ),
        ),
        (
          id: 'default_farmacia',
          category: ExpenseCategory(
            name: 'Farmácia',
            iconCodePoint: Icons.medication_rounded.codePoint,
            colorValue: AppTheme.chartColors[3].toARGB32(),
          ),
        ),
        (
          id: 'default_transporte',
          category: ExpenseCategory(
            name: 'Transporte',
            iconCodePoint: Icons.directions_bus.codePoint,
            colorValue: AppTheme.chartColors[4].toARGB32(),
          ),
        ),
        (
          id: 'default_outros',
          category: ExpenseCategory(
            name: 'Outros',
            iconCodePoint: Icons.category_rounded.codePoint,
            colorValue: AppTheme.chartColors[5].toARGB32(),
          ),
        ),
      ];

      final batch = _firestore.batch();
      var hasDefaultsToCreate = false;
      for (final entry in defaults) {
        final normalizedName = entry.category.name.withoutDiacritics
            .trim()
            .toLowerCase();
        if (existingIds.contains(entry.id) ||
            existingNames.contains(normalizedName)) {
          continue;
        }
        batch.set(categoriesCollection.doc(entry.id), entry.category.toMap());
        hasDefaultsToCreate = true;
      }
      if (hasDefaultsToCreate) {
        await batch.commit();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error ensuring categories exist: $e");
      }
    }
  }

  Future<User> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatarPath,
  }) async {
    firebase.User authUser;
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      authUser = credential.user!;
    } on firebase.FirebaseAuthException catch (error) {
      final current = _firebaseAuth.currentUser;
      if (error.code != 'email-already-in-use' ||
          current == null ||
          current.email?.trim().toLowerCase() != email.trim().toLowerCase()) {
        rethrow;
      }
      authUser = current;
    }
    final userId = authUser.uid;

    final newUser = User(
      id: userId,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      avatarPath: avatarPath,
    );

    try {
      final profileRef = _firestore.collection('users').doc(userId);
      final savedProfile = await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(profileRef);
        if (existing.exists) {
          return User.fromMap(existing.data()!);
        }
        transaction.set(profileRef, newUser.toMap());
        return newUser;
      });
      await ensureCategoriesExist(userId);
      return savedProfile;
    } catch (_) {
      throw const ProfileSetupException();
    }
  }

  Future<User?> signInWithGoogle({String? serverClientId}) async {
    try {
      await _ensureGoogleSignInInitialized(serverClientId: serverClientId);

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final firebase.AuthCredential credential =
          firebase.GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final userId = userCredential.user!.uid;
      User? userProfile = await getUserProfile(userId);

      if (userProfile == null) {
        final newUser = User(
          id: userId,
          name: userCredential.user!.displayName ?? '',
          email: userCredential.user!.email ?? '',
          avatarPath: userCredential.user!.photoURL,
        );
        final profileRef = _firestore.collection('users').doc(newUser.id);
        userProfile = await _firestore.runTransaction((transaction) async {
          final existing = await transaction.get(profileRef);
          if (existing.exists) {
            return User.fromMap(existing.data()!);
          }
          transaction.set(profileRef, newUser.toMap());
          return newUser;
        });
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
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        print("Error during Google sign-out: $e");
      }
    }
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  firebase.User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
