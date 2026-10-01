import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_request_model.dart';
import 'wallet_service.dart';

/// Service for all Firestore operations on ride requests.
class RideRequestService {
  static final RideRequestService _instance = RideRequestService._internal();
  factory RideRequestService() => _instance;
  RideRequestService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'rideRequests';

  /// Passenger sends a request to a driver's ride.
  Future<String> sendRequest({
    required String rideId,
    required String driverId,
    required String passengerId,
    required String passengerName,
    required String origin,
    required String destination,
    required double offeredPrice,
  }) async {
    // Generate a random 4-digit PIN
    final random = math.Random();
    final pin = random.nextInt(10000).toString().padLeft(4, '0');

    final request = RideRequestModel(
      id: '',
      rideId: rideId,
      driverId: driverId,
      passengerId: passengerId,
      passengerName: passengerName,
      origin: origin,
      destination: destination,
      offeredPrice: offeredPrice,
      ridePin: pin, // Assign generated PIN
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );
    final ref = await _db.collection(_collection).add(request.toFirestore());
    return ref.id;
  }

  /// Driver accepts a request — updates status and decrements available seats.
  Future<void> acceptRequest(RideRequestModel request) async {
    final batch = _db.batch();

    // Update request status
    batch.update(
      _db.collection(_collection).doc(request.id),
      {'status': RequestStatus.accepted.name},
    );

    // Decrement available seats on the ride
    batch.update(
      _db.collection('rides').doc(request.rideId),
      {'availableSeats': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  /// Driver declines a request.
  Future<void> declineRequest(String requestId) async {
    await _db.collection(_collection).doc(requestId).update(
      {'status': RequestStatus.declined.name},
    );
  }

  /// Driver verifies the passenger's 4-digit PIN to start the trip.
  /// Throws an exception if the PIN is incorrect.
  Future<void> verifyPinAndStartTrip({
    required String requestId,
    required String enteredPin,
  }) async {
    final doc = await _db.collection(_collection).doc(requestId).get();
    if (!doc.exists) {
      throw Exception('Request not found');
    }
    
    final request = RideRequestModel.fromFirestore(doc);
    if (request.ridePin != enteredPin) {
      throw Exception('Incorrect PIN. Please ask the passenger for their 4-digit code.');
    }

    // PIN matches! Update status to in_progress
    await _db.collection(_collection).doc(requestId).update(
      {'status': RequestStatus.in_progress.name},
    );
  }

  /// Driver completes the ride. This deducts the fare from the passenger and pays the driver.
  Future<void> completeRideAndProcessPayment(String requestId) async {
    final doc = await _db.collection(_collection).doc(requestId).get();
    if (!doc.exists) {
      throw Exception('Request not found');
    }
    
    final request = RideRequestModel.fromFirestore(doc);
    
    // Process Payment via WalletService
    await WalletService().processRidePayment(
      passengerId: request.passengerId,
      driverId: request.driverId,
      amount: request.offeredPrice,
    );
    
    // Update ride status to completed
    await _db.collection(_collection).doc(requestId).update({
      'status': RequestStatus.completed.name
    });
  }

  /// Listens for all PENDING requests on rides owned by [driverId].
  /// Fires every time a new request arrives in real-time.
  Stream<List<RideRequestModel>> watchPendingRequestsForDriver(String driverId) {
    return _db
        .collection(_collection)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(RideRequestModel.fromFirestore).toList());
  }

  /// Listens for status changes on a specific request (for the passenger side).
  Stream<RideRequestModel?> watchRequest(String requestId) {
    return _db
        .collection(_collection)
        .doc(requestId)
        .snapshots()
        .map((doc) => doc.exists ? RideRequestModel.fromFirestore(doc) : null);
  }
}
