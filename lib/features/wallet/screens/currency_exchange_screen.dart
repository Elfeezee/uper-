import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CurrencyExchangeScreen extends StatefulWidget {
  const CurrencyExchangeScreen({super.key});

  @override
  State<CurrencyExchangeScreen> createState() => _CurrencyExchangeScreenState();
}

class _CurrencyExchangeScreenState extends State<CurrencyExchangeScreen> {
  final TextEditingController _amountController = TextEditingController();
  
  String _fromCurrency = 'NGN';
  String _toCurrency = 'USD';

  final Map<String, double> _mockRates = {
    'NGN_USD': 0.00062, // Mock exchange rate: 1 NGN = 0.00062 USD
    'NGN_GBP': 0.00049,
    'USD_NGN': 1610.50,
    'GBP_NGN': 2040.30,
  };

  double _convertedAmount = 0.0;

  void _calculateConversion(String val) {
    if (val.isEmpty) {
      setState(() => _convertedAmount = 0.0);
      return;
    }
    double amount = double.tryParse(val) ?? 0.0;
    String rateKey = '${_fromCurrency}_$_toCurrency';
    
    // Fallback logic for mock purposes
    double rate = _mockRates[rateKey] ?? 1.0;
    
    setState(() {
      _convertedAmount = amount * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Currency'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Convert Your Balance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Exchange your money seamlessly within the app.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              // FROM Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _fromCurrency,
                      underline: const SizedBox(),
                      items: ['NGN', 'USD', 'GBP'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _fromCurrency = val!;
                          _calculateConversion(_amountController.text);
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
                        ),
                        onChanged: _calculateConversion,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Icon(Icons.swap_vert, size: 32, color: AppTheme.primaryColor),
                ),
              ),
              
              // TO Output
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _toCurrency,
                      underline: const SizedBox(),
                      items: ['NGN', 'USD', 'GBP'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _toCurrency = val!;
                          _calculateConversion(_amountController.text);
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _convertedAmount.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Converted $_fromCurrency to $_toCurrency successfully!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Confirm Exchange'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
