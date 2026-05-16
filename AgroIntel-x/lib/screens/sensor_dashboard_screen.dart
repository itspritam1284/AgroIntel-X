import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../services/thingspeak_service.dart';
import '../services/weather_service.dart';
import 'sensor_detail_screen.dart';
import 'crop_planning_screen.dart';
import 'plan_history_screen.dart';
import 'gemini_chatbot_screen.dart';
import 'market_price_screen.dart';
import '../services/translation_service.dart';


class SensorDashboardScreen extends StatefulWidget {
  const SensorDashboardScreen({super.key});

  @override
  State<SensorDashboardScreen> createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends State<SensorDashboardScreen>
    with TickerProviderStateMixin {
  final TranslationService _translator = TranslationService();
  final ThingSpeakService _service = ThingSpeakService();
  final WeatherService _weatherService = WeatherService();
  SensorData? _latestData;
  List<SensorData> _historicalData = [];
  WeatherData? _weatherData;
  List<ForecastDay> _forecastData = [];
  bool _isLoading = true;
  bool _isLoadingWeather = true;
  String? _error;
  Timer? _refreshTimer;
  Timer? _imageScrollTimer;
  Timer? _weatherRefreshTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;


  // Farming images from internet
  final List<String> _farmingImages = [
    'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800',
    'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800',
    'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=800',
    'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=800',
    'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
  ];

  @override
  void initState() {
    super.initState();
    // Set status bar to green to match header
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B5E20), // Deep green
        statusBarIconBrightness: Brightness.light, // Light icons
        statusBarBrightness: Brightness.dark, // For iOS
      ),
    );
    _loadData();
    _loadWeather();
    _startAutoRefresh();
    _startWeatherRefresh();
    _startImageAutoScroll();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _imageScrollTimer?.cancel();
    _weatherRefreshTimer?.cancel();
    _pageController.dispose();

    super.dispose();
  }



  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadData(showLoading: false);
    });
  }

  void _startImageAutoScroll() {
    _imageScrollTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _farmingImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final latest = await _service.getLatestData();
      final historical = await _service.getHistoricalData(results: 5);

      setState(() {
        _latestData = latest;
        _historicalData = historical;
        _isLoading = false;
        _error = null;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startWeatherRefresh() {
    _weatherRefreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _loadWeather();
    });
  }

  Future<void> _loadWeather() async {
    try {
      // Fetch current weather and 5-day forecast in parallel
      final results = await Future.wait([
        _weatherService.getWeather(),
        _weatherService.getForecast(),
      ]);

      final weather = results[0] as WeatherData?;
      final forecast = results[1] as List<ForecastDay>;

      if (mounted) {
        setState(() {
          _weatherData = weather;
          _forecastData = forecast;
          _isLoadingWeather = false;
        });

      }
    } catch (e) {
      print('Error loading weather: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent, // Transparent to show green header behind
        statusBarIconBrightness: Brightness.light, // Light icons
        statusBarBrightness: Brightness.dark, // For iOS
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F5DC),
        drawer: _buildNotificationDrawer(),
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: const Color(0xFF1B5E20),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body:
            _isLoading && _latestData == null
                ? _buildLoadingState()
                : _error != null && _latestData == null
                ? _buildErrorState()
                : _buildDashboard(),
      ),
    );
  }

  // ── Helper: build forecast-based weather alerts ──────────────────────────
  List<Map<String, dynamic>> _buildForecastAlerts() {
    final alerts = <Map<String, dynamic>>[];
    if (_forecastData.isEmpty) return alerts;

    // 1. Rain forecast
    final rainDays =
        _forecastData.where((d) {
          final m = d.weatherMain.toLowerCase();
          return m.contains('rain') ||
              m.contains('drizzle') ||
              m.contains('thunderstorm');
        }).toList();
    if (rainDays.isNotEmpty) {
      final dayNames = rainDays
          .map((d) => DateFormat('EEE').format(d.date))
          .take(3)
          .join(', ');
      alerts.add({
        'icon': Icons.umbrella,
        'title': 'Rain Expected',
        'message':
            'Rain forecast on $dayNames. Plan irrigation & protect crops accordingly.',
        'isActive': true,
        'color': Colors.blue.shade600,
      });
    }

    // 2. High wind alert
    final windyDays = _forecastData.where((d) => d.windSpeed > 8.0).toList();
    if (windyDays.isNotEmpty) {
      final dayNames = windyDays
          .map((d) => DateFormat('EEE').format(d.date))
          .take(3)
          .join(', ');
      alerts.add({
        'icon': Icons.air,
        'title': 'High Wind Warning',
        'message':
            'Wind speed above 8 m/s on $dayNames. Secure equipment & fragile plants.',
        'isActive': true,
        'color': Colors.teal.shade600,
      });
    }

    // 3. Thunderstorm
    final stormDays =
        _forecastData
            .where((d) => d.weatherMain.toLowerCase().contains('thunderstorm'))
            .toList();
    if (stormDays.isNotEmpty) {
      final dayNames = stormDays
          .map((d) => DateFormat('EEE').format(d.date))
          .take(3)
          .join(', ');
      alerts.add({
        'icon': Icons.bolt,
        'title': 'Thunderstorm Alert',
        'message':
            '⚡ Thunderstorm expected on $dayNames. Avoid outdoor farm work.',
        'isActive': true,
        'color': Colors.deepPurple.shade600,
      });
    }

    // 4. Hot days
    final hotDays = _forecastData.where((d) => d.tempMax > 38).toList();
    if (hotDays.isNotEmpty) {
      final dayNames = hotDays
          .map((d) => DateFormat('EEE').format(d.date))
          .take(3)
          .join(', ');
      alerts.add({
        'icon': Icons.thermostat,
        'title': 'Heat Alert',
        'message':
            'Temperature above 38°C on $dayNames. Increase irrigation & shade crops.',
        'isActive': true,
        'color': Colors.deepOrange.shade600,
      });
    }

    // 5. Clear / Good farming weather
    if (alerts.isEmpty) {
      alerts.add({
        'icon': Icons.wb_sunny,
        'title': 'Good Farming Weather',
        'message':
            'Next 5 days look clear and calm. Great time for planting & fieldwork!',
        'isActive': false,
        'color': Colors.green.shade600,
      });
    }

    return alerts;
  }

  Widget _buildNotificationDrawer() {
    final hasRain = _latestData?.isRaining ?? false;
    final hasMotion = _latestData?.hasMotion ?? false;
    final hasFlame = _latestData?.hasFlame ?? false;
    final forecastAlerts = _buildForecastAlerts();
    final activeForecastAlerts =
        forecastAlerts.where((a) => a['isActive'] == true).length;
    final totalAlerts =
        (hasRain ? 1 : 0) +
        (hasMotion ? 1 : 0) +
        (hasFlame ? 1 : 0) +
        activeForecastAlerts;

    return Drawer(
      backgroundColor: const Color(0xFFF8FBF8),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translator.translate('notifications'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$totalAlerts active alert${totalAlerts != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalAlerts > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$totalAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Alert list ──────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Section: Sensor Alerts ──────────────────────────────
                _buildSectionLabel('🌾 Farm Sensor Alerts'),
                const SizedBox(height: 8),
                _buildNotificationCard(
                  icon: Icons.water_drop,
                  title: _translator.translate('rain'),
                  message:
                      hasRain
                          ? 'Rain detected! Consider protecting crops.'
                          : 'No rain detected. Weather is clear.',
                  isActive: hasRain,
                  color: Colors.blue,
                  time: _latestData?.timestamp,
                ),
                const SizedBox(height: 10),
                _buildNotificationCard(
                  icon: Icons.sensors,
                  title: _translator.translate('motion'),
                  message:
                      hasMotion
                          ? 'Motion detected in the farm area!'
                          : 'No motion detected. Area is secure.',
                  isActive: hasMotion,
                  color: Colors.orange,
                  time: _latestData?.timestamp,
                ),
                const SizedBox(height: 10),
                _buildNotificationCard(
                  icon: Icons.local_fire_department,
                  title: _translator.translate('fire'),
                  message:
                      hasFlame
                          ? '🔥 URGENT: Fire detected! Take immediate action!'
                          : 'No fire detected. Farm is safe.',
                  isActive: hasFlame,
                  color: Colors.red,
                  time: _latestData?.timestamp,
                ),

                // ── Section: Weather Forecast Alerts ───────────────────
                const SizedBox(height: 20),
                _buildSectionLabel('🌤 5-Day Weather Forecast Alerts'),
                const SizedBox(height: 8),

                if (_isLoadingWeather && _forecastData.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading forecast...'),
                      ],
                    ),
                  )
                else
                  ...forecastAlerts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final a = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                      child: _buildNotificationCard(
                        icon: a['icon'] as IconData,
                        title: a['title'] as String,
                        message: a['message'] as String,
                        isActive: a['isActive'] as bool,
                        color: a['color'] as Color,
                        time: null,
                      ),
                    );
                  }),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String message,
    required bool isActive,
    required Color color,
    DateTime? time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isActive ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isActive ? color : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (time != null)
                      Text(
                        DateFormat('hh:mm a').format(time.toLocal()),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B5E20).withOpacity(0.1),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _translator.translate('loading'),
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to Load Data',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_latestData == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoading: false),
      color: const Color(0xFF1B5E20),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildImageSlider(),
                const SizedBox(height: 20),
                // Weather and Sensor Data Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Weather Card - Now displayed BEFORE sensor data
                      _buildWeatherCard(),
                      const SizedBox(height: 20),
                      // Sensor Section Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.sensors_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                           Text(
                            _translator.translate('field_sensors'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 8),
                      // Sensor Grid - Now displayed AFTER weather data
                      _buildSensorGrid(),
                      const SizedBox(height: 24),
                      _buildAIFarmingSection(),
                      const SizedBox(height: 24),
                      _buildLastUpdated(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Add safe area top padding + original padding
    final topPadding = MediaQuery.of(context).padding.top + 20;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _translator.translate('app_title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'EEEE, dd MMM yyyy',
                              ).format(DateTime.now()),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Notification Button with badge
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      // Badge: count sensor alerts + active forecast alerts
                      Builder(
                        builder: (context) {
                          final sensorCount =
                              (_latestData?.isRaining == true ? 1 : 0) +
                              (_latestData?.hasMotion == true ? 1 : 0) +
                              (_latestData?.hasFlame == true ? 1 : 0);
                          final forecastCount =
                              _buildForecastAlerts()
                                  .where((a) => a['isActive'] == true)
                                  .length;
                          final total = sensorCount + forecastCount;
                          if (total == 0) return const SizedBox.shrink();
                          return Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '$total',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Language Selection Button
                GestureDetector(
                  onTap: _showLanguageDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusChip('Live', Colors.green.shade300),
                const SizedBox(width: 8),
                _buildStatusChip('Auto-refresh: 2s', Colors.white70),
                const SizedBox(width: 8),
                // Mode Switcher Button (moved here, smaller)
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/rower');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rower',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(_translator.translate('language')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TranslationService.languages.length,
              itemBuilder: (context, index) {
                final lang = TranslationService.languages[index];
                final isSelected = _translator.currentLanguage.value == lang['code'];
                return ListTile(
                  leading: Text(
                    isSelected ? '✅' : '🌐',
                    style: const TextStyle(fontSize: 18),
                  ),
                  title: Text(lang['native']!),
                  subtitle: Text(lang['name']!),
                  onTap: () {
                    _translator.changeLanguage(lang['code']!);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'Live')
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _farmingImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _farmingImages[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(
          controller: _pageController,
          count: _farmingImages.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: const Color(0xFF1B5E20),
            dotColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    if (_isLoadingWeather && _weatherData == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
            ),
          ),
        ),
      );
    }

    if (_weatherData == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Weather unavailable',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      );
    }

    final weather = _weatherData!;
    final sunriseTime = DateFormat(
      'h:mm a',
    ).format(weather.sunriseTime.toLocal());
    final sunsetTime = DateFormat(
      'h:mm a',
    ).format(weather.sunsetTime.toLocal());

    // Compute sunrise-sunset arc progress (0.0 → 1.0)
    final now = DateTime.now();
    final totalDaySeconds =
        weather.sunsetTime.difference(weather.sunriseTime).inSeconds.toDouble();
    final elapsedSeconds = now
        .difference(weather.sunriseTime)
        .inSeconds
        .toDouble()
        .clamp(0.0, totalDaySeconds);
    final sunProgress =
        totalDaySeconds > 0 ? elapsedSeconds / totalDaySeconds : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main Weather Card ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Location + H/L + Icon ─────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${weather.cityName}, ${weather.country}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Temperature
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weather.temperature.round()}',
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                                height: 1.0,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                '°C',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // H/L + Icon column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'H: ${weather.tempMax.round()}°C',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'L: ${weather.tempMin.round()}°C',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Image.network(
                        weather.getWeatherIconUrl(),
                        width: 70,
                        height: 70,
                        errorBuilder:
                            (_, __, ___) => Icon(
                              Icons.wb_cloudy_outlined,
                              size: 70,
                              color: Colors.grey.shade400,
                            ),
                      ),
                      Text(
                        weather.weatherDescription
                            .split(' ')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' '),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Divider(color: Colors.grey.shade200, thickness: 1),
              const SizedBox(height: 14),

              // ── Row 2: Humidity | Pressure | Wind ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherStat(
                    'Humidity',
                    '${weather.humidity}%',
                    Icons.water_drop_outlined,
                    Colors.blue.shade400,
                  ),
                  Container(width: 1, height: 44, color: Colors.grey.shade200),
                  _buildWeatherStat(
                    'Pressure',
                    '${weather.pressure}',
                    Icons.speed_outlined,
                    Colors.purple.shade400,
                    subtitle: 'hPa',
                  ),
                  Container(width: 1, height: 44, color: Colors.grey.shade200),
                  _buildWeatherStat(
                    'Wind',
                    '${weather.windSpeed.toStringAsFixed(1)}',
                    Icons.air,
                    Colors.teal.shade400,
                    subtitle: 'm/s',
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Divider(color: Colors.grey.shade200, thickness: 1),
              const SizedBox(height: 14),

              // ── Row 3: Sunrise Arc + Sunset ───────────────────────────
              _buildSunriseSunsetRow(
                sunriseTime: sunriseTime,
                sunsetTime: sunsetTime,
                progress: sunProgress,
              ),
            ],
          ),
        ),

        // ── 5-Day Forecast Strip ──────────────────────────────────────────
        if (_forecastData.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildForecastStrip(),
        ],
      ],
    );
  }

  Widget _buildWeatherStat(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    String? subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
      ],
    );
  }

  Widget _buildSunriseSunsetRow({
    required String sunriseTime,
    required String sunsetTime,
    required double progress,
  }) {
    return Column(
      children: [
        // Arc painter
        SizedBox(
          height: 56,
          child: CustomPaint(
            painter: _SunArcPainter(progress: progress),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sunrise
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sunriseTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Sunrise',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Sunset
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sunsetTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Sunset',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.wb_twilight,
                    size: 18,
                    color: Colors.indigo.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForecastStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '5-Day Forecast',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170, // Increased height to fix overflow and allow more info
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _forecastData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final day = _forecastData[index];
              final dayName = DateFormat('EEE').format(day.date);
              final dateStr = DateFormat('dd MMM').format(day.date);

              // Premium card design
              return Container(
                width: 110, // Slightly wider for better layout
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF1B5E20).withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date Section
                    Column(
                      children: [
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B5E20),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    // Icon Section with subtle glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Image.network(
                          day.getIconUrl(),
                          width: 42,
                          height: 42,
                          errorBuilder:
                              (_, __, ___) => Icon(
                                Icons.wb_cloudy_outlined,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                        ),
                      ],
                    ),

                    // Temperature Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${day.tempMax.round()}°',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${day.tempMin.round()}°',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),

                    // Extra info row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 10,
                              color: Colors.blue.withOpacity(0.6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${day.humidity}%',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.air,
                              size: 10,
                              color: Colors.teal.withOpacity(0.6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${day.windSpeed.round()}m/s',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSensorGrid() {
    final data = _latestData!;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        ModernSensorCard(
          title: 'Temperature',
          value: data.temperature.toStringAsFixed(1),
          unit: '°C',
          status: data.getTemperatureStatus(),
          icon: Icons.thermostat,
          color: const Color(0xFFFF6B6B),
          statusColor: _getTemperatureColor(data.temperature),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SensorDetailScreen(
                      sensorName: 'Temperature',
                      sensorUnit: '°C',
                      sensorIcon: Icons.thermostat,
                      sensorColor: const Color(0xFFFF6B6B),
                      getValue: (data) => data.temperature,
                      historicalData: _historicalData,
                    ),
              ),
            );
          },
        ),
        ModernSensorCard(
          title: 'Humidity',
          value: data.humidity.toStringAsFixed(1),
          unit: '%',
          status: data.getHumidityStatus(),
          icon: Icons.water_drop,
          color: const Color(0xFF4ECDC4),
          statusColor: _getHumidityColor(data.humidity),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SensorDetailScreen(
                      sensorName: 'Humidity',
                      sensorUnit: '%',
                      sensorIcon: Icons.water_drop,
                      sensorColor: const Color(0xFF4ECDC4),
                      getValue: (data) => data.humidity,
                      historicalData: _historicalData,
                    ),
              ),
            );
          },
        ),
        ModernSensorCard(
          title: 'Soil Moisture',
          value: data.soilMoisture.toString(),
          unit: '',
          status: data.getSoilMoistureStatus(),
          icon: Icons.grass,
          color: const Color(0xFF95E1D3),
          statusColor: _getSoilMoistureColor(data.soilMoisture),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SensorDetailScreen(
                      sensorName: 'Soil Moisture',
                      sensorUnit: '',
                      sensorIcon: Icons.grass,
                      sensorColor: const Color(0xFF95E1D3),
                      getValue: (data) => data.soilMoisture.toDouble(),
                      historicalData: _historicalData,
                    ),
              ),
            );
          },
        ),
        ModernSensorCard(
          title: 'Rain Sensor',
          value: data.rain.toString(),
          unit: '',
          status: data.isRaining ? 'Raining' : 'Dry',
          icon: Icons.umbrella,
          color: const Color(0xFF6C5CE7),
          statusColor: data.isRaining ? Colors.blue : Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SensorDetailScreen(
                      sensorName: 'Rain Sensor',
                      sensorUnit: '',
                      sensorIcon: Icons.umbrella,
                      sensorColor: const Color(0xFF6C5CE7),
                      getValue: (data) => data.rain.toDouble(),
                      historicalData: _historicalData,
                    ),
              ),
            );
          },
        ),
        ModernSensorCard(
          title: 'Light Level',
          value: data.lux.toString(),
          unit: 'lux',
          status: data.isDaylight ? 'Day' : 'Night',
          icon: data.isDaylight ? Icons.wb_sunny : Icons.nightlight_round,
          color: const Color(0xFFFFC107),
          statusColor: data.isDaylight ? Colors.yellow : Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SensorDetailScreen(
                      sensorName: 'Light Level',
                      sensorUnit: 'lux',
                      sensorIcon: Icons.wb_sunny,
                      sensorColor: const Color(0xFFFFC107),
                      getValue: (data) => data.lux.toDouble(),
                      historicalData: _historicalData,
                    ),
              ),
            );
          },
        ),
        ModernSensorCard(
          title: 'Motion Sensor',
          value: data.motion.toString(),
          unit: '',
          status: data.hasMotion ? 'Detected' : 'No Motion',
          icon: Icons.sensors,
          color: const Color(0xFFFF9800),
          statusColor: data.hasMotion ? Colors.red : Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SensorDetailScreen(
                      sensorName: 'Motion Sensor',
                      sensorUnit: '',
                      sensorIcon: Icons.sensors,
                      sensorColor: const Color(0xFFFF9800),
                      getValue: (data) => data.motion.toDouble(),
                      historicalData: _historicalData,
                    ),
              ),
            );
          },
        ),
        ModernSensorCard(
          title: 'Flame Sensor',
          value: data.flame.toString(),
          unit: '',
          status: data.hasFlame ? 'Fire!' : 'Safe',
          icon: Icons.local_fire_department,
          color: const Color(0xFFF44336),
          statusColor: data.hasFlame ? Colors.red : Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SensorDetailScreen(
                      sensorName: 'Flame Sensor',
                      sensorUnit: '',
                      sensorIcon: Icons.local_fire_department,
                      sensorColor: const Color(0xFFF44336),
                      getValue: (data) => data.flame.toDouble(),
                      historicalData: _historicalData,
                    ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLastUpdated() {
    if (_latestData == null) return const SizedBox();

    final formatter = DateFormat('MMM dd, yyyy • hh:mm:ss a');
    final timeStr = formatter.format(_latestData!.timestamp.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 8),
          Text(
            'Last updated: $timeStr',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp < 25) return Colors.green;
    if (temp < 35) return Colors.orange;
    return Colors.red;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.orange;
    if (humidity < 60) return Colors.green;
    if (humidity < 80) return Colors.blue;
    return Colors.purple;
  }

  Color _getSoilMoistureColor(int moisture) {
    if (moisture < 100) return Colors.red;
    if (moisture < 200) return Colors.orange;
    if (moisture < 400) return Colors.green;
    if (moisture < 600) return Colors.blue;
    return Colors.purple;
  }

  Widget _buildAIFarmingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Farming Assistant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
        // AI Suggest Button
        GestureDetector(
          onTap: () {
            if (_latestData != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CropPlanningScreen(sensorData: _latestData!),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                  Color(0xFF388E3C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Suggest for Your Farm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get personalized crop recommendations',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // View Past Plans Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PlanHistoryScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1B5E20).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B5E20).withOpacity(0.15),
                        const Color(0xFF2E7D32).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Color(0xFF1B5E20),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'View Past Plans',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review your farming plan history',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF1B5E20),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // AI Chatbot Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GeminiChatbotScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chat with AI Assistant',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ask questions about farming',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Market Price Button ────────────────────────────────────────
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MarketPriceScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade50, Colors.green.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade400, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.orange.shade500],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('🌾', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translator.translate('check_prices'),
                        style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live mandi prices • Onion, Wheat & more',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Modern Sensor Card Widget
class ModernSensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String status;
  final IconData icon;
  final Color color;
  final Color statusColor;
  final VoidCallback? onTap;

  const ModernSensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.color,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    TranslationService().translate(status.toLowerCase()),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              TranslationService().translate(title.toLowerCase().replaceAll(' ', '_')),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sun Arc Painter ─────────────────────────────────────────────────────────

class _SunArcPainter extends CustomPainter {
  final double progress; // 0.0 = sunrise, 1.0 = sunset

  const _SunArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Dashed arc track
    final trackPaint =
        Paint()
          ..color = const Color(0xFFE0E0E0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // Draw dashed arc
    final dashPath =
        Path()..addArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi, // start = left (sunrise)
          math.pi, // sweep = full semicircle to right (sunset)
        );
    _drawDashedPath(canvas, dashPath, trackPaint, 6, 4);

    // Progress arc (filled portion)
    final progressPaint =
        Paint()
          ..color = Colors.orange.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi,
      math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );

    // Sun dot position
    final angle = -math.pi + math.pi * progress.clamp(0.0, 1.0);
    final sunX = center.dx + radius * math.cos(angle);
    final sunY = center.dy + radius * math.sin(angle);
    final sunOffset = Offset(sunX, sunY);

    // Glow
    final glowPaint =
        Paint()
          ..color = Colors.orange.withOpacity(0.25)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(sunOffset, 10, glowPaint);

    // Sun circle
    final sunPaint =
        Paint()
          ..color = Colors.orange.shade600
          ..style = PaintingStyle.fill;
    canvas.drawCircle(sunOffset, 6, sunPaint);

    // White centre dot
    canvas.drawCircle(sunOffset, 2.5, Paint()..color = Colors.white);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashLen,
    double gapLen,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final start = dist;
        final end = (dist + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_SunArcPainter old) => old.progress != progress;
}
