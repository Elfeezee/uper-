import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../chat/screens/chat_screen.dart';
import '../../../shared/services/ride_request_service.dart';

class ActiveRideMapScreen extends StatefulWidget {
  final String driverName;
  final String carModel;
  final String destination;
  final bool isDriver;
  final String? ridePin;
  final String? requestId;

  const ActiveRideMapScreen({
    super.key,
    required this.driverName,
    required this.carModel,
    required this.destination,
    this.isDriver = false,
    this.ridePin,
    this.requestId,
  });

  @override
  State<ActiveRideMapScreen> createState() => _ActiveRideMapScreenState();
}

class _ActiveRideMapScreenState extends State<ActiveRideMapScreen> {
  late GoogleMapController mapController;
  bool _tripStarted = false;
  
  // Mock coordinates for Abuja
  final LatLng _center = const LatLng(9.0765, 7.3986); 

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _startTrip() async {
    final pinController = TextEditingController();
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Passenger PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            hintText: '4-digit code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (success == true && widget.requestId != null) {
      try {
        // Use the service to verify
        await RideRequestService().verifyPinAndStartTrip(
          requestId: widget.requestId!,
          enteredPin: pinController.text,
        );
        setState(() => _tripStarted = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip started successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // SOS Button
          Positioned(
            top: 50,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.local_police, color: Colors.white),
                onPressed: () {
                  // SOS Action
                },
              ),
            ),
          ),

          // Bottom Ride Details Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Heading to ${widget.destination}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _tripStarted ? 'In Progress' : 'Arriving',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isDriver && widget.ridePin != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Give this PIN to your driver: ${widget.ridePin}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 1000.ms, curve: Curves.easeInOut),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.driverName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.carModel,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.chat, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(driverName: widget.driverName),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: AppTheme.secondaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.call, color: Colors.white),
                          onPressed: () {
                            // Call driver
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: widget.isDriver && !_tripStarted
                        ? ElevatedButton(
                            onPressed: _startTrip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Start Trip (Verify PIN)'),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              if (widget.isDriver && _tripStarted && widget.requestId != null) {
                                // End ride / pay
                                try {
                                  await RideRequestService().completeRideAndProcessPayment(widget.requestId!);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Trip completed! Fare collected to Wallet.')),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Payment Error: ${e.toString().replaceAll('Exception: ', '')}')),
                                    );
                                  }
                                }
                              } else {
                                // Cancel ride
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(widget.isDriver ? 'End Trip' : 'Cancel Ride'),
                          ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1.0, end: 0, duration: 600.ms, curve: Curves.easeOutCirc),
          ),
        ],
      ),
    );
  }
}
