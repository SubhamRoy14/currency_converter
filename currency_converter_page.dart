import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage>
    with SingleTickerProviderStateMixin {
  double result = 0;
  final TextEditingController textEditingController = TextEditingController();
  final String fullName = 'Subham Roy';
  String displayedName = '';
  int index = 0;
  bool forward = true;
  int cycleCount = 0;
  final int maxCycles = 7;
  double conversionRate = 85.47; // Default rate for USD fallback
  bool usingDefaultRate = false;
  String selectedCurrency = 'USD'; // Default currency is USD
  final List<Color> rainbowColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
  ];
  late final AnimationController _rotationController;

  // Map of top 10 powerful currencies with their symbols and full names
  final Map<String, String> topCurrencies = {
    'EUR': '€ - Euro',
    'CHF': 'Fr - Swiss Franc',
    'GBP': '£ - British Pound',
    'USD': '\$ - US Dollar',
    'CAD': 'C\$ - Canadian Dollar',
    'AUD': 'A\$ - Australian Dollar',
    'JPY': '¥ - Japanese Yen',
    'CNY': '¥ - Chinese Yuan',
    'SEK': 'kr - Swedish Krona',
    'NZD': '\$ - New Zealand Dollar',
  };

  // Map to hold conversion rates fetched
  final Map<String, double> _conversionRates = {};

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _startNameAnimation();
    _fetchConversionRate(selectedCurrency); // Initial fetch for USD
  }

  @override
  void dispose() {
    _rotationController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  void _startNameAnimation() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (cycleCount >= maxCycles) {
          displayedName = fullName;
          timer.cancel();
          return;
        }
        if (forward) {
          index++;
          if (index > fullName.length) {
            forward = false;
            index = fullName.length - 1;
          }
        } else {
          index--;
          if (index < 0) {
            forward = true;
            index = 1;
            cycleCount++;
          }
        }
        displayedName = fullName.substring(0, index.clamp(0, fullName.length));
      });
    });
  }

  Future<void> _fetchConversionRate(String baseCurrency) async {
    final url = 'https://api.exchangerate-api.com/v4/latest/$baseCurrency';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'];
        setState(() {
          _conversionRates.clear();
          rates.forEach((key, value) {
            if (value is num) {
              _conversionRates[key] = value.toDouble();
            }
          });
          conversionRate =
              _conversionRates['INR'] ??
              (baseCurrency == 'EUR' ? 92.00 : 85.47);
          usingDefaultRate = false;
          selectedCurrency = baseCurrency;
        });
      } else {
        setState(() {
          usingDefaultRate = true;
          conversionRate = (baseCurrency == 'EUR') ? 92.00 : 85.47;
        });
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        usingDefaultRate = true;
        conversionRate = (baseCurrency == 'EUR') ? 92.00 : 85.47;
      });
      print('Error fetching data: $e');
    }
  }

  List<TextSpan> _buildColorfulName(String name) {
    List<TextSpan> spans = [];
    for (int i = 0; i < name.length; i++) {
      spans.add(
        TextSpan(
          text: name[i],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: rainbowColors[i % rainbowColors.length],
          ),
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    String fallbackRate = (selectedCurrency == 'EUR') ? '92.00' : '85.47';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(127, 181, 234, 1),
        leading: RotationTransition(
          turns: _rotationController,
          child: const Icon(Icons.currency_exchange),
        ),
        centerTitle: true,
        title: const Text('Currency Converter'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.black,
        ),
      ),
      body: ColoredBox(
        color: const Color.fromRGBO(0, 0, 0, 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Crafted by',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: RichText(
                text: TextSpan(children: _buildColorfulName(displayedName)),
              ),
            ),
            Center(
              child: Text(
                '₹ ${result.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: TextField(
                controller: textEditingController,
                style: const TextStyle(color: Color.fromARGB(220, 42, 154, 78)),
                decoration: InputDecoration(
                  label: Text(
                    'Enter the $selectedCurrency amount',
                    style: const TextStyle(
                      color: Color.fromRGBO(57, 102, 112, 1),
                    ),
                  ),
                  hintText: "Like: 20.3",
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: GestureDetector(
                    onLongPress: () {
                      _showCurrencyList(context);
                    },
                    child: Icon(
                      selectedCurrency == 'USD'
                          ? Icons.monetization_on_outlined
                          : Icons.euro_symbol,
                      color: const Color.fromRGBO(253, 232, 3, 1),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color.fromRGBO(77, 76, 77, 0.578),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(231, 248, 2, 1),
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(90)),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    final input = textEditingController.text;
                    if (input.isNotEmpty) {
                      final parsed = double.tryParse(input);
                      if (parsed != null) {
                        result = parsed * conversionRate;
                      }
                    }
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(97, 167, 238, 1),
                  backgroundColor: const Color.fromRGBO(248, 237, 38, 1),
                  fixedSize: const Size(200, 50),
                ),
                child: const Text('Convert'),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Current rate: 1 $selectedCurrency = ${conversionRate.toStringAsFixed(2)} INR',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Rate Date: 15-05-2025',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            if (usingDefaultRate)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Text(
                  'Note: Unable to fetch online rates. Using the default value ($fallbackRate) as of 15-05-2025, straight from Kolkata, India.',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: topCurrencies.length,
              itemBuilder: (context, index) {
                final currencyCode = topCurrencies.keys.elementAt(index);
                final currencyName = topCurrencies.values.elementAt(index);
                return ListTile(
                  title: Text(currencyName),
                  onTap: () {
                    setState(() {
                      selectedCurrency = currencyCode;
                      textEditingController.clear();
                      result = 0;
                      _fetchConversionRate(currencyCode);
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
