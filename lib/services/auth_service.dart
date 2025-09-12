import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'invalid-email':
          throw 'Invalid email address.';
        case 'user-disabled':
          throw 'This user has been disabled.';
        case 'invalid-credential':
          throw 'Invalid email or password.';
        default:
          throw 'An error occurred. Please try again.';
      }
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // Register with email and password
  Future<User?> createUserWithEmailAndPassword(
      String email,
      String password,
      String displayName,
      ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await result.user!.reload();
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw 'The password is too weak.';
        case 'email-already-in-use':
          throw 'An account already exists with this email.';
        case 'invalid-email':
          throw 'Invalid email address.';
        default:
          throw 'An error occurred. Please try again.';
      }
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If the user cancels the sign-in process
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result =
      await _auth.signInWithCredential(credential);

      return result.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'An account already exists with the same email address but different sign-in credentials.';
        case 'invalid-credential':
          throw 'Invalid credentials. Please try again.';
        case 'operation-not-allowed':
          throw 'Google sign-in is not enabled. Please contact support.';
        case 'user-disabled':
          throw 'This user has been disabled.';
        default:
          throw 'An error occurred during Google sign-in. Please try again.';
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('Sign out error: $e');
      throw 'Error signing out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw 'Invalid email address.';
        case 'user-not-found':
          throw 'No user found with this email.';
        default:
          throw 'An error occurred. Please try again.';
      }
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // Check if user is signed in with Google
  bool isGoogleSignIn() {
    final user = _auth.currentUser;
    if (user != null) {
      for (var provider in user.providerData) {
        if (provider.providerId == 'google.com') {
          return true;
        }
      }
    }
    return false;
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Failed to send verification email. Please try again.';
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();
      }
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }
}