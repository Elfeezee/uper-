import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Role: 'passenger' or 'driver'
  String _selectedRole = 'passenger';

  // Common user fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Driver-specific fields
  final TextEditingController _vehicleModelController =
      TextEditingController();
  final TextEditingController _plateNumberController =
      TextEditingController();
  final TextEditingController _vehicleColorController =
      TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _vehicleModelController.dispose();
    _plateNumberController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final isDriver = _selectedRole == 'driver';
    Map<String, dynamic>? vehicleData;

    if (isDriver) {
      vehicleData = {
        'model': _vehicleModelController.text.trim(),
        'plateNumber': _plateNumberController.text.trim().toUpperCase(),
        'color': _vehicleColorController.text.trim(),
      };
    }

    try {
      await ref.read(authControllerProvider.notifier).signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole,
            vehicle: vehicleData,
          );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final isDriver = _selectedRole == 'driver';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join Uper',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isDriver
                      ? 'Register your vehicle and start earning as a driver.'
                      : 'Find rides, carpool, and save on daily commuting.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Role Selector Switcher (Passenger vs Driver)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildRoleTab(
                          roleKey: 'passenger',
                          label: 'Passenger',
                          subtitle: 'I want to ride',
                          icon: Icons.person_pin_circle_outlined,
                          isSelected: !isDriver,
                        ),
                      ),
                      Expanded(
                        child: _buildRoleTab(
                          roleKey: 'driver',
                          label: 'Driver',
                          subtitle: 'I have a car',
                          icon: Icons.directions_car_filled_outlined,
                          isSelected: isDriver,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Common Form Fields
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'e.g. Amina Bello',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'e.g. 08012345678',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.trim().length < 10 ? 'Please enter a valid phone number' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'e.g. user@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),

                // Driver Vehicle Section (animated display)
                if (isDriver) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_car, color: Colors.orange, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Vehicle Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Passengers will see your car model and color when you accept rides.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _vehicleModelController,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle Make & Model',
                            prefixIcon: Icon(Icons.car_rental_outlined),
                            hintText: 'e.g. Toyota Corolla 2017',
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          validator: (v) => isDriver && (v == null || v.trim().isEmpty)
                              ? 'Enter your car model'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _plateNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'License Plate',
                                  prefixIcon: Icon(Icons.pin_outlined),
                                  hintText: 'e.g. KJA-829-AB',
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                textCapitalization: TextCapitalization.characters,
                                validator: (v) => isDriver && (v == null || v.trim().isEmpty)
                                    ? 'Enter plate number'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _vehicleColorController,
                                decoration: const InputDecoration(
                                  labelText: 'Color',
                                  prefixIcon: Icon(Icons.color_lens_outlined),
                                  hintText: 'e.g. Silver',
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                validator: (v) => isDriver && (v == null || v.trim().isEmpty)
                                    ? 'Enter color'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isDriver ? AppTheme.accentColor : AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isDriver ? 'Register as Driver' : 'Sign Up as Passenger',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Or continue with', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(authControllerProvider.notifier).signInWithGoogle();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                        label: const Text('Google', style: TextStyle(color: Colors.black87)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(authControllerProvider.notifier).signInWithApple();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.apple, size: 26, color: Colors.black),
                        label: const Text('Apple', style: TextStyle(color: Colors.black87)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab({
    required String roleKey,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = roleKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (roleKey == 'driver' ? AppTheme.accentColor : AppTheme.primaryColor)
                  : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.grey.shade700 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
