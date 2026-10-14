import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _service = WeatherService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  WeatherModel? _weather;
  bool _isLoading = false;
  String? _error;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _loadCurrentLocationWeather();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location service is disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final weather = await _service.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      _searchByCity('Dhaka');
    }
  }

  Future<void> _searchByCity(String city) async {
    if (city.trim().isEmpty) return;
    _focusNode.unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _service.getWeatherByCity(city.trim());
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _weather?.gradientColors ??
        const [
          Color(0xFF0F1B3D),
          Color(0xFF1F3A63),
          Color(0xFF2C5364),
        ];
    final accent = _weather?.accentColor ?? const Color(0xFF7AB8FF);

    return Scaffold(
      backgroundColor: colors.last,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => _buildAurora(accent),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                  Colors.black.withOpacity(0.35),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildTopBar(),
                  const SizedBox(height: 22),
                  _buildSearchBar(accent),
                  const SizedBox(height: 22),
                  Expanded(child: _buildContent(accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Aurora Background ====================
  Widget _buildAurora(Color accent) {
    final t = _bgController.value;
    final angle = t * 2 * math.pi;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -100 + math.sin(angle) * 60,
              right: -80 + math.cos(angle) * 50,
              child: _orb(280, accent.withOpacity(0.45)),
            ),
            Positioned(
              bottom: -120 + math.cos(angle * 1.3) * 70,
              left: -100 + math.sin(angle * 1.3) * 60,
              child: _orb(340, Colors.white.withOpacity(0.18)),
            ),
            Positioned(
              top: 280 + math.sin(angle * 0.8) * 40,
              left: -60 + math.cos(angle * 0.8) * 40,
              child: _orb(200, accent.withOpacity(0.30)),
            ),
            Positioned(
              top: 60 + math.cos(angle * 1.5) * 30,
              left: -40 + math.sin(angle * 1.5) * 30,
              child: _orb(140, const Color(0xFFFFB6E0).withOpacity(0.25)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }

  // ==================== Top Bar ====================
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atmosphere',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Live weather intelligence',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.60),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.10),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.3, curve: Curves.easeOutCubic);
  }

  // ==================== Search Bar ====================
  Widget _buildSearchBar(Color accent) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: Colors.white,
        onSubmitted: _searchByCity,
        decoration: InputDecoration(
          hintText: 'Search any city...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.55),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.22),
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.22),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide(
              color: accent.withOpacity(0.9),
              width: 1.8,
            ),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.search_rounded,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.my_location_rounded,
              color: Colors.white.withOpacity(0.9),
            ),
            onPressed: _loadCurrentLocationWeather,
            tooltip: 'Use my location',
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 600.ms)
        .slideY(begin: -0.2, curve: Curves.easeOutCubic);
  }

  // ==================== Content ====================
  Widget _buildContent(Color accent) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
                backgroundColor: Colors.white.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Fetching weather...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              TextButton.icon(
                onPressed: _loadCurrentLocationWeather,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.92, 0.92)),
      );
    }

    if (_weather == null) return const SizedBox.shrink();
    return _buildWeatherContent(_weather!, accent);
  }

  // ==================== Weather Content ====================
  Widget _buildWeatherContent(WeatherModel w, Color accent) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          _buildHeroCard(w, accent),
          const SizedBox(height: 20),
          _buildStatsGrid(w, accent),
          const SizedBox(height: 20),
          _buildSunArc(w, accent),
          const SizedBox(height: 20),
          _buildTipBanner(w, accent),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== Hero Card ====================
  Widget _buildHeroCard(WeatherModel w, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.16),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 60,
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Location row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.white.withOpacity(0.95),
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${w.cityName}, ${w.country}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, d MMMM • hh:mm a').format(w.dateTime),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),

          // ══════════════ PREMIUM ANIMATED ICON ══════════════
          SizedBox(
            width: 170,
            height: 170,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WeatherIconPainter(
                    iconCode: w.iconCode,
                    t: _bgController.value,
                    accent: accent,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 0),

          // Temperature
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white.withOpacity(0.75)],
                ).createShader(bounds),
                child: Text(
                  '${w.temperature.round()}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.w200,
                    height: 1,
                    letterSpacing: -4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  '°',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 42,
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text(
                  'C',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Description chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 1,
              ),
            ),
            child: Text(
              w.description.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Min / Max chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tempChip(
                  Icons.arrow_downward_rounded, 'Min', '${w.tempMin.round()}°'),
              const SizedBox(width: 12),
              _tempChip(
                  Icons.arrow_upward_rounded, 'Max', '${w.tempMax.round()}°'),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.18, curve: Curves.easeOutCubic);
  }

  Widget _tempChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 14),
          const SizedBox(width: 5),
          Text(
            '$label  $value',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Stats Grid ====================
  Widget _buildStatsGrid(WeatherModel w, Color accent) {
    final stats = [
      _StatData(Icons.water_drop_rounded, 'Humidity', '${w.humidity}%'),
      _StatData(Icons.air_rounded, 'Wind', '${w.windSpeed} m/s'),
      _StatData(
          Icons.thermostat_rounded, 'Feels Like', '${w.feelsLike.round()}°C'),
      _StatData(Icons.speed_rounded, 'Pressure', '${w.pressure} hPa'),
      _StatData(Icons.visibility_rounded, 'Visibility',
          '${(w.visibility / 1000).toStringAsFixed(1)} km'),
      _StatData(Icons.wb_twilight_rounded, 'Condition', w.mainCondition),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.85,
      ),
      itemBuilder: (context, index) {
        final s = stats[index];
        return _statCard(s, accent)
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 300 + index * 80),
              duration: 500.ms,
            )
            .slideY(begin: 0.25, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _statCard(_StatData s, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.14),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.22),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Icon(s.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Sun Arc ====================
  Widget _buildSunArc(WeatherModel w, Color accent) {
    final sunriseTime = DateTime.fromMillisecondsSinceEpoch(w.sunrise * 1000);
    final sunsetTime = DateTime.fromMillisecondsSinceEpoch(w.sunset * 1000);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Sun Cycle',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            child: CustomPaint(
              size: const Size(double.infinity, 90),
              painter: _SunArcPainter(accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sunInfo('Sunrise', DateFormat('hh:mm a').format(sunriseTime),
                  Icons.wb_twilight_rounded),
              _sunInfo('Sunset', DateFormat('hh:mm a').format(sunsetTime),
                  Icons.nights_stay_rounded),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 600.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

  Widget _sunInfo(String label, String time, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.60),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== Tip Banner ====================
  Widget _buildTipBanner(WeatherModel w, Color accent) {
    String tip;
    IconData tipIcon;

    if (w.isRainy) {
      tip = 'Rain is on the way — carry an umbrella';
      tipIcon = Icons.umbrella_rounded;
    } else if (w.temperature >= 35) {
      tip = 'It is quite hot today — stay hydrated';
      tipIcon = Icons.wb_sunny_rounded;
    } else if (w.temperature <= 15) {
      tip = 'Chilly weather — wear warm clothes';
      tipIcon = Icons.ac_unit_rounded;
    } else if (w.isCloudy) {
      tip = 'Sky is overcast — a calm, cozy day';
      tipIcon = Icons.cloud_rounded;
    } else if (w.isNight) {
      tip = 'Peaceful night — enjoy the calm breeze';
      tipIcon = Icons.nightlight_round;
    } else {
      tip = 'Beautiful weather — make the most of it';
      tipIcon = Icons.emoji_emotions_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.25),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 1,
              ),
            ),
            child: Icon(tipIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 850.ms, duration: 600.ms)
        .slideY(begin: 0.25, curve: Curves.easeOutCubic);
  }
}

// ═══════════════════════════════════════════════════════════
// Helper Data Class
// ═══════════════════════════════════════════════════════════
class _StatData {
  final IconData icon;
  final String label;
  final String value;
  _StatData(this.icon, this.label, this.value);
}

// ═══════════════════════════════════════════════════════════
// ☀️🌧️ PREMIUM WEATHER ICON PAINTER — dispatches to sub painters
// ═══════════════════════════════════════════════════════════
class _WeatherIconPainter extends CustomPainter {
  final String iconCode;
  final double t;
  final Color accent;

  _WeatherIconPainter({
    required this.iconCode,
    required this.t,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (iconCode.length < 2) return;
    final isNight = iconCode.endsWith('n');
    final id = iconCode.substring(0, 2);

    switch (id) {
      case '01':
        isNight ? _drawMoon(canvas, size) : _drawSun(canvas, size);
        break;
      case '02':
        isNight ? _drawMoonCloud(canvas, size) : _drawSunCloud(canvas, size);
        break;
      case '03':
      case '04':
        _drawCloud(canvas, size);
        break;
      case '09':
      case '10':
        _drawRain(canvas, size);
        break;
      case '11':
        _drawThunder(canvas, size);
        break;
      case '13':
        _drawSnow(canvas, size);
        break;
      case '50':
        _drawMist(canvas, size);
        break;
      default:
        _drawSun(canvas, size);
    }
  }

  // ─────────────────────────────────────────────
  // ☀️ SUN
  // ─────────────────────────────────────────────
  void _drawSun(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.19;

    // Outer corona glow (double layer)
    canvas.drawCircle(
      c,
      r * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE082).withOpacity(0.55),
            const Color(0xFFFFE082).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2.6)),
    );

    // Rotating rays (two passes with different lengths)
    final ang = t * math.pi * 2;
    final rayPaintLong = Paint()
      ..color = const Color(0xFFFFC93C).withOpacity(0.95)
      ..strokeWidth = size.width * 0.022
      ..strokeCap = StrokeCap.round;
    final rayPaintShort = Paint()
      ..color = const Color(0xFFFFA726).withOpacity(0.85)
      ..strokeWidth = size.width * 0.016
      ..strokeCap = StrokeCap.round;

    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final a = ang + i * math.pi * 2 / rayCount;
      final pulse = 1 + 0.08 * math.sin(t * math.pi * 4 + i);
      final start = r * 1.35;
      final end = r * (1.75 * pulse);
      final p1 = c + Offset(math.cos(a) * start, math.sin(a) * start);
      final p2 = c + Offset(math.cos(a) * end, math.sin(a) * end);
      canvas.drawLine(p1, p2, i.isEven ? rayPaintLong : rayPaintShort);
    }

    // Sun body — 3-stop radial gradient
    final bodyRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: const [
            Color(0xFFFFFDE7),
            Color(0xFFFFD54F),
            Color(0xFFF57C00),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bodyRect),
    );

    // Inner rim highlight
    canvas.drawCircle(
      c,
      r * 0.85,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.5),
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.85)),
    );
  }

  // ─────────────────────────────────────────────
  // 🌙 MOON
  // ─────────────────────────────────────────────
  void _drawMoon(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.19;

    // Outer glow
    canvas.drawCircle(
      c,
      r * 2.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFB8C8FF).withOpacity(0.55),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2.4)),
    );

    // Moon body — radial gradient
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: const [
            Colors.white,
            Color(0xFFF0F4FF),
            Color(0xFFB8C8FF),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Craters
    final crater = Paint()..color = const Color(0xFF9EB2E8).withOpacity(0.35);
    canvas.drawCircle(c + Offset(-r * 0.30, r * 0.20), r * 0.16, crater);
    canvas.drawCircle(c + Offset(-r * 0.05, -r * 0.35), r * 0.10, crater);
    canvas.drawCircle(c + Offset(-r * 0.45, -r * 0.15), r * 0.08, crater);
    canvas.drawCircle(c + Offset(r * 0.15, r * 0.35), r * 0.06, crater);

    // Inner highlight
    canvas.drawCircle(
      c + Offset(-r * 0.35, -r * 0.35),
      r * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.65),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: c + Offset(-r * 0.35, -r * 0.35),
            radius: r * 0.55,
          ),
        ),
    );

    // Twinkling stars
    _star(canvas, c + Offset(r * 1.7, -r * 1.3), r * 0.14, t + 0.0);
    _star(canvas, c + Offset(-r * 1.8, -r * 1.0), r * 0.11, t + 0.3);
    _star(canvas, c + Offset(r * 1.4, r * 1.5), r * 0.09, t + 0.6);
    _star(canvas, c + Offset(-r * 1.5, r * 1.2), r * 0.12, t + 0.9);
  }

  void _star(Canvas canvas, Offset p, double r, double phase) {
    final twinkle = 0.5 + 0.5 * math.sin((phase + t * 1.5) * math.pi * 2);
    final paint = Paint()..color = Colors.white.withOpacity(0.4 + 0.6 * twinkle);
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final outer = p + Offset(math.cos(a) * r * 1.7, math.sin(a) * r * 1.7);
      final innerA = a + math.pi / 4;
      final inner = p + Offset(math.cos(innerA) * r * 0.55, math.sin(innerA) * r * 0.55);
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ─────────────────────────────────────────────
  // ☁️ CLOUD (3-layer gradient puff)
  // ─────────────────────────────────────────────
  void _drawCloudShape(
    Canvas canvas,
    Offset center,
    double width,
    List<Color> colors, {
    double opacity = 1.0,
  }) {
    final h = width * 0.42;
    final path = Path();

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: width, height: h * 0.62),
        Radius.circular(h * 0.31),
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: center + Offset(-width * 0.22, -h * 0.15),
        radius: h * 0.55,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: center + Offset(0, -h * 0.45),
        radius: h * 0.80,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: center + Offset(width * 0.22, -h * 0.08),
        radius: h * 0.50,
      ),
    );

    // Drop shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.22 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Main fill
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.55, 1.0],
        ).createShader(path.getBounds())
        ..color = Colors.white.withOpacity(opacity),
    );

    // Top shine
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.7),
          colors: [
            Colors.white.withOpacity(0.55 * opacity),
            Colors.transparent,
          ],
        ).createShader(path.getBounds()),
    );
  }

  void _drawCloud(Canvas canvas, Size size) {
    final dx = math.sin(t * math.pi * 2) * size.width * 0.04;

    // Back cloud
    _drawCloudShape(
      canvas,
      Offset(size.width * 0.36 - dx, size.height * 0.42),
      size.width * 0.50,
      const [Color(0xFFF5F9FF), Color(0xFFCFDCEC), Color(0xFF8FA5C7)],
      opacity: 0.70,
    );
    // Front cloud
    _drawCloudShape(
      canvas,
      Offset(size.width * 0.55 + dx, size.height * 0.58),
      size.width * 0.68,
      const [Color(0xFFFFFFFF), Color(0xFFE3ECF8), Color(0xFFA8BCD6)],
    );
  }

  // ─────────────────────────────────────────────
  // 🌤️ SUN + CLOUD
  // ─────────────────────────────────────────────
  void _drawSunCloud(Canvas canvas, Size size) {
    final sunC = Offset(size.width * 0.36, size.height * 0.36);
    final r = size.width * 0.15;

    // Sun glow
    canvas.drawCircle(
      sunC,
      r * 2.3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE082).withOpacity(0.55),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: sunC, radius: r * 2.3)),
    );

    // Rays
    final ang = t * math.pi * 2;
    final rayPaint = Paint()
      ..color = const Color(0xFFFFC93C)
      ..strokeWidth = size.width * 0.016
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 10; i++) {
      final a = ang + i * math.pi * 2 / 10;
      final p1 = sunC + Offset(math.cos(a) * r * 1.35, math.sin(a) * r * 1.35);
      final p2 = sunC + Offset(math.cos(a) * r * 1.75, math.sin(a) * r * 1.75);
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Sun body
    canvas.drawCircle(
      sunC,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: const [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFF57C00)],
        ).createShader(Rect.fromCircle(center: sunC, radius: r)),
    );

    // Cloud
    _drawCloudShape(
      canvas,
      Offset(size.width * 0.56, size.height * 0.62),
      size.width * 0.66,
      const [Color(0xFFFFFFFF), Color(0xFFE3ECF8), Color(0xFFA8BCD6)],
    );
  }

  // ─────────────────────────────────────────────
  // 🌙 MOON + CLOUD
  // ─────────────────────────────────────────────
  void _drawMoonCloud(Canvas canvas, Size size) {
    final moonC = Offset(size.width * 0.36, size.height * 0.36);
    final r = size.width * 0.15;

    canvas.drawCircle(
      moonC,
      r * 2.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFB8C8FF).withOpacity(0.55),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: moonC, radius: r * 2.2)),
    );

    canvas.drawCircle(
      moonC,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: const [Colors.white, Color(0xFFF0F4FF), Color(0xFFB8C8FF)],
        ).createShader(Rect.fromCircle(center: moonC, radius: r)),
    );

    // Crater
    canvas.drawCircle(
      moonC + Offset(-r * 0.3, r * 0.15),
      r * 0.18,
      Paint()..color = const Color(0xFF9EB2E8).withOpacity(0.35),
    );

    // Cloud
    _drawCloudShape(
      canvas,
      Offset(size.width * 0.56, size.height * 0.62),
      size.width * 0.66,
      const [Color(0xFFFFFFFF), Color(0xFFE3ECF8), Color(0xFFA8BCD6)],
    );
  }

  // ─────────────────────────────────────────────
  // 🌧️ RAIN
  // ─────────────────────────────────────────────
  void _drawRain(Canvas canvas, Size size) {
    _drawCloudShape(
      canvas,
      Offset(size.width * 0.5, size.height * 0.38),
      size.width * 0.72,
      const [Color(0xFFFFFFFF), Color(0xFFD0DEF2), Color(0xFF8FA5C7)],
    );

    // Raindrops
    const dropCount = 7;
    for (int i = 0; i < dropCount; i++) {
      final baseX = size.width * (0.22 + 0.56 * i / (dropCount - 1));
      final phase = (t + i * 0.14) % 1.0;
      final y = size.height * (0.60 + phase * 0.34);
      final alpha = (1 - phase).clamp(0.0, 1.0);

      final dw = size.width * 0.024;
      final dh = size.width * 0.055;

      // Drop body (teardrop shape)
      final path = Path();
      path.moveTo(baseX, y - dh * 0.5);
      path.quadraticBezierTo(
          baseX + dw, y + dh * 0.5, baseX, y + dh * 0.7);
      path.quadraticBezierTo(baseX - dw, y + dh * 0.5, baseX, y - dh * 0.5);

      // Drop fill with gradient
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB3E0FF), Color(0xFF4FA8FF)],
          ).createShader(Rect.fromCircle(
              center: Offset(baseX, y), radius: dw * 1.5))
          ..color = Colors.white.withOpacity(alpha),
      );

      // Highlight on drop
      canvas.drawCircle(
        Offset(baseX - dw * 0.3, y + dh * 0.1),
        dw * 0.35,
        Paint()..color = Colors.white.withOpacity(0.65 * alpha),
      );
    }
  }

  // ─────────────────────────────────────────────
  // ⛈️ THUNDER
  // ─────────────────────────────────────────────
  void _drawThunder(Canvas canvas, Size size) {
    // Flash glow behind
    final flash = (math.sin(t * math.pi * 6) + 1) / 2;
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.65),
      size.width * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF176).withOpacity(0.45 * flash),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.65),
          radius: size.width * 0.55,
        )),
    );

    // Dark cloud
    _drawCloudShape(
      canvas,
      Offset(size.width * 0.5, size.height * 0.38),
      size.width * 0.72,
      const [Color(0xFFDDE5F0), Color(0xFFA8B7CE), Color(0xFF5D6E88)],
    );

    // Lightning bolt
    final cx = size.width * 0.5;
    final top = size.height * 0.60;
    final bottom = size.height * 0.90;
    final w = size.width * 0.14;

    final bolt = Path();
    bolt.moveTo(cx + w * 0.10, top);
    bolt.lineTo(cx - w * 0.55, (top + bottom) * 0.5);
    bolt.lineTo(cx - w * 0.05, (top + bottom) * 0.5);
    bolt.lineTo(cx - w * 0.35, bottom);
    bolt.lineTo(cx + w * 0.65, (top + bottom) * 0.5 + size.height * 0.05);
    bolt.lineTo(cx + w * 0.15, (top + bottom) * 0.5 + size.height * 0.05);
    bolt.lineTo(cx + w * 0.40, top);
    bolt.close();

    // Outer glow
    canvas.drawPath(
      bolt,
      Paint()
        ..color = const Color(0xFFFFEB3B).withOpacity(0.85 * flash)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Bolt body
    canvas.drawPath(
      bolt,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFFA000)],
        ).createShader(
            Rect.fromLTWH(0, top, size.width, bottom - top)),
    );

    // Bolt highlight stripe
    canvas.drawPath(
      bolt,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.55 * flash),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromLTWH(0, top, size.width, bottom - top)),
    );
  }

  // ─────────────────────────────────────────────
  // ❄️ SNOW
  // ─────────────────────────────────────────────
  void _drawSnow(Canvas canvas, Size size) {
    _drawCloudShape(
      canvas,
      Offset(size.width * 0.5, size.height * 0.36),
      size.width * 0.72,
      const [Color(0xFFFFFFFF), Color(0xFFE5EEF8), Color(0xFFB6C7DE)],
    );

    const flakeCount = 7;
    for (int i = 0; i < flakeCount; i++) {
      final baseX = size.width * (0.22 + 0.56 * i / (flakeCount - 1));
      final phase = (t + i * 0.12) % 1.0;
      final y = size.height * (0.60 + phase * 0.34);
      final sway = math.sin(phase * math.pi * 4 + i) * size.width * 0.03;
      final alpha = (1 - phase).clamp(0.0, 1.0);
      final spin = phase * math.pi * 2;

      _snowflake(
        canvas,
        Offset(baseX + sway, y),
        size.width * 0.045,
        Colors.white.withOpacity(alpha),
        spin,
      );
    }
  }

  void _snowflake(Canvas canvas, Offset c, double r, Color color, double spin) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final a = spin + i * math.pi / 3;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      canvas.drawLine(c, p, paint);

      // Branches
      final mid = c + Offset(math.cos(a) * r * 0.6, math.sin(a) * r * 0.6);
      final b1 = mid + Offset(math.cos(a + 0.7) * r * 0.35, math.sin(a + 0.7) * r * 0.35);
      final b2 = mid + Offset(math.cos(a - 0.7) * r * 0.35, math.sin(a - 0.7) * r * 0.35);
      canvas.drawLine(mid, b1, paint);
      canvas.drawLine(mid, b2, paint);
    }

    // Center dot
    canvas.drawCircle(c, r * 0.18, Paint()..color = color);
  }

  // ─────────────────────────────────────────────
  // 🌫️ MIST
  // ─────────────────────────────────────────────
  void _drawMist(Canvas canvas, Size size) {
    _drawCloudShape(
      canvas,
      Offset(size.width * 0.5, size.height * 0.32),
      size.width * 0.62,
      const [Color(0xFFF0F4FB), Color(0xFFD5DEEB), Color(0xFFA8B4C8)],
      opacity: 0.85,
    );

    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.55 + i * 0.085);
      final path = Path();
      final amp = 3.0 + i * 1.0;
      final shift = t * math.pi * 2 + i * 1.1;
      for (double x = size.width * 0.12; x < size.width * 0.88; x += 2) {
        final yy = y + math.sin(x * 0.09 + shift) * amp;
        if (x == size.width * 0.12) {
          path.moveTo(x, yy);
        } else {
          path.lineTo(x, yy);
        }
      }
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.55 - i * 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 - i * 0.4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherIconPainter old) =>
      old.t != t || old.iconCode != iconCode || old.accent != accent;
}

// ═══════════════════════════════════════════════════════════
// Sun Arc Painter
// ═══════════════════════════════════════════════════════════
class _SunArcPainter extends CustomPainter {
  final Color accent;
  _SunArcPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(10, h - 10)
      ..quadraticBezierTo(w / 2, -h + 40, w - 10, h - 10);

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final len = math.min(4.0, metric.length - distance);
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += 9;
      }
    }

    const t = 0.5;
    final sunX =
        (1 - t) * (1 - t) * 10 + 2 * (1 - t) * t * (w / 2) + t * t * (w - 10);
    final sunY = (1 - t) * (1 - t) * (h - 10) +
        2 * (1 - t) * t * (-h + 40) +
        t * t * (h - 10);

    final glow = Paint()
      ..color = accent.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(sunX, sunY), 12, glow);

    final sun = Paint()..color = accent;
    canvas.drawCircle(Offset(sunX, sunY), 7, sun);

    final inner = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(sunX, sunY), 3, inner);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) =>
      oldDelegate.accent != accent;
}