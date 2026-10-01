import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Stream providing the current user profile (including role: driver or passenger)
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((doc) => doc.data());
});

// Riverpod 3.x: use Notifier<bool> instead of StateNotifier<bool>
class AuthController extends Notifier<bool> {
  late FirebaseAuth _auth;

  @override
  bool build() {
    _auth = ref.watch(firebaseAuthProvider);
    return false; // initial state: not loading
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = true;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role, // 'passenger' or 'driver'
    Map<String, dynamic>? vehicle,
  }) async {
    state = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(fullName);

        // Save detailed profile in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'phone': phone,
          'email': email,
          'role': role,
          'vehicle': vehicle,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = true;
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        state = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _checkAndCreateUserProfile(userCredential.user);
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> signInWithApple() async {
    state = true;
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      await _checkAndCreateUserProfile(userCredential.user);
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> _checkAndCreateUserProfile(User? user) async {
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'fullName': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'role': 'passenger', // Default to passenger for social logins
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// Riverpod 3.x: use NotifierProvider instead of StateNotifierProvider
final authControllerProvider = NotifierProvider<AuthController, bool>(() {
  return AuthController();
});
