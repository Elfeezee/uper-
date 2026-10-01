import 'package:cloud_firestore/cloud_firestore.dart';

/// Full lifecycle states for an active ride.
enum RequestStatus {
  pending,      // Waiting for driver response
  accepted,     // Driver accepted, en route to pickup
  arrived,      // Driver has arrived at pickup location
  in_progress,  // 4-digit PIN verified, trip is underway
  completed,    // Driver and passenger completed trip
  declined,     // Driver declined
  cancelled,    // Cancelled by either party
}

class RideRequestModel {
  final String id;
  final String rideId;
  final String driverId;
  final String driverName;
  final String carModel;
  final String passengerId;
  final String passengerName;
  final String origin;
  final String destination;
  final double offeredPrice;
  final String ridePin;
  final double? driverLat;
  final double? driverLng;
  final double? driverHeading;
  final RequestStatus status;
  final DateTime createdAt;

  const RideRequestModel({
    required this.id,
    required this.rideId,
    required this.driverId,
    this.driverName = 'Driver',
    this.carModel = 'Vehicle',
    required this.passengerId,
    required this.passengerName,
    required this.origin,
    required this.destination,
    required this.offeredPrice,
    this.ridePin = '1234',
    this.driverLat,
    this.driverLng,
    this.driverHeading,
    this.status = RequestStatus.pending,
    required this.createdAt,
  });

  factory RideRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideRequestModel(
      id: doc.id,
      rideId: data['rideId'] as String? ?? '',
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? 'Driver',
      carModel: data['carModel'] as String? ?? 'Vehicle',
      passengerId: data['passengerId'] as String? ?? '',
      passengerName: data['passengerName'] as String? ?? 'Passenger',
      origin: data['origin'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      offeredPrice: (data['offeredPrice'] as num?)?.toDouble() ?? 0.0,
      ridePin: data['ridePin'] as String? ?? '1234',
      driverLat: (data['driverLat'] as num?)?.toDouble(),
      driverLng: (data['driverLng'] as num?)?.toDouble(),
      driverHeading: (data['driverHeading'] as num?)?.toDouble(),
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'driverId': driverId,
      'driverName': driverName,
      'carModel': carModel,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'origin': origin,
      'destination': destination,
      'offeredPrice': offeredPrice,
      'ridePin': ridePin,
      'driverLat': driverLat,
      'driverLng': driverLng,
      'driverHeading': driverHeading,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static RequestStatus _statusFromString(String s) {
    return RequestStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => RequestStatus.pending,
    );
  }

  String get formattedPrice {
    final int naira = offeredPrice.toInt();
    return '₦${naira.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }
}
