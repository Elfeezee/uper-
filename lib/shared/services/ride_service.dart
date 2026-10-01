import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';

/// Service class for all Firestore operations related to rides.
class RideService {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'rides';

  /// Publishes a new ride to Firestore.
  /// Returns the document ID of the newly created ride.
  Future<String> publishRide({
    required String driverId,
    required String driverName,
    required String origin,
    required String destination,
    required DateTime departureTime,
    required int seats,
    required double pricePerSeat,
  }) async {
    final ride = RideModel(
      id: '',
      driverId: driverId,
      driverName: driverName,
      origin: origin,
      destination: destination,
      departureTime: departureTime,
      totalSeats: seats,
      availableSeats: seats,
      pricePerSeat: pricePerSeat,
      status: 'active',
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_collection)
        .add(ride.toFirestore());

    return docRef.id;
  }

  /// Searches for active rides matching the given origin and destination.
  /// Fetches all rides with NO server-side ordering (avoids composite index).
  /// All filtering and sorting happens client-side.
  Future<List<RideModel>> searchRides({
    required String origin,
    required String destination,
  }) async {
    final originQuery = origin.toLowerCase().trim();
    final destinationQuery = destination.toLowerCase().trim();

    // Only a single equality filter — Firestore handles this with no index at all.
    final QuerySnapshot snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .get();

    final allRides = snapshot.docs.map(RideModel.fromFirestore).toList();

    // Filter and sort entirely on the client side
    final filtered = allRides.where((ride) {
      final matchesOrigin = originQuery.isEmpty ||
          ride.origin.toLowerCase().contains(originQuery);
      final matchesDestination = destinationQuery.isEmpty ||
          ride.destination.toLowerCase().contains(destinationQuery);
      return matchesOrigin && matchesDestination && ride.availableSeats > 0;
    }).toList();

    // Sort by departure time ascending
    filtered.sort((a, b) => a.departureTime.compareTo(b.departureTime));

    return filtered;
  }

  /// Fetches all active rides as a real-time stream.
  /// Uses only a single equality filter — no composite index required.
  Stream<List<RideModel>> watchActiveRides() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map(RideModel.fromFirestore)
              .where((r) => r.availableSeats > 0)
              .toList();
          // Sort by departure time client-side
          rides.sort((a, b) => a.departureTime.compareTo(b.departureTime));
          return rides;
        });
  }
}
