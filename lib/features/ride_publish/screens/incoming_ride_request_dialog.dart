import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/ride_request_model.dart';
import '../../../shared/services/ride_alert_service.dart';
import '../../../shared/services/ride_request_service.dart';
import '../../active_ride/screens/active_ride_map_screen.dart';

/// Full-screen incoming ride request overlay modal (Uber / Bolt style)
/// featuring a pulsing animation, 30-second countdown, and accept/decline actions.
class IncomingRideRequestDialog extends StatefulWidget {
  final RideRequestModel request;

  const IncomingRideRequestDialog({
    super.key,
    required this.request,
  });

  static Future<void> show(BuildContext context, RideRequestModel request) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => IncomingRideRequestDialog(request: request),
    );
  }

  @override
  State<IncomingRideRequestDialog> createState() =>
      _IncomingRideRequestDialogState();
}

class _IncomingRideRequestDialogState extends State<IncomingRideRequestDialog>
    with SingleTickerProviderStateMixin {
  final RideRequestService _requestService = RideRequestService();
  final RideAlertService _alertService = RideAlertService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 30-second countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _handleDecline();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _alertService.stopRingtone();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    await _alertService.stopRingtone();
    _countdownTimer?.cancel();

    try {
      if (!widget.request.id.startsWith('test_request_')) {
        await _requestService.acceptRequest(widget.request);
      }
      if (!mounted) return;

      Navigator.of(context).pop();

      // Open ActiveRideMapScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveRideMapScreen(
            driverName: widget.request.passengerName,
            carModel: 'Passenger: ${widget.request.passengerName}',
            destination: widget.request.destination,
            isDriver: true,
            requestId: widget.request.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept ride: $e')),
      );
    }
  }

  Future<void> _handleDecline() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    await _alertService.stopRingtone();
    _countdownTimer?.cancel();

    try {
      if (!widget.request.id.startsWith('test_request_')) {
        await _requestService.declineRequest(widget.request.id);
      }
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF111827), // Sleek dark slate
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                // Top Tag & Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'NEW REQUEST',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: CircularProgressIndicator(
                            value: _secondsRemaining / 30.0,
                            strokeWidth: 4,
                            color: _secondsRemaining <= 10 ? Colors.red : AppTheme.primaryColor,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        Text(
                          '$_secondsRemaining',
                          style: TextStyle(
                            color: _secondsRemaining <= 10 ? Colors.red : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Pulsing Icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withOpacity(0.18),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.local_taxi_rounded,
                      color: AppTheme.primaryColor,
                      size: 64,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Offered Price
                Text(
                  widget.request.formattedPrice,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Offered Fare',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Passenger & Route Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      // Passenger Info
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.secondaryColor,
                            child: Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.request.passengerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      '5.0 ★ • Passenger',
                                      style: TextStyle(color: Colors.white60, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white12, height: 1),
                      ),

                      // Route Details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            children: [
                              Icon(Icons.circle, size: 12, color: AppTheme.primaryColor),
                              SizedBox(
                                height: 28,
                                child: VerticalDivider(
                                  color: Colors.white30,
                                  thickness: 1.5,
                                ),
                              ),
                              Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.request.origin.isEmpty ? 'Current Pickup' : widget.request.origin,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  widget.request.destination.isEmpty ? 'Destination' : widget.request.destination,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Action Buttons (Decline / Accept)
                if (_isProcessing)
                  const CircularProgressIndicator(color: AppTheme.primaryColor)
                else
                  Row(
                    children: [
                      // Decline Button
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: _handleDecline,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, color: Colors.redAccent),
                              SizedBox(width: 6),
                              Text(
                                'Decline',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Accept Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: _handleAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'ACCEPT RIDE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
