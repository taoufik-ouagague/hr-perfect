import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  AnimationController? _fadeController;
  AnimationController? _scaleController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;
  
  final HRController _hrController = Get.find<HRController>();

  @override
  void initState() {
    super.initState();
    // For testing purposes only; remove in production
    _loginCtrl.text = 'Demo';
    _passwordCtrl.text = 'Kaytech@2017';

    // Animation setup
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController!, curve: Curves.easeOutBack),
    );

    _fadeController?.forward();
    _scaleController?.forward();
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeController?.dispose();
    _scaleController?.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final login = _loginCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();

    try {
      final ok = await _hrController.authenticate(login, pwd);

      if (!mounted) return;

      if (ok) {
        Get.offAllNamed('/home');
      } else {
        Get.snackbar(
          'Erreur',
          'Identifiants invalides',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade900,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.error_outline, color: Colors.red),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String msg = 'Erreur inattendue. Veuillez réessayer.';
      
      if (e.toString().contains('timeout')) {
        msg = 'Le serveur ne répond pas. Vérifiez votre connexion/VPN.';
      } else if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        msg = 'Erreur réseau. Vérifiez votre connexion internet.';
      }

      Get.snackbar(
        'Erreur',
        msg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.red),
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FadeTransition(
                        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 1),
                            
                            // Logo with animation and image
                            ScaleTransition(
                              scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                              child: Container(
                                width: 300,
                                height: 100,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3F79BF).withValues(alpha: 0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'lib/assets/img/WhatsApp_Image_2026-01-02_at_16.12.09-removebg-preview.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            
                            // App title and subtitle
                            const Text(
                              "HR PERFECT",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3142),
                                letterSpacing: 1.2,
                              ),
                            ),
                            
                            const SizedBox(height: 6),
                            
                            const Text(
                              "Boostez la performance humaine\nde votre entreprise",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8B92A8),
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Form card
                            _buildFormCard(context),
                            
                            const Spacer(flex: 1),
                            
                            // Footer
                            _buildFooter(),
                            
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7), // Semi-transparent white
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 40,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF3F79BF).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with accent
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5FB3E8), Color(0xFF3F79BF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Connexion",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Login field label
              const Text(
                "Login",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Login field
              _buildInputField(
                controller: _loginCtrl,
                icon: Icons.person_outline_rounded,
                hintText: "Votre identifiant",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Veuillez entrer votre identifiant";
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 18),
              
              // Password field label
              const Text(
                "Mot de passe",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Password field
              _buildInputField(
                controller: _passwordCtrl,
                icon: Icons.lock_outline_rounded,
                hintText: "Votre mot de passe",
                obscureText: _obscurePassword,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer votre mot de passe";
                  }
                  if (value.length < 4) {
                    return "Mot de passe trop court";
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Login button with Obx for loading state
              Obx(() {
                final isLoading = _hrController.isLoading.value;
                
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onLoginPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLoading 
                            ? [const Color(0xFFB5BAC9), const Color(0xFF8B92A8)]
                            : [const Color(0xFF5FB3E8), const Color(0xFF3F79BF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isLoading ? [] : [
                          BoxShadow(
                            color: const Color(0xFF3F79BF).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "Se connecter",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6), // Transparent input background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF2D3142),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFB5BAC9),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF8B92A8),
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8B92A8),
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          errorStyle: const TextStyle(
            fontSize: 12,
            height: 1.5,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Version 1.0",
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF8B92A8).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "|",
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF8B92A8).withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            // Handle conditions
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            "Conditions",
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF8B92A8).withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          "/",
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF8B92A8).withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            // Handle confidentiality
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            "Confidentialité",
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF8B92A8).withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}