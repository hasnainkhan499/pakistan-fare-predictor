import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FareApi {
  static const String baseUrl = 'https://your-app.onrender.com';

  static Future<double> predictFare({
    required double distanceKm,
    required String timeOfDay,
    required String routeType,
    required int passengers,
  }) async {
    final uri = Uri.parse('$baseUrl/predict');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'distance_km': distanceKm,
              'time_of_day': timeOfDay,
              'route_type': routeType,
              'passengers': passengers,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final fare = data['predicted_fare_pkr'];
        if (fare is num) return fare.toDouble();
        throw const FormatException('Invalid response: predicted_fare_pkr missing');
      } else {
        final Map<String, dynamic> err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Request failed (${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to predict fare: $e');
    }
  }
}

class FarePredictionScreen extends StatefulWidget {
  const FarePredictionScreen({super.key});

  @override
  State<FarePredictionScreen> createState() => _FarePredictionScreenState();
}

class _FarePredictionScreenState extends State<FarePredictionScreen> {
  final _distanceCtrl = TextEditingController(text: '10');
  final _passengersCtrl = TextEditingController(text: '1');
  String _timeOfDay = 'morning';
  String _routeType = 'city';
  bool _loading = false;
  double? _fare;
  String? _error;

  Future<void> _onPredict() async {
    setState(() {
      _loading = true;
      _error = null;
      _fare = null;
    });
    try {
      final fare = await FareApi.predictFare(
        distanceKm: double.parse(_distanceCtrl.text),
        timeOfDay: _timeOfDay,
        routeType: _routeType,
        passengers: int.parse(_passengersCtrl.text),
      );
      setState(() => _fare = fare);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _passengersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pakistan Fare Prediction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _distanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Distance (km)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passengersCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Passengers'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _timeOfDay,
              decoration: const InputDecoration(labelText: 'Time of Day'),
              items: const ['morning', 'afternoon', 'evening', 'night']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _timeOfDay = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _routeType,
              decoration: const InputDecoration(labelText: 'Route Type'),
              items: const ['city', 'intercity', 'highway']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _routeType = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _onPredict,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Predict Fare'),
            ),
            const SizedBox(height: 20),
            if (_fare != null)
              Text('Predicted Fare: PKR ${_fare!.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
