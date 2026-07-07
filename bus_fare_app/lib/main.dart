import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const BusFareApp());
}

final supabase = Supabase.instance.client;

enum AppLanguage { english, sinhala, tamil }

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class RouteStopEntry {
  final int stopId;
  final int stageNumber;
  final String nameEn;
  final String nameSi;
  final String nameTa;

  RouteStopEntry({
    required this.stopId,
    required this.stageNumber,
    required this.nameEn,
    required this.nameSi,
    required this.nameTa,
  });

  String name(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return nameEn;
      case AppLanguage.sinhala:
        return nameSi;
      case AppLanguage.tamil:
        return nameTa;
    }
  }
}

class _HomePageState extends State<HomePage> {
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
    'selectRouteFirst': {
      AppLanguage.english: 'Select a route first',
      AppLanguage.sinhala: 'මුලින්ම මාර්ගයක් තෝරන්න',
      AppLanguage.tamil: 'முதலில் ஒரு பாதையைத் தேர்ந்தெடுக்கவும்',
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
    'fareNotFound': {
      AppLanguage.english: 'Fare not available for this stage difference yet',
      AppLanguage.sinhala: 'මෙම අදියර වෙනසට තවම ගාස්තුවක් නොමැත',
      AppLanguage.tamil: 'இந்த நிலை வேறுபாட்டிற்கு கட்டணம் இன்னும் இல்லை',
    },
  };

  String _t(String key, AppLanguage lang) => _text[key]?[lang] ?? key;

  AppLanguage _language = AppLanguage.english;

  List<Map<String, dynamic>> _routes = [];
  List<RouteStopEntry> _availableStops = [];

  int? _selectedRouteId;
  int? _selectedStartStopId;
  int? _selectedDestStopId;

  double? _calculatedFare;
  String? _fareError;

  bool _loadingRoutes = true;
  bool _loadingStops = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final data = await supabase
          .from('routes')
          .select()
          .order('route_number');
      setState(() {
        _routes = List<Map<String, dynamic>>.from(data);
        _loadingRoutes = false;
      });
    } catch (e) {
      setState(() {
        _loadingRoutes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading routes: $e')),
        );
      }
    }
  }

  Future<void> _loadStopsForRoute(int routeId) async {
    setState(() {
      _loadingStops = true;
      _availableStops = [];
      _selectedStartStopId = null;
      _selectedDestStopId = null;
      _calculatedFare = null;
      _fareError = null;
    });

    try {
      final data = await supabase
          .from('route_stops')
          .select('stop_id, stage_number, stops(name_en, name_si, name_ta)')
          .eq('route_id', routeId)
          .order('stage_number');

      final stops = (data as List).map((row) {
        final stopInfo = row['stops'] as Map<String, dynamic>;
        return RouteStopEntry(
          stopId: row['stop_id'],
          stageNumber: row['stage_number'],
          nameEn: stopInfo['name_en'] ?? '',
          nameSi: stopInfo['name_si'] ?? '',
          nameTa: stopInfo['name_ta'] ?? '',
        );
      }).toList();

      setState(() {
        _availableStops = stops;
        _loadingStops = false;
      });
    } catch (e) {
      setState(() {
        _loadingStops = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stops: $e')),
        );
      }
    }
  }

  Future<void> _onSubmit() async {
    if (_selectedRouteId == null ||
        _selectedStartStopId == null ||
        _selectedDestStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('selectAllError', _language))),
      );
      return;
    }

    if (_selectedStartStopId == _selectedDestStopId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('sameStopError', _language))),
      );
      return;
    }

    try {
      final startStop =
          _availableStops.firstWhere((s) => s.stopId == _selectedStartStopId);
      final destStop =
          _availableStops.firstWhere((s) => s.stopId == _selectedDestStopId);
      final stageDiff = (destStop.stageNumber - startStop.stageNumber).abs();

      final fareRows = await supabase
          .from('fare_stages')
          .select()
          .eq('stage_diff', stageDiff)
          .order('effective_date', ascending: false)
          .limit(1);

      if ((fareRows as List).isEmpty) {
        setState(() {
          _calculatedFare = null;
          _fareError = _t('fareNotFound', _language);
        });
        return;
      }

      setState(() {
        _calculatedFare = (fareRows.first['fare'] as num).toDouble();
        _fareError = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating fare: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeSelected = _selectedRouteId != null;

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
              setState(() => _language = value);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loadingRoutes
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedRouteId,
                    decoration: InputDecoration(
                      labelText: _t('busRoute', _language),
                      border: const OutlineInputBorder(),
                    ),
                    items: _routes.map((route) {
                      return DropdownMenuItem<int>(
                        value: route['id'] as int,
                        child: Text(route['route_number']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRouteId = value);
                      if (value != null) _loadStopsForRoute(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey('start-${_selectedRouteId ?? "none"}'),
                    initialValue: _selectedStartStopId,
                    decoration: InputDecoration(
                      labelText: routeSelected
                          ? _t('startingPoint', _language)
                          : _t('selectRouteFirst', _language),
                      border: const OutlineInputBorder(),
                    ),
                    items: _availableStops.map((stop) {
                      return DropdownMenuItem<int>(
                        value: stop.stopId,
                        child: Text(stop.name(_language)),
                      );
                    }).toList(),
                    onChanged: routeSelected && !_loadingStops
                        ? (value) {
                            setState(() {
                              _selectedStartStopId = value;
                              _calculatedFare = null;
                              _fareError = null;
                            });
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey('dest-${_selectedRouteId ?? "none"}'),
                    initialValue: _selectedDestStopId,
                    decoration: InputDecoration(
                      labelText: routeSelected
                          ? _t('destination', _language)
                          : _t('selectRouteFirst', _language),
                      border: const OutlineInputBorder(),
                    ),
                    items: _availableStops.map((stop) {
                      return DropdownMenuItem<int>(
                        value: stop.stopId,
                        child: Text(stop.name(_language)),
                      );
                    }).toList(),
                    onChanged: routeSelected && !_loadingStops
                        ? (value) {
                            setState(() {
                              _selectedDestStopId = value;
                              _calculatedFare = null;
                              _fareError = null;
                            });
                          }
                        : null,
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
                  if (_fareError != null)
                    Text(
                      _fareError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                ],
              ),
            ),
    );
  }
}