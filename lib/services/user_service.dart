// services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // User collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create or update user profile in Firestore
  Future<void> createOrUpdateUserProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoURL,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? location,
  }) async {
    try {
      final userData = {
        'uid': uid,
        'email': email ?? _auth.currentUser?.email,
        'displayName': displayName ?? _auth.currentUser?.displayName,
        'photoURL': photoURL ?? _auth.currentUser?.photoURL,
        'bio': bio,
        'phone': phone,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _usersCollection.doc(uid).set(
        userData,
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to create/update user profile: $e');
    }
  }

  // Get user profile from Firestore
  Future<UserProfile?> getUserProfile([String? uid]) async {
    try {
      final userId = uid ?? currentUserId;
      if (userId == null) return null;

      final doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      } else {
        // Create default profile if doesn't exist
        await createOrUpdateUserProfile(uid: userId);
        final newDoc = await _usersCollection.doc(userId).get();
        return newDoc.exists ? UserProfile.fromFirestore(newDoc) : null;
      }
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile - This is the main method for updating profile
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? location,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add fields that are being updated
      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (phone != null) updateData['phone'] = phone;
      if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (location != null) updateData['location'] = location;

      // Update Firestore document
      await _usersCollection.doc(userId).update(updateData);

      // Update Firebase Auth profile if display name changed
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get user profile stream for real-time updates
  Stream<UserProfile?> getUserProfileStream([String? uid]) {
    final userId = uid ?? currentUserId;
    if (userId == null) return Stream.value(null);

    return _usersCollection.doc(userId).snapshots().map((doc) {
      return doc.exists ? UserProfile.fromFirestore(doc) : null;
    });
  }

  // Delete user profile
  Future<void> deleteUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // Update photo URL
  Future<void> updatePhotoURL(String photoURL) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _usersCollection.doc(userId).update({
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth profile
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw Exception('Failed to update photo URL: $e');
    }
  }
}

// User Profile Model
class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? bio;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,

    this.bio,
    this.phone,
    this.dateOfBirth,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserProfile(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      bio: data['bio'],
      phone: data['phone'],
      dateOfBirth: data['dateOfBirth'] != null
          ? DateTime.parse(data['dateOfBirth'])
          : null,
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'location': location,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,

      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get initials {
    final name = displayName ?? email ?? 'U';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String get formattedName {
    return displayName ?? email?.split('@').first ?? 'User';
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get hasCompleteProfile {
    return displayName != null &&
        phone != null &&
        dateOfBirth != null &&
        location != null;
  }
}