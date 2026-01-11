import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hr_perfect/services/api_service.dart';
import 'package:hr_perfect/widgets/app_text_field.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../models/request_model.dart';

class CustomDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> items;
  final String? selectedValue;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final IconData prefixIcon;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
    this.prefixIcon = Icons.category_outlined,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Animation controller for dropdown opening
  AnimationController? _dropdownAnimationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _dropdownAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _dropdownAnimationController!,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _dropdownAnimationController!,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    // Remove overlay first before disposing controller
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOpen = false;
    }
    _dropdownAnimationController?.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    if (_dropdownAnimationController != null && _isOpen) {
      _dropdownAnimationController!.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        setState(() {
          _isOpen = false;
        });
      });
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOpen = false;
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Ensure animations are initialized
    if (_dropdownAnimationController == null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => _removeOverlay(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + -15),
                child: GestureDetector(
                  onTap: () {},
                  child: FadeTransition(
                    opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
                    child: ScaleTransition(
                      scale: _scaleAnimation ?? AlwaysStoppedAnimation(1.0),
                      alignment: Alignment.topCenter,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: widget.items.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      'Aucun résultat',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: widget.items.length,
                                    itemBuilder: (context, index) {
                                      final item = widget.items[index];
                                      final isSelected =
                                          widget.selectedValue == item;

                                      // Staggered animation for each item
                                      return TweenAnimationBuilder<double>(
                                        duration: Duration(
                                          milliseconds: 200 + (index * 50),
                                        ),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Transform.translate(
                                            offset: Offset(20 * (1 - value), 0),
                                            child: Opacity(
                                              opacity: value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: InkWell(
                                          onTap: () {
                                            widget.onChanged(item);
                                            _removeOverlay();
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            curve: Curves.easeInOut,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            color: isSelected
                                                ? const Color(
                                                    0xFF00C6FF,
                                                  ).withValues(alpha: 0.1)
                                                : Colors.transparent,
                                            child: Row(
                                              children: [
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  width: isSelected ? 3 : 2,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: isSelected
                                                          ? [
                                                              const Color(
                                                                0xFF00E5A0,
                                                              ),
                                                              const Color(
                                                                0xFF00C6FF,
                                                              ),
                                                            ]
                                                          : [
                                                              Colors.grey
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                              Colors.grey
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                            ],
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: AnimatedDefaultTextStyle(
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.w500,
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFF00C6FF,
                                                            )
                                                          : const Color(
                                                              0xFF374151,
                                                            ),
                                                    ),
                                                    child: Text(item),
                                                  ),
                                                ),
                                                AnimatedScale(
                                                  scale: isSelected ? 1.0 : 0.0,
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  curve: Curves.easeOutBack,
                                                  child: const Icon(
                                                    Icons.check_circle,
                                                    color: Color(0xFF00C6FF),
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
    _dropdownAnimationController?.forward();
  }

  String _getSelectedLabel() {
    if (widget.selectedValue == null) return widget.hint;
    return widget.selectedValue!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOpen ? const Color(0xFF00C6FF) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isOpen
                        ? const Color(0xFF00C6FF).withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: _isOpen ? 15 : 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _isOpen ? 0.125 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.prefixIcon,
                      color: const Color(0xFF00C6FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSelectedLabel(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: widget.selectedValue == null
                            ? Colors.grey
                            : const Color(0xFF111827),
                        fontWeight: widget.selectedValue == null
                            ? FontWeight.w400
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF00C6FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============== RESPONSE MESSAGE ==============
class ResponseMessage {
  final String message;
  final Color color;
  final IconData icon;

  const ResponseMessage({
    required this.message,
    required this.color,
    required this.icon,
  });

  factory ResponseMessage.success(String message) => ResponseMessage(
    message: message,
    color: Colors.green,
    icon: Icons.check_circle_outline,
  );

  factory ResponseMessage.error(String message) => ResponseMessage(
    message: message,
    color: Colors.red,
    icon: Icons.error_outline,
  );

  factory ResponseMessage.warning(String message) => ResponseMessage(
    message: message,
    color: Colors.orange,
    icon: Icons.warning_outlined,
  );
}

class MissionApiService {
  String url = _baseUrl;
  final Logger _logger = Logger();
  static const String _baseUrl = ApiService.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'token': token,
  };

  Future<List<String>> fetchMoyensTransport() async {
    final token = await _getToken();
    if (token == null) throw Exception('Aucun jeton d\'authentification');

    try {
      final response = await http.get(
        Uri.parse(ApiService.getMoyensTransports()),
        headers: _headers(token),
      );

      _logger.i('Moyens transport response: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => item['moyenTransport'] as String).toList();
        }
        throw Exception('Format de données invalide');
      }
      throw Exception('Échec de la récupération (${response.statusCode})');
    } catch (e) {
      _logger.e('Error fetching moyens transport: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchNbCheveaux() async {
    final token = await _getToken();
    if (token == null) throw Exception('Aucun jeton d\'authentification');

    try {
      final response = await http.get(
        Uri.parse(ApiService.getTransportsChevaux()),
        headers: _headers(token),
      );

      _logger.i('Nb Cheveaux response: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((item) => item['transportCheveaux'] as String)
              .toList();
        }
        throw Exception('Format de données invalide');
      }
      throw Exception('Échec de la récupération (${response.statusCode})');
    } catch (e) {
      _logger.e('Error fetching nb cheveaux: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitMission(MissionFormData data) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Impossible de s\'authentifier'};
    }

    try {
      final jsonData = data.toJson();
      final jsonBody = jsonEncode(jsonData);

      _logger.i('=== MISSION SUBMISSION DEBUG ===');
      _logger.i('URL: ${ApiService.addMissions()}');
      _logger.i('Headers: ${_headers(token)}');
      _logger.i(
        'Body (formatted): ${JsonEncoder.withIndent('  ').convert(jsonData)}',
      );
      _logger.i('Body (raw): $jsonBody');
      _logger.i('================================');

      final response = await http.post(
        Uri.parse(ApiService.addMissions()),
        headers: _headers(token),
        body: jsonBody,
      );

      _logger.i('=== RESPONSE DEBUG ===');
      _logger.i('Status code: ${response.statusCode}');
      _logger.i('Response headers: ${response.headers}');
      _logger.i('Response body: ${response.body}');
      _logger.i('=====================');

      if (response.statusCode == 200) {
        try {
          final responseJson = jsonDecode(response.body);
          _logger.i('Parsed response: $responseJson');

          if (responseJson is List && responseJson.isNotEmpty) {
            final msg =
                responseJson[0]['MSG'] ?? responseJson[0]['msg'] ?? 'Succès';
            return {'success': true, 'message': msg};
          } else if (responseJson is Map) {
            final msg =
                responseJson['MSG'] ??
                responseJson['msg'] ??
                responseJson['message'] ??
                'Succès';
            return {'success': true, 'message': msg};
          } else {
            return {
              'success': true,
              'message': 'La demande a été effectuée avec succès',
            };
          }
        } catch (e) {
          _logger.e('Error parsing response: $e');
          return {
            'success': true,
            'message': 'Demande soumise (réponse: ${response.body})',
          };
        }
      } else {
        _logger.e('Non-200 status code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erreur ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      _logger.e('Exception during submission: $e');
      return {'success': false, 'message': 'Erreur lors de l\'envoi: $e'};
    }
  }
}

// ============== ADD MISSION PAGE ==============
class AddMissionPage extends StatefulWidget {
  const AddMissionPage({super.key});

  @override
  State<AddMissionPage> createState() => _AddMissionPageState();
}

class _AddMissionPageState extends State<AddMissionPage>
    with SingleTickerProviderStateMixin {
  final _apiService = MissionApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _accompagnateurController;
  late final TextEditingController _matriculeController;
  late final TextEditingController _objetController;
  late final TextEditingController _marqueController;
  late final TextEditingController _dateDepartController;
  late final TextEditingController _dateRetourController;
  late final TextEditingController _designationController;

  DateTime? _dateDepart;
  DateTime? _dateRetour;
  bool _submitting = false;
  bool _loadingDropdowns = true;
  ResponseMessage? _responseMessage;
  String? _dropdownError;

  List<String> _moyensTransport = [];
  List<String> _nbCheveaux = [];
  final List<String> _carburantOptions = ['Diesel', 'Essence'];
  final List<String> _etrangerOptions = ['Non', 'Oui'];

  String _selectedHeureDepart = '08';
  String _selectedMinDepart = '00';
  String _selectedHeureRetour = '17';
  String _selectedMinRetour = '00';
  String? _selectedMoyenTransport;
  String? _selectedNbCheveaux;
  String _selectedCarburant = 'Diesel';
  String _selectedEtranger = 'Non';

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  List<String> get _hours =>
      List.generate(24, (i) => i.toString().padLeft(2, '0'));
  List<String> get _minutes =>
      List.generate(60, (i) => i.toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeControllers();
    _initializeDates();
    _loadDropdownData();
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

  void _initializeControllers() {
    _accompagnateurController = TextEditingController();
    _matriculeController = TextEditingController();
    _objetController = TextEditingController();
    _marqueController = TextEditingController();
    _dateDepartController = TextEditingController();
    _dateRetourController = TextEditingController();
    _designationController = TextEditingController();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _dateDepart = now;
    _dateRetour = now.add(const Duration(hours: 9));
    _dateDepartController.text = _formatDate(_dateDepart!);
    _dateRetourController.text = _formatDate(_dateRetour!);

    _selectedHeureDepart = now.hour.toString().padLeft(2, '0');
    _selectedMinDepart = now.minute.toString().padLeft(2, '0');
    final returnTime = now.add(const Duration(hours: 9));
    _selectedHeureRetour = returnTime.hour.toString().padLeft(2, '0');
    _selectedMinRetour = returnTime.minute.toString().padLeft(2, '0');
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _loadingDropdowns = true;
      _dropdownError = null;
    });

    try {
      final results = await Future.wait([
        _apiService.fetchMoyensTransport(),
        _apiService.fetchNbCheveaux(),
      ]);

      setState(() {
        _moyensTransport = results[0];
        _nbCheveaux = results[1];

        if (_moyensTransport.isEmpty || _nbCheveaux.isEmpty) {
          _dropdownError = 'Échec du chargement des options';
        } else {
          _selectedMoyenTransport = _moyensTransport.first;
          _selectedNbCheveaux = _nbCheveaux.first;
        }
      });
    } catch (e) {
      setState(() {
        _dropdownError = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _loadingDropdowns = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final initialDate = isDeparture
        ? (_dateDepart ?? DateTime.now())
        : (_dateRetour ?? DateTime.now());

final picked = await showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: DateTime(2000),
  lastDate: DateTime(2100),
  builder: (context, child) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10 * value,
            sigmaY: 10 * value,
          ),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child!,
              ),
            ),
          ),
        );
      },
    );
  },
);


    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _dateDepart = picked;
          _dateDepartController.text = _formatDate(picked);
        } else {
          _dateRetour = picked;
          _dateRetourController.text = _formatDate(picked);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_moyensTransport.isEmpty || _nbCheveaux.isEmpty) {
      _setResponseMessage(
        ResponseMessage.warning('Données non chargées. Veuillez réessayer.'),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _responseMessage = null;
    });

    try {
      final formData = MissionFormData(
        accompagnateur: _accompagnateurController.text.trim(),
        matricule: _matriculeController.text.trim(),
        objet: _objetController.text.trim(),
        carburant: _selectedCarburant,
        marque: _marqueController.text.trim(),
        etrange: _selectedEtranger,
        dateDepart: _dateDepartController.text.trim(),
        heureDepart: _selectedHeureDepart,
        minDepart: _selectedMinDepart,
        dateRetour: _dateRetourController.text.trim(),
        heureRetour: _selectedHeureRetour,
        minRetour: _selectedMinRetour,
        nbCheveaux: _selectedNbCheveaux ?? _nbCheveaux.first,
        moyenTransport: _selectedMoyenTransport ?? _moyensTransport.first,
        designation: _designationController.text.trim(),
      );

      final response = await _apiService.submitMission(formData);

      if (response['success'] == true) {
        final backendMessage =
            response['message'] ?? 'Demande soumise avec succès';
        _apiService._logger.i(
          '✅ Affichage du message backend: $backendMessage',
        );

        Get.snackbar(
          'Succès',
          backendMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          colorText: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        );

        _accompagnateurController.clear();
        _matriculeController.clear();
        _objetController.clear();
        _marqueController.clear();
        _designationController.clear();

        _initializeDates();

        setState(() {
          _selectedMoyenTransport = _moyensTransport.isNotEmpty
              ? _moyensTransport.first
              : null;
          _selectedNbCheveaux = _nbCheveaux.isNotEmpty
              ? _nbCheveaux.first
              : null;
          _selectedCarburant = 'Diesel';
          _selectedEtranger = 'Non';
        });
      } else {
        _setResponseMessage(
          ResponseMessage.error(
            response['message'] ?? 'Échec de la soumission',
          ),
        );
      }
    } catch (e) {
      _setResponseMessage(ResponseMessage.error('Erreur: $e'));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _setResponseMessage(ResponseMessage message) {
    setState(() => _responseMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: false, // We'll handle bottom padding manually
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5F7FB),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF111827),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Demande de mission',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody() {
    if (_loadingDropdowns) {
      return _buildLoadingState();
    }

    if (_dropdownError != null) {
      return _buildErrorState();
    }

    return _buildForm();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00E5A0)),
          const SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _dropdownError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDropdownData,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Réessayer',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5A0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    Widget scrollContent = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        // Add bottom padding that accounts for system navigation bar
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _HeaderCard(),
          ),
          const SizedBox(height: 22),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    _objetController,
                    'Objet',
                    'Entrez l\'objet de la mission',
                    Icons.note,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _accompagnateurController,
                    'Accompagnateur',
                    'Entrez la personne accompagnatrice',
                    Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    _dateDepartController,
                    'Date de Départ',
                    true,
                  ),
                  const SizedBox(height: 16),
                  _buildTimeRow(
                    _selectedHeureDepart,
                    _selectedMinDepart,
                    (h) => setState(() => _selectedHeureDepart = h!),
                    (m) => setState(() => _selectedMinDepart = m!),
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    _dateRetourController,
                    'Date de Retour',
                    false,
                  ),
                  const SizedBox(height: 16),
                  _buildTimeRow(
                    _selectedHeureRetour,
                    _selectedMinRetour,
                    (h) => setState(() => _selectedHeureRetour = h!),
                    (m) => setState(() => _selectedMinRetour = m!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _designationController,
                    'Désignation',
                    'Entrez la désignation',
                    Icons.label,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Étranger',
                    Icons.public,
                    _selectedEtranger,
                    _etrangerOptions,
                    (v) => setState(() => _selectedEtranger = v!),
                    key: ValueKey('etranger_$_selectedEtranger'),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Moyen de Transport',
                    Icons.directions_car,
                    _selectedMoyenTransport,
                    _moyensTransport,
                    (v) => setState(() => _selectedMoyenTransport = v),
                    key: ValueKey('transport_$_selectedMoyenTransport'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _marqueController,
                    'Marque',
                    'Entrez la marque du véhicule',
                    Icons.car_repair,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Nb Cheveaux',
                    Icons.speed,
                    _selectedNbCheveaux,
                    _nbCheveaux,
                    (v) => setState(() => _selectedNbCheveaux = v),
                    key: ValueKey('cheveaux_$_selectedNbCheveaux'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _matriculeController,
                    'Matricule',
                    'Entrez le matricule',
                    Icons.card_membership,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Carburant',
                    Icons.local_gas_station,
                    _selectedCarburant,
                    _carburantOptions,
                    (v) => setState(() => _selectedCarburant = v!),
                    key: ValueKey('carburant_$_selectedCarburant'),
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _buildSubmitButton(),
                  ),
                  if (_responseMessage != null) ...[
                    const SizedBox(height: 20),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: _ResponseMessageCard(message: _responseMessage!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Widget animatedContent = (_fadeAnimation != null)
        ? FadeTransition(opacity: _fadeAnimation!, child: scrollContent)
        : scrollContent;

    return animatedContent;
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
  ) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer $label';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(
    TextEditingController controller,
    String label,
    bool isDeparture,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context, isDeparture),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.text.isEmpty
                              ? 'Sélectionner'
                              : controller.text,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: controller.text.isEmpty
                                ? FontWeight.w400
                                : FontWeight.w600,
                            color: controller.text.isEmpty
                                ? Colors.grey
                                : const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5A0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF00E5A0),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    String hourValue,
    String minValue,
    void Function(String?) onHourChanged,
    void Function(String?) onMinChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: CustomDropdown(
            label: 'Heure',
            hint: 'HH',
            items: _hours,
            selectedValue: hourValue,
            prefixIcon: Icons.access_time,
            onChanged: onHourChanged,
            key: ValueKey('hour_$hourValue'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomDropdown(
            label: 'Minute',
            hint: 'MM',
            items: _minutes,
            selectedValue: minValue,
            prefixIcon: Icons.timer,
            onChanged: onMinChanged,
            key: ValueKey('min_$minValue'),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    String? currentValue,
    List<String> items,
    void Function(String?) onChanged, {
    Key? key,
  }) {
    return CustomDropdown(
      key: key,
      label: label,
      hint: 'Sélectionner ${label.toLowerCase()}',
      items: items,
      selectedValue: items.contains(currentValue)
          ? currentValue
          : (items.isNotEmpty ? items.first : null),
      prefixIcon: icon,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Requis';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5A0),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Soumettre la demande',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _accompagnateurController.dispose();
    _matriculeController.dispose();
    _objetController.dispose();
    _marqueController.dispose();
    _dateDepartController.dispose();
    _dateRetourController.dispose();
    _designationController.dispose();
    super.dispose();
  }
}

// ============== HEADER CARD ==============
class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A0).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.send_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle demande',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remplissez les informations ci-dessous',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== RESPONSE MESSAGE CARD ==============
class _ResponseMessageCard extends StatelessWidget {
  final ResponseMessage message;

  const _ResponseMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: message.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: message.color),
      ),
      child: Row(
        children: [
          Icon(message.icon, color: message.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.message,
              style: GoogleFonts.poppins(
                color: message.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}