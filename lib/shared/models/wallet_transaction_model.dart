import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { topup, withdrawal, ridePayment, rideEarnings, exchange }

class WalletTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final TransactionType type;
  final String description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? '₦',
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.topup,
      ),
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
