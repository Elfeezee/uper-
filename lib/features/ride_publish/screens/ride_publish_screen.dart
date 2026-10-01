import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/ride_service.dart';

class RidePublishScreen extends StatefulWidget {
  const RidePublishScreen({super.key});

  @override
  State<RidePublishScreen> createState() => _RidePublishScreenState();
}

class _RidePublishScreenState extends State<RidePublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _seats = 3;
  bool _isPublishing = false;

  final RideService _rideService = RideService();

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  Future<void> _publishRide() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a departure date and time.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final driverName = user?.displayName ?? user?.email?.split('@').first ?? 'Driver';
      final driverId = user?.uid ?? 'anonymous';

      final departureTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _rideService.publishRide(
        driverId: driverId,
        driverName: driverName,
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        departureTime: departureTime,
        seats: _seats,
        pricePerSeat: double.parse(_priceController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Ride Published! Passengers can now find it.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDateTime = _selectedDate != null && _selectedTime != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer a Ride'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Publish your ride',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share your route and find passengers going your way.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _originController,
                  decoration: const InputDecoration(
                    labelText: 'Leaving from',
                    prefixIcon: Icon(Icons.my_location, color: AppTheme.primaryColor),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter your starting point' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Going to',
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter your destination' : null,
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: hasDateTime ? AppTheme.primaryColor : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: hasDateTime ? AppTheme.primaryColor : AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          hasDateTime
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}  at  ${_selectedTime!.format(context)}'
                              : 'Select Date & Time',
                          style: TextStyle(
                            fontSize: 15,
                            color: hasDateTime ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_seat, color: AppTheme.secondaryColor),
                  title: const Text('Available Seats'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_seats > 1) setState(() => _seats--);
                        },
                      ),
                      Text('$_seats',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (_seats < 8) setState(() => _seats++);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Asking Price per seat (₦)',
                    prefixIcon: Icon(Icons.payments_outlined),
                    hintText: 'e.g., 5000',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter a price';
                    if (double.tryParse(v.trim()) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _isPublishing ? null : _publishRide,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Publish Ride',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
