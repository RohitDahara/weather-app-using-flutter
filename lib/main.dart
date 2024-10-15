import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  TextEditingController _cityController = TextEditingController();
  String _cityName = '';
  String _description = '';
  String _temperature = '';
  String _humidity = '';
  String _feelsLike = '';
  String _errorMessage = '';
  String _windSpeed = '';
  List<String> _dailyForecast = [];
  bool _loading = false;

  String _apiKey = '9a49d58923a8ad1d7d669189f283a559'; // Replace with your API key

  Future<void> _fetchWeatherByCity(String city) async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cityName = data['name'];
        _description = data['weather'][0]['description'];
        _temperature = '${(data['main']['temp'] - 273.15).toStringAsFixed(1)}°C';
        _feelsLike = 'Feels like: ${(data['main']['feels_like'] - 273.15).toStringAsFixed(1)}°C';
        _humidity = 'Humidity: ${data['main']['humidity']}%';
        _windSpeed = 'Wind Speed: ${data['wind']['speed']} m/s';

        // Get latitude and longitude
        double lat = data['coord']['lat'];
        double lon = data['coord']['lon'];

        // Fetch forecast using lat/lon
        await _fetchForecast(lat, lon);
      } else {
        setState(() {
          _errorMessage = 'Error fetching weather data: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching weather data';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchForecast(double lat, double lon) async {
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey';

    try {
      final response = await http.get(Uri.parse(forecastUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('list')) {
          final List<dynamic> forecasts = data['list'];
          List<String> dailyForecast = [];

          for (var forecast in forecasts.take(3)) {
            String time = forecast['dt_txt'].split(' ')[0];
            double temp = forecast['main']['temp'] - 273.15;
            String description = forecast['weather'][0]['description'];
            dailyForecast.add('$time: ${temp.toStringAsFixed(1)}°C, $description');
          }

          setState(() {
            _dailyForecast = dailyForecast;
          });
        } else {
          setState(() {
            _errorMessage = 'Daily forecast not found in response';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error fetching forecast data: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching forecast data';
      });
    }
  }

  LinearGradient _getWeatherBackground(String description) {
    if (description.contains('clear')) {
      return LinearGradient(
        colors: [Colors.lightBlueAccent, Colors.blue],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (description.contains('cloud')) {
      return LinearGradient(
        colors: [Colors.grey.shade300, Colors.grey.shade800],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (description.contains('rain')) {
      return LinearGradient(
        colors: [Colors.blue.shade800, Colors.black],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (description.contains('snow')) {
      return LinearGradient(
        colors: [Colors.white, Colors.grey.shade300],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (description.contains('thunderstorm')) {
      return LinearGradient(
        colors: [Colors.deepPurple, Colors.black87],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (description.contains('fog')) {
      return LinearGradient(
        colors: [Colors.grey.shade200, Colors.grey.shade600],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return LinearGradient(
        colors: [Colors.grey.shade700, Colors.black],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _getWeatherBackground(_description),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Center( // Center widget to center-align the content
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center, // Center align horizontally
            children: [
              SizedBox(height: 20),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: 'Enter city name',
                  hintStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10), // Added space between text field and button
              ElevatedButton(
                onPressed: () async {
                  final city = _cityController.text;
                  await _fetchWeatherByCity(city);
                },
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (_cityName.isNotEmpty)
                Text(
                  _cityName,
                  style: TextStyle(fontSize: 32, color: Colors.white),
                  textAlign: TextAlign.center, // Center align city name
                ),
              if (_description.isNotEmpty)
                Text(
                  _description,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center, // Center align description
                ),
              if (_temperature.isNotEmpty)
                Text(
                  _temperature,
                  style: TextStyle(fontSize: 64, color: Colors.white),
                  textAlign: TextAlign.center, // Center align temperature
                ),
              if (_feelsLike.isNotEmpty)
                Text(
                  _feelsLike,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center, // Center align feels like
                ),
              if (_humidity.isNotEmpty)
                Text(
                  _humidity,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center, // Center align humidity
                ),
              if (_windSpeed.isNotEmpty)
                Text(
                  _windSpeed,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center, // Center align wind speed
                ),
              SizedBox(height: 20),
              if (_dailyForecast.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _dailyForecast.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 10.0),
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _dailyForecast[index],
                          style: TextStyle(fontSize: 18, color: Colors.black),
                          textAlign: TextAlign.center, // Center align forecast data
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
