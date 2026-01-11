import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_perfect/controllers/controller.dart';
import 'package:hr_perfect/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final String userId;

  const EmployeeProfileScreen({super.key, required this.userId});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> with SingleTickerProviderStateMixin {
  static const LinearGradient _brandGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final HRController _hrController = Get.find<HRController>();
  
  bool _isLoading = true;
  String? _photoPath;
  
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation controller
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadProfile();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    
    _animationController?.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Data is already in HRController from authentication
    // Just load the saved photo
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_photo_${widget.userId}');
    if (savedPath != null && File(savedPath).existsSync()) {
      _photoPath = savedPath;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;
    if (!mounted) return;

    setState(() => _photoPath = picked.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo_${widget.userId}', picked.path);
  }

  String get _displayName {
    // Use prenom from HRController
    if (_hrController.prenom.value.trim().isNotEmpty) {
      return '${_hrController.prenom.value.trim()} ${_hrController.nom.value.trim()}';
    }

    final raw = widget.userId.split('@').first;
    if (raw.isEmpty) return 'Employé';

    final parts = raw.split(RegExp(r'[._\-]+'));
    final cleaned = parts.where((e) => e.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return 'Employé';

    return cleaned
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  String get _initial {
    final n = _displayName.trim();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  String _valOrDefault(String v, {String fallback = 'Non renseigné'}) {
    final t = v.trim();
    return t.isEmpty ? fallback : t;
  }

  void _handleLogout() {
    _hrController.logout();
    Get.offAll(() => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    Widget scrollContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(-30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  "Mon profil",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Déconnexion",
                  onPressed: _handleLogout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Obx(() => Column(
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 20),
                      _buildDetailsSlider(),
                    ],
                  )),
        ],
      ),
    );

    // Wrap with fade animation
    Widget animatedContent = (_fadeAnimation != null)
        ? FadeTransition(
            opacity: _fadeAnimation!,
            child: scrollContent,
          )
        : scrollContent;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ClipPath(
              clipper: _TopWaveClipper(),
              child: Container(
                height: 230,
                decoration: const BoxDecoration(gradient: _brandGradient),
              ),
            ),
          ),
          SafeArea(child: animatedContent),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage: _photoPath != null
                        ? FileImage(File(_photoPath!))
                        : null,
                    backgroundColor: const Color(0xFFE4F2FF),
                    child: _photoPath == null
                        ? Text(
                            _initial,
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0072FF),
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C6FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.6),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hrController.categorie.value.trim().isEmpty
                        ? 'Poste non défini'
                        : _hrController.categorie.value.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3FDF6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            size: 16,
                            color: Color(0xFF00C6A2),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _hrController.departement.value.trim().isEmpty
                                ? 'Aucun département'
                                : _hrController.departement.value.trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF048C73),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDetailsSlider() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            height: 470,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _buildDetailsCard(
                  title: "Informations Personnelles",
                  icon: Icons.person_outline_rounded,
                  details: [
                    _DetailItem(
                      icon: Icons.person_outline,
                      label: "Nom",
                      value: _valOrDefault(_hrController.nom.value),
                    ),
                    _DetailItem(
                      icon: Icons.person_outline,
                      label: "Prénom",
                      value: _valOrDefault(_hrController.prenom.value),
                    ),
                    _DetailItem(
                      icon: Icons.phone_outlined,
                      label: "Téléphone",
                      value: _valOrDefault(_hrController.telephoneMobile.value),
                    ),
                    _DetailItem(
                      icon: Icons.wc,
                      label: "Sexe",
                      value: _valOrDefault(_hrController.sexe.value),
                    ),
                    _DetailItem(
                      icon: Icons.cake_outlined,
                      label: "Date de naissance",
                      value: _valOrDefault(_hrController.dateNaissance.value),
                    ),
                    _DetailItem(
                      icon: Icons.location_city_outlined,
                      label: "Ville",
                      value: _valOrDefault(_hrController.ville.value),
                    ),
                    _DetailItem(
                      icon: Icons.work_outline,
                      label: "Poste",
                      value: _valOrDefault(_hrController.categorie.value),
                    ),
                  ],
                ),
                _buildDetailsCard(
                  title: "Informations Professionnelles",
                  icon: Icons.work_outline_rounded,
                  details: [
                    _DetailItem(
                      icon: Icons.badge_outlined,
                      label: "Matricule",
                      value: _valOrDefault(_hrController.matricule.value),
                    ),
                    _DetailItem(
                      icon: Icons.verified_user_outlined,
                      label: "N° CNSS",
                      value: _valOrDefault(_hrController.numCnss.value),
                    ),
                    _DetailItem(
                      icon: Icons.work_outline,
                      label: "Poste",
                      value: _valOrDefault(_hrController.categorie.value),
                    ),
                    _DetailItem(
                      icon: Icons.apartment_outlined,
                      label: "Département",
                      value: _valOrDefault(_hrController.departement.value),
                    ),
                    _DetailItem(
                      icon: Icons.category_outlined,
                      label: "Catégorie",
                      value: _valOrDefault(_hrController.categorie.value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: _currentPage == index ? _brandGradient : null,
                    color: _currentPage == index ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required IconData icon,
    required List<_DetailItem> details,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: _brandGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: details
                    .asMap()
                    .entries
                    .map(
                      (entry) => _buildDetailTileAnimated(
                        icon: entry.value.icon,
                        label: entry.value.label,
                        value: entry.value.value,
                        index: entry.key,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTileAnimated({
    required IconData icon,
    required String label,
    required String value,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAF0F6)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  _DetailItem({required this.icon, required this.label, required this.value});
}

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.6,
      size.height - 70,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height - 110,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TopWaveClipper oldClipper) => false;
}