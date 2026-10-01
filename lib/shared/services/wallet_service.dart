import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_transaction_model.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream a user's wallet balance
  Stream<double> watchBalance(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['walletBalance'] ?? 0.0).toDouble();
    });
  }

  /// Stream a user's transaction history (most recent first)
  Stream<List<WalletTransactionModel>> watchTransactions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => WalletTransactionModel.fromFirestore(doc)).toList());
  }

  /// Add funds to the wallet
  Future<void> topUp(String userId, double amount) async {
    if (amount <= 0) throw Exception('Invalid top-up amount');

    final userRef = _db.collection('users').doc(userId);
    final txRef = userRef.collection('transactions').doc();

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');

      final data = userDoc.data() as Map<String, dynamic>?;
      final currentBalance = (data?['walletBalance'] ?? 0.0).toDouble();

      // Update balance
      transaction.update(userRef, {
        'walletBalance': currentBalance + amount,
      });

      // Add transaction record
      final newTx = WalletTransactionModel(
        id: txRef.id,
        userId: userId,
        amount: amount,
        currency: '₦',
        type: TransactionType.topup,
        description: 'Wallet Top-up',
        createdAt: DateTime.now(),
      );
      transaction.set(txRef, newTx.toFirestore());
    });
  }

  /// Withdraw funds from the wallet
  Future<void> withdraw(String userId, double amount) async {
    if (amount <= 0) throw Exception('Invalid withdrawal amount');

    final userRef = _db.collection('users').doc(userId);
    final txRef = userRef.collection('transactions').doc();

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');

      final data = userDoc.data() as Map<String, dynamic>?;
      final currentBalance = (data?['walletBalance'] ?? 0.0).toDouble();

      if (currentBalance < amount) {
        throw Exception('Insufficient funds');
      }

      // Update balance
      transaction.update(userRef, {
        'walletBalance': currentBalance - amount,
      });

      // Add transaction record
      final newTx = WalletTransactionModel(
        id: txRef.id,
        userId: userId,
        amount: amount,
        currency: '₦',
        type: TransactionType.withdrawal,
        description: 'Wallet Withdrawal',
        createdAt: DateTime.now(),
      );
      transaction.set(txRef, newTx.toFirestore());
    });
  }

  /// Process a ride payment (deduct from passenger, add to driver)
  Future<void> processRidePayment({
    required String passengerId,
    required String driverId,
    required double amount,
  }) async {
    if (amount <= 0) throw Exception('Invalid payment amount');

    final passengerRef = _db.collection('users').doc(passengerId);
    final driverRef = _db.collection('users').doc(driverId);
    final passTxRef = passengerRef.collection('transactions').doc();
    final driverTxRef = driverRef.collection('transactions').doc();

    await _db.runTransaction((transaction) async {
      final passengerDoc = await transaction.get(passengerRef);
      final driverDoc = await transaction.get(driverRef);

      final passData = passengerDoc.data() as Map<String, dynamic>?;
      final driverData = driverDoc.data() as Map<String, dynamic>?;

      final passengerBalance = (passData?['walletBalance'] ?? 0.0).toDouble();
      final driverBalance = (driverData?['walletBalance'] ?? 0.0).toDouble();

      if (passengerBalance < amount) {
        throw Exception('Passenger has insufficient funds for this ride.');
      }

      // Deduct from Passenger
      transaction.update(passengerRef, {
        'walletBalance': passengerBalance - amount,
      });

      // Add Passenger Transaction
      final passTx = WalletTransactionModel(
        id: passTxRef.id,
        userId: passengerId,
        amount: amount,
        currency: '₦',
        type: TransactionType.ridePayment,
        description: 'Payment for Ride',
        createdAt: DateTime.now(),
      );
      transaction.set(passTxRef, passTx.toFirestore());

      // Add to Driver
      transaction.update(driverRef, {
        'walletBalance': driverBalance + amount,
      });

      // Add Driver Transaction
      final driverTx = WalletTransactionModel(
        id: driverTxRef.id,
        userId: driverId,
        amount: amount,
        currency: '₦',
        type: TransactionType.rideEarnings,
        description: 'Earnings from Ride',
        createdAt: DateTime.now(),
      );
      transaction.set(driverTxRef, driverTx.toFirestore());
    });
  }
}

