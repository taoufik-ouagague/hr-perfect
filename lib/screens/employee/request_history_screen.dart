import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_perfect/screens/employee/employee_home.dart';
import 'package:hr_perfect/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/request_model.dart';

class TopWaveClipper extends CustomClipper<Path> {
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
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Sticky Header Delegate
class StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  StickyFilterDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.only(top: 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(StickyFilterDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}

// Helper functions for UI
IconData requestTypeIconByKey(String typeKey) {
  switch (typeKey.toLowerCase()) {
    case 'conge':
      return Icons.wb_sunny_outlined;
    case 'sortie':
      return Icons.logout_rounded;
    case 'attestation':
      return Icons.article_outlined;
    case 'mission':
      return Icons.task_alt;
    case 'reclamation':
      return Icons.error_outline;
    default:
      return Icons.help_outline;
  }
}

String requestTypeLabelByKey(String typeKey) {
  switch (typeKey.toLowerCase()) {
    case 'conge':
      return 'Congé';
    case 'sortie':
      return 'Sortie';
    case 'attestation':
      return 'Attestation';
    case 'mission':
      return 'Mission';
    case 'reclamation':
      return 'Réclamation';
    default:
      return typeKey;
  }
}

Color getTypeColor(String typeKey) {
  switch (typeKey.toLowerCase()) {
    case 'conge':
      return const Color(0xFF3B82F6);
    case 'attestation':
      return const Color(0xFF10B981);
    case 'sortie':
      return const Color(0xFFF59E0B);
    case 'mission':
      return const Color(0xFF8B5CF6);
    case 'reclamation':
      return const Color(0xFFEF4444);
    default:
      return Colors.grey;
  }
}

Color requestStatusColor(RequestStatus status) {
  switch (status) {
    case RequestStatus.demande:
      return const Color(0xFFFFA726);
    case RequestStatus.valide:
      return const Color(0xFF43A047);
    case RequestStatus.rejete:
      return const Color(0xFFE53935);
    case RequestStatus.annule:
      return const Color(0xFF90A4AE);
    case RequestStatus.enCours:
      return const Color(0xFF42A5F5);
  }
}

String requestStatusLabel(RequestStatus status) {
  switch (status) {
    case RequestStatus.demande:
      return 'Demande';
    case RequestStatus.valide:
      return 'Validé';
    case RequestStatus.rejete:
      return 'Rejeté';
    case RequestStatus.annule:
      return 'Annulé';
    case RequestStatus.enCours:
      return 'En cours';
  }
}

class RequestHistoryScreen extends StatefulWidget {
  final String userId;
  const RequestHistoryScreen({super.key, required this.userId});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  List<RequestModel> requests = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _q = '';
  RequestStatus? _statusFilter;
  String? _typeFilter = 'conge';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchRequests();
    _searchCtrl.addListener(_onSearchChanged);
    _animationController.forward();
  }

  void _onSearchChanged() {
    setState(() => _q = _searchCtrl.text.trim().toLowerCase());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchRequests() async {
    final token = await getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Session expirée. Reconnexion requise.')),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      if (!mounted) return;
      Future.microtask(() {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
      return;
    }

    final apiUrls = [
      ApiService.mesConges(),
      ApiService.demandesSorties(),
      ApiService.getTypesAttestations(),
      ApiService.missions(),
      ApiService.reclamations(),
    ];

    // 🔍 DEBUG: Log all API URLs
    _logger.i('=== FETCHING FROM ${apiUrls.length} APIS ===');
    for (var i = 0; i < apiUrls.length; i++) {
      _logger.i('API $i: ${apiUrls[i]}');
    }

    try {
      List<RequestModel> allRequests = [];

      final responses = await Future.wait(
        apiUrls.map(
          (url) => http.get(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', 'token': token},
          ),
        ),
      );

      for (var i = 0; i < responses.length; i++) {
        final response = responses[i];
        final url = apiUrls[i];

        _logger.i('GET $url => ${response.statusCode}');

        // 🔍 DEBUG: Special logging for réclamations
        if (url.contains('reclamations')) {
          _logger.i('━━━ RÉCLAMATIONS API RESPONSE ━━━');
          _logger.i('Status: ${response.statusCode}');
          _logger.i('Body length: ${response.body.length} chars');
          _logger.i('Body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
        }

        if (response.statusCode == 200) {
          try {
            final List<dynamic> data = jsonDecode(response.body);
            
            // 🔍 DEBUG: Log réclamation data before parsing
            if (url.contains('reclamations')) {
              _logger.i('Réclamations raw count: ${data.length}');
              if (data.isNotEmpty) {
                _logger.i('First réclamation: ${data[0]}');
              }
            }
            
            final parsed = data
                .map((e) => RequestModel.fromJson(e as Map<String, dynamic>))
                .toList();
            
            // 🔍 DEBUG: Log réclamation data after parsing
            if (url.contains('reclamations')) {
              _logger.i('Réclamations parsed count: ${parsed.length}');
              for (var req in parsed) {
                _logger.i('  - Type: ${req.type}, Title: ${req.title}, Status: ${req.status}');
              }
            }
            
            allRequests.addAll(parsed);
          } catch (e) {
            _logger.e('Error parsing response from $url: $e');
            
            // 🔍 DEBUG: Extra error info for réclamations
            if (url.contains('reclamations')) {
              _logger.e('❌ RÉCLAMATIONS PARSING FAILED');
              _logger.e('Error: $e');
              _logger.e('Response body: ${response.body}');
            }
          }
        } else if (response.statusCode == 401) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Session expirée. Veuillez vous reconnecter.'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          if (!mounted) return;
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
          return;
        }
      }

      // 🔍 DEBUG: Final summary
      final reclamationCount = allRequests.where((r) => r.type == 'reclamation').length;
      final congeCount = allRequests.where((r) => r.type == 'conge').length;
      final attestationCount = allRequests.where((r) => r.type == 'attestation').length;
      final sortieCount = allRequests.where((r) => r.type == 'sortie').length;
      final missionCount = allRequests.where((r) => r.type == 'mission').length;
      
      _logger.i('━━━ LOADING SUMMARY ━━━');
      _logger.i('  Congés: $congeCount');
      _logger.i('  Attestations: $attestationCount');
      _logger.i('  Sorties: $sortieCount');
      _logger.i('  Missions: $missionCount');
      _logger.i('  Réclamations: $reclamationCount');

      if (!mounted) return;
      setState(() {
        requests = allRequests;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Fetch error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur de connexion: ${e.toString().split(':').last}',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _fetchRequests,
          ),
        ),
      );
    }
  }

  List<RequestModel> get _visible {
    Iterable<RequestModel> list = requests;
    if (_typeFilter != null) {
      list = list.where(
        (r) => r.type.toLowerCase() == _typeFilter!.toLowerCase(),
      );
    }
    if (_statusFilter != null) {
      list = list.where((r) => r.status == _statusFilter);
    }
    if (_q.isNotEmpty) {
      list = list.where((r) {
        final hay = '${r.title} ${r.reason} ${r.type}'.toLowerCase();
        return hay.contains(_q);
      });
    }
    final out = list.toList();
    out.sort((a, b) {
      final yearCompare = b.createdYear.compareTo(a.createdYear);
      if (yearCompare != 0) return yearCompare;
      return b.startDate.compareTo(a.startDate);
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    
    final pending = requests
        .where((r) => r.status == RequestStatus.demande)
        .length;
    final enCours = requests
        .where((r) => r.status == RequestStatus.enCours)
        .length;
    final approved = requests
        .where((r) => r.status == RequestStatus.valide)
        .length;
    final rejected = requests
        .where((r) => r.status == RequestStatus.rejete)
        .length;
    final visible = _visible;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                ),
              ),
            ),
          ),
          // Wave header with glass effect
          Align(
            alignment: Alignment.topCenter,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                height: 240,
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
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _fetchRequests,
                color: const Color(0xFF00C6FF),
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // App Bar
                    SliverToBoxAdapter(child: _buildAppBar()),

                    // Header Stats
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildHeaderStats(
                          pending: pending,
                          enCours: enCours,
                          approved: approved,
                          rejected: rejected,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: const SizedBox(height: 16)),

                    // Sticky Filters Section
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: StickyFilterDelegate(
                        height: 185,
                        child: Column(
                          children: [
                            // Search Bar
                            _buildSearchBar(),
                            const SizedBox(height: 12),
                            // Status Filters
                            _buildStatusFilters(),
                            const SizedBox(height: 12),
                            // Type Filters
                            _buildTypeFilters(),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    if (_isLoading)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00C6FF),
                                ),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chargement des demandes...',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (visible.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildCard(visible[index], index),
                            childCount: visible.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeHome(userId: widget.userId),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mes demandes",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _fetchRequests,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Rechercher une demande...",
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[400],
              size: 22,
            ),
            suffixIcon: _q.isNotEmpty
                ? IconButton(
                    onPressed: () => _searchCtrl.clear(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(
            "Demande",
            _statusFilter == RequestStatus.demande,
            () => setState(
              () => _statusFilter = _statusFilter == RequestStatus.demande
                  ? null
                  : RequestStatus.demande,
            ),
            const Color(0xFFFFA726),
          ),
          const SizedBox(width: 10),
          _chip(
            "En cours",
            _statusFilter == RequestStatus.enCours,
            () => setState(
              () => _statusFilter = _statusFilter == RequestStatus.enCours
                  ? null
                  : RequestStatus.enCours,
            ),
            const Color(0xFF42A5F5),
          ),
          const SizedBox(width: 10),
          _chip(
            "Validé",
            _statusFilter == RequestStatus.valide,
            () => setState(
              () => _statusFilter = _statusFilter == RequestStatus.valide
                  ? null
                  : RequestStatus.valide,
            ),
            const Color(0xFF43A047),
          ),
          const SizedBox(width: 10),
          _chip(
            "Rejeté",
            _statusFilter == RequestStatus.rejete,
            () => setState(
              () => _statusFilter = _statusFilter == RequestStatus.rejete
                  ? null
                  : RequestStatus.rejete,
            ),
            const Color(0xFFE53935),
          ),
          const SizedBox(width: 10),
          _chip(
            "Annulé",
            _statusFilter == RequestStatus.annule,
            () => setState(
              () => _statusFilter = _statusFilter == RequestStatus.annule
                  ? null
                  : RequestStatus.annule,
            ),
            const Color(0xFF90A4AE),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _typeChip(
            "Congé",
            _typeFilter == 'conge',
            'conge',
            () => setState(
              () => _typeFilter = _typeFilter == 'conge' ? null : 'conge',
            ),
          ),
          const SizedBox(width: 10),
          _typeChip(
            "Attestation",
            _typeFilter == 'attestation',
            'attestation',
            () => setState(
              () => _typeFilter = _typeFilter == 'attestation'
                  ? null
                  : 'attestation',
            ),
          ),
          const SizedBox(width: 10),
          _typeChip(
            "Sortie",
            _typeFilter == 'sortie',
            'sortie',
            () => setState(
              () => _typeFilter = _typeFilter == 'sortie' ? null : 'sortie',
            ),
          ),
          const SizedBox(width: 10),
          _typeChip(
            "Mission",
            _typeFilter == 'mission',
            'mission',
            () => setState(
              () => _typeFilter = _typeFilter == 'mission' ? null : 'mission',
            ),
          ),
          const SizedBox(width: 10),
          _typeChip(
            "Réclamation",
            _typeFilter == 'reclamation',
            'reclamation',
            () => setState(
              () => _typeFilter = _typeFilter == 'reclamation'
                  ? null
                  : 'reclamation',
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, Color color) {
    return Material(
      color: selected ? color.withValues(alpha: 0.15) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: selected ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? color : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
  String label,
  bool selected,
  String? typeKey,
  VoidCallback onTap,
) {
  Color chipColor = typeKey != null
      ? getTypeColor(typeKey)
      : const Color(0xFF0072FF);
  IconData? chipIcon = typeKey != null ? requestTypeIconByKey(typeKey) : null;

  return Material(
    color: selected ? chipColor.withValues(alpha: 0.12) : Colors.white,
    borderRadius: BorderRadius.circular(12),
    elevation: selected ? 0 : 2,
    shadowColor: Colors.black.withValues(alpha: 0.05),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          // Toggle the type filter
          final newTypeFilter = _typeFilter == typeKey ? null : typeKey;
          _typeFilter = newTypeFilter;
          
          // Set default status based on type
          if (newTypeFilter != null) {
            if (typeKey == 'reclamation') {
              // Réclamation defaults to "En cours"
              _statusFilter = RequestStatus.enCours;
            } else {
              // All other types default to "Demande"
              _statusFilter = RequestStatus.demande;
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? chipColor : Colors.grey.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chipIcon != null) ...[
              Icon(
                chipIcon,
                size: 18,
                color: selected ? chipColor : Colors.grey[600],
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? chipColor : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeaderStats({
    required int pending,
    required int enCours,
    required int approved,
    required int rejected,
  }) {
    return Container(
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
         
          const SizedBox(width: 12),
          _statChip(
            label: "Demande",
            value: pending.toString(),
            color: const Color(0xFFFFA726),
          ),
          const SizedBox(width: 12),
          _statChip(
            label: "En cours",
            value: enCours.toString(),
            color: const Color(0xFF42A5F5),
          ),
          const SizedBox(width: 12),
          _statChip(
            label: "Validé",
            value: approved.toString(),
            color: const Color(0xFF43A047),
          ),
          const SizedBox(width: 12),
          _statChip(
            label: "Rejeté",
            value: rejected.toString(),
            color: const Color(0xFFE53935),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
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
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(RequestModel r, int index) {
    final range =
        "${DateFormat('dd/MM').format(r.startDate)} - ${DateFormat('dd/MM').format(r.endDate)}";
    final statusCol = requestStatusColor(r.status);
    final statusLabel = requestStatusLabel(r.status);
    final typeKey = r.typeKey;
    final icon = requestTypeIconByKey(typeKey);
    final typeLabel = requestTypeLabelByKey(typeKey);
    final typeColor = getTypeColor(typeKey);
    final isAttestation = typeKey.toLowerCase() == 'attestation';
    final isMission = typeKey.toLowerCase() == 'mission';
    final isSortie = typeKey.toLowerCase() == 'sortie';
    final isReclamation = typeKey.toLowerCase() == 'reclamation';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: typeColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Add navigation to detail screen
            },
            child: Stack(
              children: [
                // Accent bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [typeColor, typeColor.withValues(alpha: 0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container with gradient
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              typeColor.withValues(alpha: 0.85),
                              typeColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: typeColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badges row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: typeColor.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, size: 12, color: typeColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        typeLabel,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: typeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: statusCol.withValues(alpha: 0.12),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: statusCol,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Title
                            Text(
                              r.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Details
                            if (isAttestation && r.derniereDemande != null)
                              _buildInfoRow(
                                Icons.update_rounded,
                                "Dernière: ${r.derniereDemande}",
                              ),
                            if (isSortie &&
                                ((r.dateSortie != null &&
                                        r.dateSortie!.isNotEmpty) ||
                                    (r.heureSortieDebut != null &&
                                        r.heureSortieFin != null)))
                              _buildInfoRow(
                                Icons.event_rounded,
                                "${r.dateSortie ?? ''} ${r.heureSortieDebut != null && r.heureSortieFin != null ? '${r.heureSortieDebut} - ${r.heureSortieFin}' : ''}"
                                    .trim(),
                              ),
                            if (isMission) ...[
                              if (r.moyenTransport != null &&
                                  r.moyenTransport!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.directions_car_rounded,
                                  r.moyenTransport!,
                                ),
                              if (r.nbCheveaux != null &&
                                  r.nbCheveaux!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.speed_rounded,
                                  r.nbCheveaux!,
                                ),
                              if (r.formattedMissionDepart != null)
                                _buildInfoRow(
                                  Icons.flight_takeoff_rounded,
                                  "Départ: ${r.formattedMissionDepart}",
                                ),
                              if (r.formattedMissionRetour != null)
                                _buildInfoRow(
                                  Icons.flight_land_rounded,
                                  "Retour: ${r.formattedMissionRetour}",
                                ),
                            ],
                            if (isReclamation) ...[
                              if (r.typeReclamation != null &&
                                  r.typeReclamation!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.category_outlined,
                                  "Type: ${r.typeReclamation}",
                                ),
                              if (r.dateTraitement != null &&
                                  r.dateTraitement!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.schedule_rounded,
                                  "Traitement: ${r.dateTraitement}",
                                ),
                            ],
                            if (!isAttestation &&
                                !isMission &&
                                !isSortie &&
                                !isReclamation)
                              _buildInfoRow(
                                Icons.calendar_today_rounded,
                                range,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 56,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Aucune demande trouvée",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Essayez d'ajuster vos filtres ou ajoutez une nouvelle demande.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                  _typeFilter = null;
                  _searchCtrl.clear();
                });
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text(
                'Réinitialiser les filtres',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C6FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                elevation: 4,
                shadowColor: const Color(0xFF00C6FF).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}