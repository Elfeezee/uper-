import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final int totalSeats;
  final int availableSeats;
  final double pricePerSeat;
  final String status; // 'active', 'full', 'completed', 'cancelled'
  final DateTime createdAt;

  const RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    this.status = 'active',
    required this.createdAt,
  });

  /// Creates a RideModel from a Firestore document snapshot.
  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideModel(
      id: doc.id,
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? 'Unknown Driver',
      origin: data['origin'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      departureTime: (data['departureTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 1,
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 1,
      pricePerSeat: (data['pricePerSeat'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the RideModel to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'origin': origin,
      'destination': destination,
      'departureTime': Timestamp.fromDate(departureTime),
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      // Lowercase for case-insensitive search queries
      'originLower': origin.toLowerCase(),
      'destinationLower': destination.toLowerCase(),
    };
  }

  /// Returns a formatted price string in Nigerian Naira.
  String get formattedPrice {
    final int naira = pricePerSeat.toInt();
    return '₦${naira.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }

  /// Returns a formatted departure time string.
  String get formattedTime {
    final hour = departureTime.hour;
    final minute = departureTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $period';
  }
}
