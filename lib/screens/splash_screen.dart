// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  AnimationController? _fadeController;
  AnimationController? _scaleController;
  AnimationController? _loadingController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeIn),
    );

    // Scale animation with bounce effect
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController!, curve: Curves.elasticOut),
    );

    // Loading line animation (0 to 100% over 2 seconds)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(parent: _loadingController!, curve: Curves.easeInOut),
    );

    // Start animations with delay for logo
    _fadeController?.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController?.forward();
    });
    
    // Start loading animation after logo appears
    Future.delayed(const Duration(milliseconds: 800), () {
      _loadingController?.forward();
    });

    // Listen for loading animation completion and navigate immediately at 100%
    _loadingController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToAuth();
      }
    });
  }

  void _navigateToAuth() {
    if (mounted) {
      final controller = Get.find<HRController>();
      
      // Check if user is already authenticated
      if (controller.isAuthenticated.value) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _scaleController?.dispose();
    _loadingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8F4F8),
              const Color(0xFFF5F7FA),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: FadeTransition(
                  opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 320,
                    height: 120,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: const Color(0xFF3F79BF).withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'lib/assets/img/WhatsApp_Image_2026-01-02_at_16.12.09-removebg-preview.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Loading line animation with percentage
              FadeTransition(
                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _loadingAnimation ?? const AlwaysStoppedAnimation(0.0),
                        builder: (context, child) {
                          return Stack(
                            children: [
                              // Background line
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3F79BF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Animated line
                              FractionallySizedBox(
                                widthFactor: _loadingAnimation?.value ?? 0.0,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF3F79BF),
                                        const Color(0xFF5B9BD5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3F79BF).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Percentage text
                      AnimatedBuilder(
                        animation: _loadingAnimation ?? const AlwaysStoppedAnimation(0.0),
                        builder: (context, child) {
                          final percentage = ((_loadingAnimation?.value ?? 0.0) * 100).toInt();
                          return Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3F79BF),
                              letterSpacing: 0.5,
                            ),
                          );
                        },
                      ),
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
}