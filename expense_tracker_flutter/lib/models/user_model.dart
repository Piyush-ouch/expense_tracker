import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String baseCurrency;
  final String displaySymbol;
  final String? profilePic;
  final DateTime createdAt;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.baseCurrency,
    required this.displaySymbol,
    this.profilePic,
    required this.createdAt,
    this.phoneNumber,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      baseCurrency: data['base_currency'] ?? 'USD',
      displaySymbol: data['display_symbol'] ?? '\$',
      profilePic: data['profile_pic'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      phoneNumber: data['phone_number'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'base_currency': baseCurrency,
      'display_symbol': displaySymbol,
      'profile_pic': profilePic,
      'created_at': Timestamp.fromDate(createdAt),
      'phone_number': phoneNumber,
    };
  }
}
