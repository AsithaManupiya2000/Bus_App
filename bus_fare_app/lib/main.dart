import 'package:flutter/material.dart';

void main() {
  runApp(const BusFareApp());
}

class BusFareApp extends StatelessWidget {
  const BusFareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Fare Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

enum AppLanguage { english, sinhala, tamil }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Stop "keys" - stable IDs that never change, used internally for lookups.
  final List<String> _stopKeys = [
    'colombo',
    'kandy',
    'galle',
    'jaffna',
    'kurunegala',
    'kaduwela',
  ];

  // Translated display names for each stop.
  final Map<String, Map<AppLanguage, String>> _stopNames = {
    'colombo': {
      AppLanguage.english: 'Colombo',
      AppLanguage.sinhala: 'කොළඹ',
      AppLanguage.tamil: 'கொழும்பு',
    },
    'kandy': {
      AppLanguage.english: 'Kandy',
      AppLanguage.sinhala: 'මහනුවර',
      AppLanguage.tamil: 'கண்டி',
    },
    'galle': {
      AppLanguage.english: 'Galle',
      AppLanguage.sinhala: 'ගාල්ල',
      AppLanguage.tamil: 'காலி',
    },
    'jaffna': {
      AppLanguage.english: 'Jaffna',
      AppLanguage.sinhala: 'යාපනය',
      AppLanguage.tamil: 'யாழ்ப்பாணம்',
    },
    'kurunegala': {
      AppLanguage.english: 'Kurunegala',
      AppLanguage.sinhala: 'කුරුණෑගල',
      AppLanguage.tamil: 'குருநாகல்',
    },
    'kaduwela': {
      AppLanguage.english: 'Kaduwela',
      AppLanguage.sinhala: 'කඩුවෙල',
      AppLanguage.tamil: 'கடுவெல',
    },
  };

  // Route keys, each pairs a route number with a start/end stop key.
  final List<Map<String, String>> _routeDefs = [
    {'number': '01', 'from': 'colombo', 'to': 'kandy'},
    {'number': '02', 'from': 'colombo', 'to': 'galle'},
    {'number': '04', 'from': 'colombo', 'to': 'jaffna'},
    {'number': '15', 'from': 'colombo', 'to': 'kurunegala'},
    {'number': '87', 'from': 'colombo', 'to': 'kaduwela'},
  ];

  final Map<String, double> _distanceFromColombo = {
    'colombo': 0,
    'kandy': 115,
    'galle': 119,
    'jaffna': 396,
    'kurunegala': 94,
    'kaduwela': 16,
  };

  final Map<String, Map<AppLanguage, String>> _text = {
    'appTitle': {
      AppLanguage.english: 'Bus Fare Finder',
      AppLanguage.sinhala: 'බස් ගාස්තු සොයන්නා',
      AppLanguage.tamil: 'பேருந்து கட்டண கண்டுபிடிப்பான்',
    },
    'busRoute': {
      AppLanguage.english: 'Bus Route',
      AppLanguage.sinhala: 'බස් මාර්ගය',
      AppLanguage.tamil: 'பேருந்து பாதை',
    },
    'startingPoint': {
      AppLanguage.english: 'Starting Point',
      AppLanguage.sinhala: 'ආරම්භක ස්ථානය',
      AppLanguage.tamil: 'தொடக்க இடம்',
    },
    'destination': {
      AppLanguage.english: 'Destination',
      AppLanguage.sinhala: 'ගමනාන්තය',
      AppLanguage.tamil: 'சேருமிடம்',
    },
    'submit': {
      AppLanguage.english: 'Submit',
      AppLanguage.sinhala: 'ඉදිරිපත් කරන්න',
      AppLanguage.tamil: 'சமர்ப்பிக்கவும்',
    },
    'estimatedFare': {
      AppLanguage.english: 'Estimated Fare',
      AppLanguage.sinhala: 'ඇස්තමේන්තුගත ගාස්තුව',
      AppLanguage.tamil: 'மதிப்பிடப்பட்ட கட்டணம்',
    },
    'selectAllError': {
      AppLanguage.english: 'Please select all three options',
      AppLanguage.sinhala: 'කරුණාකර සියලුම විකල්ප තුන තෝරන්න',
      AppLanguage.tamil: 'மூன்று விருப்பங்களையும் தேர்ந்தெடுக்கவும்',
    },
    'sameStopError': {
      AppLanguage.english: 'Starting point and destination cannot be the same',
      AppLanguage.sinhala: 'ආරම්භක ස්ථානය සහ ගමනාන්තය සමාන විය නොහැක',
      AppLanguage.tamil: 'தொடக்க இடமும் சேருமிடமும் ஒரே இடமாக இருக்க முடியாது',
    },
  };

