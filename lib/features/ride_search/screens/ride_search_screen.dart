import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'search_results_screen.dart';

class RideSearchScreen extends StatefulWidget {
  const RideSearchScreen({super.key});

  @override
  State<RideSearchScreen> createState() => _RideSearchScreenState();
}

class _RideSearchScreenState extends State<RideSearchScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Ride'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _originController,
                      decoration: const InputDecoration(
                        labelText: 'Leaving from (e.g., Abuja)',
                        prefixIcon: Icon(Icons.my_location, color: AppTheme.primaryColor),
                        filled: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Going to (e.g., Kaduna)',
                        prefixIcon: Icon(Icons.location_on, color: Colors.red),
                        filled: false,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.secondaryColor),
                      const SizedBox(width: 16),
                      Text(
                        _selectedDate == null
                            ? 'Today'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      const Text('1 Passenger'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultsScreen(
                        origin: _originController.text.isEmpty ? 'Abuja' : _originController.text,
                        destination: _destinationController.text.isEmpty ? 'Kaduna' : _destinationController.text,
                      ),
                    ),
                  );
                },
                child: const Text('Search Rides'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
