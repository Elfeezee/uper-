import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/ride_model.dart';
import '../../../shared/models/ride_request_model.dart';
import '../../../shared/services/ride_service.dart';
import '../../../shared/services/ride_request_service.dart';
import '../../active_ride/screens/active_ride_map_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;

  const SearchResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final RideService _rideService = RideService();
  late Future<List<RideModel>> _ridesFuture;

  @override
  void initState() {
    super.initState();
    _ridesFuture = _rideService.searchRides(
      origin: widget.origin,
      destination: widget.destination,
    );
  }

  void _refresh() {
    setState(() {
      _ridesFuture = _rideService.searchRides(
        origin: widget.origin,
        destination: widget.destination,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.origin} → ${widget.destination}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Available Rides',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<RideModel>>(
        future: _ridesFuture,
        builder: (context, snapshot) {
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text('Finding rides...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // --- Error State ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not load rides',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final rides = snapshot.data ?? [];

          // --- Empty State ---
          if (rides.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      'No rides found',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No one is driving from\n${widget.origin} to ${widget.destination} yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check back later or try a different route.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- Results List ---
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                return _RideCard(
                  ride: ride,
                  destination: widget.destination,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideModel ride;
  final String destination;

  const _RideCard({required this.ride, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time & Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      ride.formattedTime,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ride.formattedPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Route mini-display
            Row(
              children: [
                const Column(
                  children: [
                    Icon(Icons.circle, size: 10, color: AppTheme.primaryColor),
                    SizedBox(
                        height: 4,
                        child: VerticalDivider(
                            thickness: 1.5, color: Colors.grey)),
                    Icon(Icons.location_on, size: 14, color: Colors.red),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.origin,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(ride.destination,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Driver Row
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.secondaryColor,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driverName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${ride.availableSeats} seat${ride.availableSeats != 1 ? 's' : ''} available',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_seat_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${ride.availableSeats}/${ride.totalSeats} seats',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    _showNegotiationSheet(context, ride);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Request'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNegotiationSheet(BuildContext context, RideModel ride) {
    final TextEditingController offerController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Request Ride with ${ride.driverName.split(' ').first}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Driver asks for ${ride.formattedPrice} per seat. Accept this price or offer your own fare.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: offerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Your Offer (₦)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  hintText: 'e.g., ${(ride.pricePerSeat * 0.9).toInt()}',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final customPrice = double.tryParse(offerController.text);
                    if (customPrice == null || customPrice <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    _sendRideRequest(context, ride, customPrice);
                  },
                  child: const Text('Send Counter-Offer'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sendRideRequest(context, ride, ride.pricePerSeat);
                  },
                  child: Text(
                    'Accept Asking Price (${ride.formattedPrice})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendRideRequest(
      BuildContext context, RideModel ride, double price) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first to request a ride'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (user.uid == ride.driverId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot request your own ride!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog while creating request in Firestore
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                SizedBox(height: 16),
                Text('Sending request to driver...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final passengerName = user.displayName?.isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? 'Passenger');

      final requestId = await RideRequestService().sendRequest(
        rideId: ride.id,
        driverId: ride.driverId,
        passengerId: user.uid,
        passengerName: passengerName,
        origin: ride.origin,
        destination: ride.destination,
        offeredPrice: price,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      // Open live waiting dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PassengerWaitingDialog(
          requestId: requestId,
          ride: ride,
          offeredPrice: price,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Dialog shown to the passenger while waiting for driver's decision
class _PassengerWaitingDialog extends StatefulWidget {
  final String requestId;
  final RideModel ride;
  final double offeredPrice;

  const _PassengerWaitingDialog({
    required this.requestId,
    required this.ride,
    required this.offeredPrice,
  });

  @override
  State<_PassengerWaitingDialog> createState() => _PassengerWaitingDialogState();
}

class _PassengerWaitingDialogState extends State<_PassengerWaitingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _hasHandledAcceptance = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RideRequestModel?>(
      stream: RideRequestService().watchRequest(widget.requestId),
      builder: (context, snapshot) {
        final req = snapshot.data;

        // Auto-navigate when driver accepts
        if (req != null &&
            req.status == RequestStatus.accepted &&
            !_hasHandledAcceptance) {
          _hasHandledAcceptance = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pop(); // Close waiting dialog
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveRideMapScreen(
                  driverName: widget.ride.driverName,
                  carModel:
                      '${widget.ride.availableSeats} seats • ${req.formattedPrice}',
                  destination: widget.ride.destination,
                  isDriver: false,
                  ridePin: req.ridePin,
                  requestId: widget.requestId,
                ),
              ),
            );
          });
        }

        final isDeclined = req?.status == RequestStatus.declined;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDeclined) ...[
                  const Icon(Icons.cancel_outlined,
                      size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Request Declined',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.ride.driverName} was unable to accept your offer. Please try another driver.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to Search'),
                    ),
                  ),
                ] else ...[
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_filled,
                        size: 56,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Waiting for Driver...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ringing ${widget.ride.driverName} with your offer of ₦${widget.offeredPrice.toInt()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel Request',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
