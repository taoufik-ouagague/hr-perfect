import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hr_perfect/screens/employee/add_pret.dart';
import 'package:hr_perfect/screens/employee/add_reclamations.dart';
import 'package:hr_perfect/screens/employee/mes_paies.dart';
import 'package:hr_perfect/screens/employee/planning.dart';
import 'package:hr_perfect/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:hr_perfect/screens/notification_screen.dart';
import 'package:hr_perfect/screens/employee/explore_screen.dart';
import 'package:hr_perfect/screens/employee/shop_screen.dart';
import 'package:hr_perfect/screens/employee/request_history_screen.dart';
import 'package:hr_perfect/screens/employee/employee_profile_screen.dart';
import 'package:hr_perfect/screens/employee/add_conge.dart';
import 'package:hr_perfect/screens/employee/add_mission.dart';
import 'package:hr_perfect/screens/employee/add_sortie.dart';
import 'package:hr_perfect/screens/employee/add_attestation.dart';

import '../../models/request_model.dart';
import '../../controllers/controller.dart';

class EmployeeHome extends StatefulWidget {
  final String userId;
  const EmployeeHome({super.key, required this.userId});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final HRController controller = Get.find<HRController>();

  int _index = 0;
  bool _isLoadingRequests = true;

  // Request counts
  int _encoursRequests = 0;
  int _pendingRequests = 0;
  int _approvedRequests = 0;
  int _rejectedRequests = 0;

