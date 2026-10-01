import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/ride_request_model.dart';
import '../../../shared/services/ride_alert_service.dart';
import '../../../shared/services/ride_request_service.dart';
import '../../ride_search/screens/ride_search_screen.dart';
import '../../ride_publish/screens/ride_publish_screen.dart';
import '../../ride_publish/screens/incoming_ride_request_dialog.dart';
import '../../wallet/screens/wallet_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RideRequestService _requestService = RideRequestService();
  final RideAlertService _alertService = RideAlertService();

  StreamSubscription<List<RideRequestModel>>? _requestSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  String _userRole = 'passenger';
  Map<String, dynamic>? _vehicleData;

  // Track requests already handled or showing dialog to avoid duplicate ringings
  final Set<String> _handledRequestIds = {};

  @override
  void initState() {
    super.initState();
    _alertService.initialize();
    _listenForUserAndRequests();
  }

  void _listenForUserAndRequests() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _requestSubscription?.cancel();
      _profileSubscription?.cancel();

      if (user == null) return;

      // 1. Listen to user profile (to determine if Driver or Passenger)
      _profileSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (!mounted) return;
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final role = (data['role'] as String?) ?? 'passenger';
          final vehicle = data['vehicle'] as Map<String, dynamic>?;

          setState(() {
            _userRole = role;
            _vehicleData = vehicle;
          });

          // If user is a driver, start listening for incoming requests!
          if (role == 'driver') {
            _subscribeToDriverRequests(user.uid);
          } else {
            _requestSubscription?.cancel();
          }
        }
      });
    });
  }

  void _subscribeToDriverRequests(String driverUid) {
    _requestSubscription?.cancel();
    _requestSubscription = _requestService
        .watchPendingRequestsForDriver(driverUid)
        .listen((requests) {
      if (!mounted || requests.isEmpty) return;

      for (final req in requests) {
        if (!_handledRequestIds.contains(req.id)) {
          _handledRequestIds.add(req.id);

          // Ring the phone!
          _alertService.startRingtone(
            passengerName: req.passengerName,
            route: '${req.origin} → ${req.destination}',
            price: req.formattedPrice,
          );

          // Show full-screen incoming ride dialog
          IncomingRideRequestDialog.show(context, req);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _requestSubscription?.cancel();
    _alertService.stopRingtone();
    super.dispose();
  }


  void _showUpgradeToDriverDialog() {
    final modelController = TextEditingController();
    final plateController = TextEditingController();
    final colorController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.directions_car, color: AppTheme.accentColor),
            SizedBox(width: 8),
            Text('Register as Driver', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your vehicle details to start offering rides and earning.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Car Model',
                  hintText: 'e.g. Toyota Corolla',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter car model' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'Plate Number',
                  hintText: 'e.g. KJA-123-AB',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter plate number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  hintText: 'e.g. Silver',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter vehicle color' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'role': 'driver',
                  'vehicle': {
                    'model': modelController.text.trim(),
                    'plateNumber': plateController.text.trim().toUpperCase(),
                    'color': colorController.text.trim(),
                  },
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Upgraded to Driver account successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Register Car'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Traveler');

    final isDriver = _userRole == 'driver';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet,
                color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Profile
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Role Status Banner
              if (isDriver)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver Mode Active (Ringing Enabled)',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_vehicleData != null)
                              Text(
                                '${_vehicleData!['model'] ?? ''} • ${_vehicleData!['plateNumber'] ?? ''}',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin_circle,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Passenger Mode: Search rides & carpool',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showUpgradeToDriverDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Drive? +',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 24),

              Text(
                'Hello, $displayName 👋',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fade(delay: 100.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
              const SizedBox(height: 4),
              Text(
                isDriver ? 'Ready to drive today?' : 'Where to today?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ).animate().fade(delay: 200.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
              const SizedBox(height: 28),

              // Find a Ride Option (Passenger Only)
              if (!isDriver) ...[
                _buildOptionCard(
                  context,
                  title: 'Find a Ride',
                  subtitle: 'Search for carpool routes & request seats',
                  icon: Icons.search,
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RideSearchScreen()),
                    );
                  },
                ).animate().fade(delay: 300.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: 20),
              ],

              // Offer a Ride Option (Driver Only)
              if (isDriver) ...[
                _buildOptionCard(
                  context,
                  title: 'Offer a Ride',
                  subtitle: 'Publish empty seats & earn money.',
                  icon: Icons.local_taxi,
                  color: AppTheme.accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RidePublishScreen()),
                    );
                  },
                ).animate().fade(delay: 400.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
