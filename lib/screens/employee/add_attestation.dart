import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hr_perfect/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddAttestationPage extends StatefulWidget {
  const AddAttestationPage({super.key});

  @override
  State<AddAttestationPage> createState() => _AddAttestationPageState();
}

class _AddAttestationPageState extends State<AddAttestationPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
 
  List<Map<String, dynamic>> _attestationTypes = [];
  String? _selectedType;

  bool _submitting = false;
  String? _responseMessage;
  Color? _responseColor;
  IconData? _responseIcon;

  final Logger _logger = Logger();
  late DateTime _requestDate;

  // Animation controller
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _requestDate = DateTime.now();
    _fetchAttestationTypes();
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

  // Format the date to dd/MM/yyyy
  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  // Fetch attestation types from the API
  Future<void> _fetchAttestationTypes() async {
    try {
      final token = await getToken();

      if (token == null) {
        _showResponseMessage(
          message: 'Le jeton est manquant ou invalide',
          color: Colors.red,
          icon: Icons.error_outline,
        );
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.getTypesAttestations()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _attestationTypes = data
              .map((item) => {'libelle': item['libelle'], 'id': item['id']})
              .toList();
        });
      } else {
        _logger.i('Erreur: ${response.statusCode}, Corps: ${response.body}');
        _showResponseMessage(
          message: 'Échec du chargement des types d\'attestation',
          color: Colors.red,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      _logger.e('Erreur lors de la récupération des types d\'attestation: $e');
      _showResponseMessage(
        message: 'Erreur lors de la récupération des types d\'attestation',
        color: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  // Submit the form
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedType == null) {
      _showResponseMessage(
        message: 'Veuillez sélectionner un type d\'attestation',
        color: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() {
      _submitting = true;
      _responseMessage = null;
    });

    try {
      final response = await _sendRequest(_selectedType!);

      if (response['success'] == true) {
        final backendMessage = response['message'] ?? 'Demande soumise avec succès';
        _logger.i('✅ Affichage du message backend: $backendMessage');
        
        Get.snackbar(
          'Succès',
          backendMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          colorText: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        );
        
        // Reset the form after successful submission
        setState(() {
          _selectedType = null;
          _requestDate = DateTime.now();
        });
      } else {
        _showResponseMessage(
          message: response['message'] ?? 'Échec de la soumission de la demande',
          color: Colors.red,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      _logger.e('Erreur lors de la soumission: $e');
      _showResponseMessage(
        message: 'Erreur lors de la soumission: $e',
        color: Colors.red,
        icon: Icons.error_outline,
      );
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  // Get token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Send request to the API
  Future<Map<String, dynamic>> _sendRequest(String typeId) async {
    final token = await getToken();

    if (token == null) {
      return {'success': false, 'message': 'Impossible de s\'authentifier'};
    }

    String url = ApiService.addAttestations(int.parse(typeId));
    try {
      final requestBody = {
        'dateDebut': _formatDate(_requestDate),
        'dateFin': _formatDate(_requestDate),
      };

      _logger.i('Envoi de la requête vers: $url');
      _logger.i('Corps de la requête: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode(requestBody),
      );

      _logger.i('Statut de la réponse: ${response.statusCode}');
      _logger.i('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseJson = jsonDecode(response.body);
          
          if (responseJson is List && responseJson.isNotEmpty) {
            final msg = responseJson[0]['MSG'] ?? 'La demande a été effectuée avec succès';
            return {'success': true, 'message': msg};
          } else if (responseJson is Map) {
            final msg = responseJson['MSG'] ?? 
                       responseJson['message'] ?? 
                       'La demande a été effectuée avec succès';
            return {'success': true, 'message': msg};
          } else {
            return {'success': true, 'message': 'La demande a été effectuée avec succès'};
          }
        } catch (e) {
          _logger.e('Erreur lors de l\'analyse de la réponse: $e');
          return {'success': true, 'message': 'La demande a été effectuée avec succès'};
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Échec de l\'authentification. Veuillez vous reconnecter.'};
      } else {
        return {
          'success': false,
          'message': 'La demande a échoué avec le statut: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'envoi de la requête: $e');
      return {'success': false, 'message': 'Erreur réseau: Impossible de se connecter au serveur'};
    }
  }

  // Show response message in the UI
  void _showResponseMessage({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    setState(() {
      _responseMessage = message;
      _responseColor = color;
      _responseIcon = icon;
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // Build Header Card for the top section
  Widget _buildHeaderCard() {
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.description_outlined,
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
                  'Nouvelle demande d\'attestation',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sélectionnez le type d\'attestation que vous souhaitez demander.',
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

  // Build the response message
  Widget _buildResponseMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _responseColor?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _responseColor ?? Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _responseIcon,
            color: _responseColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _responseMessage!,
              style: GoogleFonts.poppins(
                color: _responseColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build radio button option
  Widget _buildRadioOption(Map<String, dynamic> item, int index) {
    final isSelected = _selectedType == item['id'].toString();
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = item['id'].toString();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5A0).withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5A0) : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5A0).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00E5A0) : Colors.grey.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  color: Colors.white,
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item['libelle'],
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF111827) : const Color(0xFF374151),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00E5A0),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Build date display card
  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date de la demande',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(_requestDate),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5A0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Aujourd\'hui',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00E5A0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget scrollContent = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildHeaderCard(),
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildDateCard(),
                ),
                const SizedBox(height: 22),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 650),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: Text(
                    'Type d\'attestation',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_attestationTypes.isEmpty)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF00E5A0),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ..._attestationTypes.asMap().entries.map(
                    (entry) => _buildRadioOption(entry.value, entry.key),
                  ),
                const SizedBox(height: 26),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 700),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5A0),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
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
                  ),
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
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildResponseMessage(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Wrap with fade animation if available
    Widget animatedContent = (_fadeAnimation != null)
        ? FadeTransition(
            opacity: _fadeAnimation!,
            child: scrollContent,
          )
        : scrollContent;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
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
          'Demande d\'attestation',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 39, 26, 17),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: animatedContent,
      ),
    );
  }
}