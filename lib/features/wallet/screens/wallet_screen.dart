import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/wallet_service.dart';
import '../../../shared/models/wallet_transaction_model.dart';
import 'currency_exchange_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final WalletService _walletService = WalletService();
  final String _currentCurrency = '₦'; // NGN

  Future<void> _handleTopUp(String userId) async {
    final amountCtrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter amount',
            prefixText: '₦ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountCtrl.text);
              Navigator.pop(context, val);
            },
            child: const Text('Top Up'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0) {
      try {
        await _walletService.topUp(userId, amount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully added ₦${amount.toStringAsFixed(2)}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleWithdraw(String userId, double currentBalance) async {
    final amountCtrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter amount (Max: ₦${currentBalance.toStringAsFixed(2)})',
            prefixText: '₦ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountCtrl.text);
              Navigator.pop(context, val);
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0) {
      try {
        await _walletService.withdraw(userId, amount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully withdrew ₦${amount.toStringAsFixed(2)}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your wallet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<double>(
                stream: _walletService.watchBalance(user.uid),
                builder: (context, snapshot) {
                  final balance = snapshot.data ?? 0.0;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF00E676)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentCurrency ${NumberFormat('#,##0.00').format(balance)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildWalletAction(
                              context,
                              icon: Icons.add_circle_outline,
                              label: 'Top Up',
                              onTap: () => _handleTopUp(user.uid),
                            ),
                            _buildWalletAction(
                              context,
                              icon: Icons.arrow_upward,
                              label: 'Withdraw',
                              onTap: () => _handleWithdraw(user.uid, balance),
                            ),
                            _buildWalletAction(
                              context,
                              icon: Icons.currency_exchange,
                              label: 'Exchange',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CurrencyExchangeScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ).animate().fade(duration: 500.ms).scale(curve: Curves.easeOutBack, duration: 600.ms);
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<WalletTransactionModel>>(
                stream: _walletService.watchTransactions(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final transactions = snapshot.data ?? [];
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No recent transactions.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: transactions.map((tx) {
                      final isNegative = tx.type == TransactionType.withdrawal ||
                          tx.type == TransactionType.ridePayment;
                      final sign = isNegative ? '-' : '+';
                      final dateFormat = DateFormat('MMM dd, hh:mm a');
                      return _buildTransactionItem(
                        title: tx.description,
                        date: dateFormat.format(tx.createdAt),
                        amount: '$sign${tx.currency} ${NumberFormat('#,##0.00').format(tx.amount)}',
                        isNegative: isNegative,
                      );
                    }).toList()
                    .animate(interval: 100.ms)
                    .fade(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({required String title, required String date, required String amount, required bool isNegative}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isNegative ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
          child: Icon(
            isNegative ? Icons.directions_car : Icons.account_balance_wallet,
            color: isNegative ? Colors.red : Colors.green,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.red : Colors.green,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