  // Animation controller - nullable to handle hot reload
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchRequestCounts();
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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController?.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchRequestCounts() async {
    final token = await getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _isLoadingRequests = false);
      return;
    }

    final apiUrls = [
      ApiService.mesConges(),
      ApiService.getTypesAttestations(),
      ApiService.demandesSorties(),
      ApiService.missions(),
      ApiService.reclamations(),
    ];

    try {
      List<RequestModel> allRequests = [];

      for (final url in apiUrls) {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json', 'token': token},
        );

        _logger.i('GET $url => ${response.statusCode}');

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final parsed = data
              .map((e) => RequestModel.fromJson(e as Map<String, dynamic>))
              .toList();
          allRequests.addAll(parsed);
        }
      }

      if (!mounted) return;

      setState(() {
        _encoursRequests = allRequests
            .where((r) => r.status == RequestStatus.enCours)
            .length;
        _pendingRequests = allRequests
            .where((r) => r.status == RequestStatus.demande)
            .length;
        _approvedRequests = allRequests
            .where((r) => r.status == RequestStatus.valide)
            .length;
        _rejectedRequests = allRequests
            .where((r) => r.status == RequestStatus.rejete)
            .length;
        _isLoadingRequests = false;
      });
    } catch (e) {
      _logger.e('Fetch error: $e');
      if (!mounted) return;
      setState(() => _isLoadingRequests = false);
    }
  }

  String _formatDisplayName(String rawId) {
    String base = rawId.trim();
    if (base.contains('@')) base = base.split('@').first;

    final parts = base.split(RegExp(r'[._\-]+'));
    final cleaned = parts.where((p) => p.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return rawId;

    return cleaned
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(context),
      RequestHistoryScreen(userId: widget.userId),
      EmployeeProfileScreen(userId: widget.userId),
      const ExploreScreen(),
      const ShopScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_index],
      bottomNavigationBar: Theme(
        data: ThemeData(canvasColor: Colors.transparent),
        child: _pillBottomBar(),
      ),
    );
  }

  Widget _pillBottomBar() {
    // Get the bottom padding to avoid system UI
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        bottomPadding > 0
            ? bottomPadding + 8
            : 12, // Add extra padding if system UI exists
      ),
      child: Container(
        height: 72,

        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            _navItem(index: 0, icon: LucideIcons.home, label: "Accueil"),
            _navItem(index: 1, icon: LucideIcons.history, label: "Historique"),
            _navItem(index: 2, icon: LucideIcons.user, label: "Profil"),
            _navItem(index: 3, icon: LucideIcons.compass, label: "Explorer"),
            _navItem(
              index: 4,
              icon: LucideIcons.shoppingCart,
              label: "Boutique",
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _index == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : Colors.transparent,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF00C6FF,
                            ).withValues(alpha: 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  height: 1.0,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? const Color(0xFF00C6FF) : Colors.grey[500],
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context) {
    Widget scrollContent = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: 100, // Add padding to avoid bottom navigation bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bon retour,",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Obx(() {
                      final prenom = controller.prenom.value.isNotEmpty
                          ? controller.prenom.value
                          : _formatDisplayName(widget.userId);

                      return Text(
                        prenom,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.bell,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _isLoadingRequests
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C6FF),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                       const SizedBox(width: 19),
                      _statPill(
                        label: "Demande",
                        value: _pendingRequests.toString(),
                        color: const Color(0xFFFFA726),
                      ),
                      const SizedBox(width: 19),
                      _statPill(
                        label: "En Cours",
                        value: _encoursRequests.toString(),
                        color: const Color(0xFF42A5F5),
                      ),
                      const SizedBox(width: 19),
                      _statPill(
                        label: "Validé",
                        value: _approvedRequests.toString(),
                        color: const Color(0xFF43A047),
                      ),
                      const SizedBox(width: 12),
                      _statPill(
                        label: "Rejeté",
                        value: _rejectedRequests.toString(),
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 28),
          Text(
            "Demandes rapides",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF2F3A4C),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.1,
            children: [
              _quickAction(
                context,
                title: "Congé",
                icon: LucideIcons.palmtree,
                color1: const Color(0xFFFF8A5C),
                color2: const Color(0xFFFF5E62),
                type: "leave",
                subtitle: "Appuyez pour créer",
                screen: AddCongePage(),
                index: 0,
              ),
              _quickAction(
                context,
                title: "Sortie",
                icon: LucideIcons.logOut,
                color1: const Color(0xFF00C6FF),
                color2: const Color(0xFF0072FF),
                type: "exit",
                subtitle: "Appuyez pour créer",
                screen: AddSortiePage(),
                index: 1,
              ),
              _quickAction(
                context,
                title: "Attestation",
                icon: LucideIcons.fileText,
                color1: const Color(0xFF7C4DFF),
                color2: const Color(0xFF536DFE),
                type: "att",
                subtitle: "Appuyez pour créer",
                screen: AddAttestationPage(),
                index: 2,
              ),
              _quickAction(
                context,
                title: "Mission",
                icon: LucideIcons.briefcase,
                color1: const Color(0xFF00E5A0),
                color2: const Color(0xFF00C6FF),
                type: "mission",
                subtitle: "Appuyez pour créer",
                screen: AddMissionPage(),
                index: 3,
              ),
              _quickAction(
                context,
                title: "Prêt",
                icon: LucideIcons.fileSignature,
                color1: const Color(0xFFFF5733),
                color2: const Color(0xFFFFC107),
                type: "prêt",
                subtitle: "Appuyez pour créer",
                screen: AddPretPage(),
                index: 4,
              ),
              _quickAction(
                context,
                title: "Reclamations",
                icon: LucideIcons.alertTriangle,
                color1: const Color(0xFFFF4081),
                color2: const Color.fromARGB(255, 234, 137, 0),
                type: "Reclamations",
                subtitle: "Appuyez pour créer",
                screen: AddReclamationsPage(),
                index: 5,
              ),
              _quickAction(
                context,
                title: "Plannings",
                icon: LucideIcons.calendar,
                color1: const Color(0xFFFF4081),
                color2: const Color(0xFF6200EA),
                type: "Plannings",
                subtitle: "Appuyez pour créer",
                screen: PlanningsPage(),
                index: 6,
              ),
              _quickAction(
                context,
                title: "ficher de paye",
                icon: LucideIcons.fileBarChart,
                color1: const Color(0xFFF06292),
                color2: const Color(0xFFF06292),
                type: "exit",
                subtitle: "Appuyez pour créer",
                screen: MesPaiesPage(),
                index: 7,
              ),
            ],
          ),
        ],
      ),
    );

    // Wrap with animations if available
    Widget animatedContent = (_fadeAnimation != null && _slideAnimation != null)
        ? FadeTransition(
            opacity: _fadeAnimation!,
            child: SlideTransition(
              position: _slideAnimation!,
              child: scrollContent,
            ),
          )
        : scrollContent;

    return Stack(
      children: [
        // Wave header with enhanced styling
        Align(
          alignment: Alignment.topCenter,
          child: ClipPath(
            clipper: _TopWaveClipper(),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00E5A0).withValues(alpha: 0.9),
                    const Color(0xFF00C6FF).withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C6FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(child: animatedContent),
      ],
    );
  }

  Widget _statPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color1,
    required Color color2,
    required String type,
    required String subtitle,
    required Widget screen,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ).then((_) {
            _fetchRequestCounts();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color2.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -18,
                child: Icon(
                  LucideIcons.circle,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
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