  String _t(String key, AppLanguage lang) => _text[key]?[lang] ?? key;
  String _stopName(String stopKey, AppLanguage lang) =>
      _stopNames[stopKey]?[lang] ?? stopKey;

  // Builds a display label for a route, e.g. "01 - Colombo - Kandy",
  // using translated stop names for the current language.
  String _routeLabel(Map<String, String> route, AppLanguage lang) {
    final from = _stopName(route['from']!, lang);
    final to = _stopName(route['to']!, lang);
    return '${route['number']} - $from - $to';
  }

  AppLanguage _language = AppLanguage.english;
  String? _selectedRouteNumber;
  String? _selectedStartKey;
  String? _selectedDestinationKey;
  double? _calculatedFare;

  double _calculateFare(String startKey, String destinationKey) {
    final startDist = _distanceFromColombo[startKey] ?? 0;
    final destDist = _distanceFromColombo[destinationKey] ?? 0;
    final distanceKm = (destDist - startDist).abs();

    const baseFare = 15.0;
    const ratePerKm = 4.20;

    return baseFare + (distanceKm * ratePerKm);
  }

  void _onSubmit() {
    if (_selectedRouteNumber == null ||
        _selectedStartKey == null ||
        _selectedDestinationKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('selectAllError', _language))),
      );
      return;
    }

    if (_selectedStartKey == _selectedDestinationKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('sameStopError', _language))),
      );
      return;
    }

    setState(() {
      _calculatedFare =
          _calculateFare(_selectedStartKey!, _selectedDestinationKey!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('appTitle', _language)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          DropdownButton<AppLanguage>(
            value: _language,
            dropdownColor: Theme.of(context).colorScheme.primary,
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.language,
                color: Theme.of(context).colorScheme.onPrimary),
            items: const [
              DropdownMenuItem(
                value: AppLanguage.english,
                child: Text('EN', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: AppLanguage.sinhala,
                child: Text('සිං', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: AppLanguage.tamil,
                child: Text('தமி', style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _language = value;
              });
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedRouteNumber,
              decoration: InputDecoration(
                labelText: _t('busRoute', _language),
                border: const OutlineInputBorder(),
              ),
              items: _routeDefs.map((route) {
                return DropdownMenuItem(
                  value: route['number'],
                  child: Text(_routeLabel(route, _language)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRouteNumber = value;
                  _calculatedFare = null;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStartKey,
              decoration: InputDecoration(
                labelText: _t('startingPoint', _language),
                border: const OutlineInputBorder(),
              ),
              items: _stopKeys.map((stopKey) {
                return DropdownMenuItem(
                  value: stopKey,
                  child: Text(_stopName(stopKey, _language)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStartKey = value;
                  _calculatedFare = null;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedDestinationKey,
              decoration: InputDecoration(
                labelText: _t('destination', _language),
                border: const OutlineInputBorder(),
              ),
              items: _stopKeys.map((stopKey) {
                return DropdownMenuItem(
                  value: stopKey,
                  child: Text(_stopName(stopKey, _language)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDestinationKey = value;
                  _calculatedFare = null;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onSubmit,
                child: Text(_t('submit', _language)),
              ),
            ),
            const SizedBox(height: 24),
            if (_calculatedFare != null)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _t('estimatedFare', _language),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${_calculatedFare!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}