import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../services/translation_service.dart';

class RowerControlScreen extends StatefulWidget {
  const RowerControlScreen({super.key});

  @override
  State<RowerControlScreen> createState() => _RowerControlScreenState();
}

class _RowerControlScreenState extends State<RowerControlScreen>
    with TickerProviderStateMixin {
  // ESP32 IP Address (updated from Serial Monitor)
  String esp32Ip = "10.182.47.155";

  String currentStatus = "Ready";
  bool isConnected = false;
  bool isLoading = false;

  // Spray control state
  bool isSprayOn = false;
  // Light control state
  bool isLightOn = false;
  // Sowing control state
  bool isPairniOn = false;
  // Cutting control state
  bool isCutOn = false;

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Schedule connection check after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnection();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    try {
      print("🔄 Attempting to connect to http://$esp32Ip/status");

      final response = await http
          .get(Uri.parse("http://$esp32Ip/status"))
          .timeout(const Duration(seconds: 5));

      print("📡 Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            isConnected = true;
            currentStatus = "Ready";
          });
        }
        print("✅ Connected successfully!");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnected = false;
          currentStatus = "Connection Failed";
        });
      }
      print("❌ Connection Error: $e");
    }
  }

  Future<void> sendCommand(String cmd, String statusText) async {
    if (isLoading) return;

    if (mounted) {
      setState(() {
        isLoading = true;
        currentStatus = statusText;
      });
    }

    try {
      final response = await http
          .get(Uri.parse("http://$esp32Ip/$cmd"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            isConnected = true;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ $statusText'),
              duration: const Duration(milliseconds: 800),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnected = false;
          currentStatus = "Error: Connection Failed";
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠ Cannot connect to ESP32'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> toggleSpray(bool turnOn) async {
    if (mounted) {
      setState(() {
        isSprayOn = turnOn;
      });
    }

    try {
      final cmd = turnOn ? 'spray_on' : 'spray_off';
      final response = await http
          .get(Uri.parse("http://$esp32Ip/$cmd"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pump Spray ${turnOn ? "ON" : "OFF"} 💦'),
              duration: const Duration(milliseconds: 800),
              backgroundColor:
                  turnOn ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          );
        }
      }
    } catch (e) {
      print("Error toggling spray: $e");
      // Revert state on error
      if (mounted) {
        setState(() {
          isSprayOn = !turnOn;
        });
      }
    }
  }

  Future<void> toggleLight(bool turnOn) async {
    if (mounted) {
      setState(() {
        isLightOn = turnOn;
      });
    }

    try {
      final cmd = turnOn ? 'light_on' : 'light_off';
      final response = await http
          .get(Uri.parse("http://$esp32Ip/$cmd"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Light ${turnOn ? "ON" : "OFF"} 💡'),
              duration: const Duration(milliseconds: 800),
              backgroundColor: turnOn ? Colors.amber.shade700 : Colors.grey.shade700,
            ),
          );
        }
      }
    } catch (e) {
      print("Error toggling light: $e");
      if (mounted) {
        setState(() {
          isLightOn = !turnOn;
        });
      }
    }
  }

  Future<void> togglePairni(bool turnOn) async {
    if (mounted) {
      setState(() {
        isPairniOn = turnOn;
      });
    }

    try {
      final cmd = turnOn ? 'pairni_on' : 'pairni_off';
      final response = await http
          .get(Uri.parse("http://$esp32Ip/$cmd"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${TranslationService().translate('sow')} ${turnOn ? "ON" : "OFF"} 🌱'),
              duration: const Duration(milliseconds: 800),
              backgroundColor: turnOn ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          );
        }
      }
    } catch (e) {
      print("Error toggling pairni: $e");
      if (mounted) {
        setState(() {
          isPairniOn = !turnOn;
        });
      }
    }
  }

  Future<void> toggleCut(bool turnOn) async {
    if (mounted) {
      setState(() {
        isCutOn = turnOn;
      });
    }

    try {
      final cmd = turnOn ? 'cut_on' : 'cut_off';
      final response = await http
          .get(Uri.parse("http://$esp32Ip/$cmd"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${TranslationService().translate('cut')} ${turnOn ? "ON" : "OFF"} 🌾'),
              duration: const Duration(milliseconds: 800),
              backgroundColor: turnOn ? Colors.orange.shade700 : Colors.grey.shade700,
            ),
          );
        }
      }
    } catch (e) {
      print("Error toggling cut: $e");
      if (mounted) {
        setState(() {
          isCutOn = !turnOn;
        });
      }
    }
  }

  void _showIpDialog() {
    final controller = TextEditingController(text: esp32Ip);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            title: const Text(
              'ESP32 IP Address',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 192.168.43.10',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    labelText: 'IP Address',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade700.withOpacity(0.5),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 How to find IP:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Check Arduino Serial Monitor',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '2. OR Check "Connected Devices" in your Phone Hotspot Settings',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      esp32Ip = controller.text;
                    });
                  }
                  Navigator.pop(context);
                  _checkConnection();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                ),
                child: const Text(
                  'Save & Connect',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0E21), Color(0xFF1D1E33), Color(0xFF1A3A52)],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      _buildSprayControls(),
                      const SizedBox(height: 30),
                      _buildControlButtons(),
                      const SizedBox(height: 30),
                      _buildWiFiSettings(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                          Icons.directions_boat_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rower Control',
                              style: TextStyle(
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔄 Refreshing connection...'),
                              duration: Duration(milliseconds: 1000),
                              backgroundColor: Color(0xFF1B5E20),
                            ),
                          );
                        }
                        await _checkConnection();
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showIpDialog,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildConnectionChip(),
                const SizedBox(width: 8),
                _buildStatusChip('IP: $esp32Ip', Colors.white70),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/sensors');
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sensors',
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

  Widget _buildConnectionChip() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // Map animation value (1.0-1.05) to opacity range (0.5-1.0)
        final pulseOpacity =
            isConnected
                ? (((_pulseAnimation.value - 1.0) * 10).clamp(0.0, 0.5) + 0.5)
                : 0.5;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isConnected
                      ? Colors.green.shade300.withOpacity(pulseOpacity)
                      : Colors.red.shade300.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color:
                      isConnected ? Colors.green.shade300 : Colors.red.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                isConnected ? 'Connected' : 'Offline',
                style: TextStyle(
                  color:
                      isConnected ? Colors.green.shade300 : Colors.red.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade700.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'CURRENT STATUS',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isLoading ? _pulseAnimation.value : 1.0,
                child: Text(
                  currentStatus,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (currentStatus.contains('Forward')) return Colors.green;
    if (currentStatus.contains('Backward')) return Colors.orange;
    if (currentStatus.contains('Left')) return Colors.blue;
    if (currentStatus.contains('Right')) return Colors.purple;
    if (currentStatus.contains('Stop')) return Colors.red;
    if (currentStatus.contains('Error')) return Colors.red;
    return Colors.blue;
  }

  Widget _buildSprayControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade700.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'AUXILIARY CONTROLS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildSprayToggle(
            label: 'Pump Spray',
            icon: Icons.water_drop_outlined,
            isOn: isSprayOn,
            onToggle: (value) => toggleSpray(value),
            activeColor: Colors.blue,
            statusText: isSprayOn ? 'Spraying Active 💦' : 'Spray Inactive',
          ),
          const SizedBox(height: 16),
          _buildSprayToggle(
            label: 'LED Light',
            icon: Icons.lightbulb_outline,
            isOn: isLightOn,
            onToggle: (value) => toggleLight(value),
            activeColor: Colors.amber,
            statusText: isLightOn ? 'Light On 💡' : 'Light Off',
          ),
          const SizedBox(height: 16),
          _buildSprayToggle(
            label: TranslationService().translate('sow'),
            icon: Icons.grass_rounded,
            isOn: isPairniOn,
            onToggle: (value) => togglePairni(value),
            activeColor: Colors.green,
            statusText: isPairniOn ? 'Sowing Active 🌱' : 'Sowing Inactive',
          ),
          const SizedBox(height: 16),
          _buildSprayToggle(
            label: TranslationService().translate('cut'),
            icon: Icons.content_cut_rounded,
            isOn: isCutOn,
            onToggle: (value) => toggleCut(value),
            activeColor: Colors.orange,
            statusText: isCutOn ? 'Cutting Active 🌾' : 'Cutting Inactive',
          ),
        ],
      ),
    );
  }

  Widget _buildSprayToggle({
    required String label,
    required IconData icon,
    required bool isOn,
    required Function(bool) onToggle,
    required MaterialColor activeColor,
    required String statusText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            isOn
                ? LinearGradient(
                  colors: [
                    activeColor.shade600.withOpacity(0.3),
                    activeColor.shade800.withOpacity(0.3),
                  ],
                )
                : null,
        color: !isOn ? Colors.grey.shade900.withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn ? activeColor.shade400 : Colors.grey.shade700,
          width: 2,
        ),
        boxShadow:
            isOn
                ? [
                  BoxShadow(
                    color: activeColor.shade400.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOn ? activeColor.shade600 : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOn ? activeColor.shade300 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOn ? activeColor.shade200 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: isOn,
              onChanged: isConnected ? onToggle : null,
              activeColor: Colors.white,
              activeTrackColor: activeColor.shade600,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.arrow_upward_rounded,
            label: 'FORWARD',
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
            ),
            onPressed: () => sendCommand('forward', 'Moving Forward'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'LEFT',
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                  ),
                  onPressed: () => sendCommand('left', 'Turning Left'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.stop_rounded,
                  label: 'STOP',
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade800],
                  ),
                  onPressed: () => sendCommand('stop', 'Stopped'),
                  isLarge: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'RIGHT',
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.purple.shade800],
                  ),
                  onPressed: () => sendCommand('right', 'Turning Right'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            icon: Icons.arrow_downward_rounded,
            label: 'BACKWARD',
            gradient: LinearGradient(
              colors: [Colors.orange.shade600, Colors.orange.shade800],
            ),
            onPressed: () => sendCommand('back', 'Moving Backward'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isLarge ? 20 : 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: isLarge ? 36 : 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 16 : 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWiFiSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.wifi, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESP32 WiFi Connection',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        esp32Ip,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showIpDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade700.withOpacity(0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connect to "ESP32_SPRAY_ROBOT" WiFi network first',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
