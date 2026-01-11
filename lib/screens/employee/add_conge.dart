import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_perfect/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_text_field.dart';

class AddCongePage extends StatefulWidget {
  const AddCongePage({super.key});

  @override
  State<AddCongePage> createState() => _AddCongePageState();
}

class _AddCongePageState extends State<AddCongePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();

  DateTime? _dateDebut;
  DateTime? _dateFin;

  bool _enCoursDesoumission = false;
  String? _messageReponse;
  Color? _couleurReponse;
  IconData? _iconeReponse;

  final Logger _logger = Logger();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    _dateDebut = DateTime.now();
    _dateFin = DateTime.now().add(const Duration(days: 1));

    _dateDebutController.text = _formaterDate(_dateDebut!);
    _dateFinController.text = _formaterDate(_dateFin!);
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  String _formaterDate(DateTime d) {
    final jour = d.day.toString().padLeft(2, '0');
    final mois = d.month.toString().padLeft(2, '0');
    final annee = d.year.toString();
    return '$jour/$mois/$annee';
  }

  String _decodeBody(http.Response r) {
    try {
      return utf8.decode(r.bodyBytes);
    } catch (_) {
      return r.body;
    }
  }

  String? _extractMsg(dynamic decoded) {
    try {
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map && first['MSG'] != null) {
          return first['MSG'].toString();
        }
      }
      if (decoded is Map && decoded['MSG'] != null) {
        return decoded['MSG'].toString();
      }
    } catch (_) {}
    return null;
  }

  bool _looksLikeErrorMsg(String msg) {
    final m = msg.toLowerCase();
    return msg.contains('!!') ||
        m.contains('erreur') ||
        m.contains('échec') ||
        m.contains('echec') ||
        m.contains('impossible') ||
        m.contains('à cheval') ||
        m.contains('a cheval');
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateDebut == null || _dateFin == null) {
      _afficherMessageReponse(
        message: 'Veuillez sélectionner les dates de début et de fin',
        couleur: Colors.red,
        icone: Icons.error_outline,
      );
      return;
    }

    setState(() {
      _enCoursDesoumission = true;
      _messageReponse = null;
    });

    try {
      final requete = {
        'libelle': _libelleController.text.trim(),
        'dateDebut': _dateDebut!,
        'dateFin': _dateFin!,
      };

      final reponse = await _envoyerRequete(requete);

      if (reponse['succes'] == true) {
        final backendMessage =
            (reponse['message'] ?? 'Demande soumise avec succès').toString();

        _logger.i('✅ Message backend: $backendMessage');

        Get.snackbar(
          'Succès',
          backendMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          colorText: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        );

        _libelleController.clear();

        setState(() {
          _dateDebut = DateTime.now();
          _dateFin = DateTime.now().add(const Duration(days: 1));
          _dateDebutController.text = _formaterDate(_dateDebut!);
          _dateFinController.text = _formaterDate(_dateFin!);
        });
      } else {
        _afficherMessageReponse(
          message: (reponse['message'] ?? 'La soumission a échoué').toString(),
          couleur: Colors.red,
          icone: Icons.error_outline,
        );
      }
    } catch (e) {
      _logger.e('Erreur lors de la soumission: $e');
      _afficherMessageReponse(
        message: 'Erreur lors de la soumission: $e',
        couleur: Colors.red,
        icone: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          _enCoursDesoumission = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _envoyerRequete(
    Map<String, dynamic> requete,
  ) async {
    final token = await obtenirToken();

    if (token == null) {
      _logger.w('Token null - échec authentification');
      return {'succes': false, 'message': 'Impossible de s\'authentifier'};
    }

    try {
      final corpsRequete = {
        'libelle': requete['libelle'],
        'dateDebut': _formaterDate(requete['dateDebut']),
        'dateFin': _formaterDate(requete['dateFin']),
        'ttjourneDebut': 'tout',
        'ttjourneFin': 'tout',
      };

      final url = ApiService.addConges();

      _logger.i('POST => $url');
      _logger.i('Body => ${jsonEncode(corpsRequete)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'token': token},
        body: jsonEncode(corpsRequete),
      );

      final body = _decodeBody(response);

      _logger.i('Status => ${response.statusCode}');
      _logger.i('Response => $body');

      dynamic decoded;
      try {
        decoded = body.isEmpty ? null : jsonDecode(body);
      } catch (_) {
        decoded = null;
      }

      final msg = decoded != null ? _extractMsg(decoded) : null;

      if (msg != null && msg.trim().isNotEmpty) {
        final isOk =
            response.statusCode == 200 && !_looksLikeErrorMsg(msg.trim());
        return {'succes': isOk, 'message': msg.trim()};
      }

      if (response.statusCode == 200) {
        return {'succes': true, 'message': 'Demande soumise avec succès'};
      }

      if (response.statusCode == 401) {
        return {
          'succes': false,
          'message': 'Échec de l\'authentification. Veuillez vous reconnecter.',
        };
      }

      if (response.statusCode == 400) {
        return {
          'succes': false,
          'message': 'Requête invalide. Vérifiez les champs saisis.',
        };
      }

      if (response.statusCode == 500) {
        return {
          'succes': false,
          'message': 'Erreur du serveur. Veuillez réessayer plus tard.',
        };
      }

      return {
        'succes': false,
        'message': 'La demande a échoué (statut: ${response.statusCode})',
      };
    } catch (e) {
      _logger.e('Erreur réseau: $e');

      final es = e.toString();
      if (es.contains('SocketException') || es.contains('HandshakeException')) {
        return {
          'succes': false,
          'message': 'Erreur réseau. Vérifiez votre connexion Internet.',
        };
      }

      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }

  Future<String?> obtenirToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      _logger.i('Token récupéré: ${token != null ? "existe" : "null"}');
      return token;
    } catch (e) {
      _logger.e('Erreur token: $e');
      return null;
    }
  }

  void _afficherMessageReponse({
    required String message,
    required Color couleur,
    required IconData icone,
  }) {
    setState(() {
      _messageReponse = message;
      _couleurReponse = couleur;
      _iconeReponse = icone;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _libelleController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Widget _buildDateField(
    TextEditingController controller,
    String label,
    bool isDateDebut,
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
            onTap: isDateDebut ? _choisirDateDebut : _choisirDateFin,
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
                      Icons.event_note_rounded,
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

  @override
  Widget build(BuildContext context) {
    final scrollContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: _construireCarteEntete(),
          ),
          const SizedBox(height: 22),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _libelleController,
                    label: 'Raison',
                    hint: 'Décrivez brièvement votre demande de congé',
                    icon: Icons.notes_outlined,
                    validator: (valeur) {
                      if (valeur == null || valeur.trim().isEmpty) {
                        return 'Requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(_dateDebutController, 'Date de début', true),
                  const SizedBox(height: 16),
                  _buildDateField(_dateFinController, 'Date de fin', false),
                  const SizedBox(height: 26),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enCoursDesoumission ? null : _soumettre,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5A0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _enCoursDesoumission
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
                  if (_messageReponse != null) ...[
                    const SizedBox(height: 20),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        final safeOpacity = value.clamp(0.0, 1.0);
                        final safeScale = value.clamp(0.0, 1.25);

                        return Transform.scale(
                          scale: safeScale,
                          child: Opacity(opacity: safeOpacity, child: child),
                        );
                      },
                      child: _construireMessageReponse(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

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
          'Demande de congé',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(opacity: _fadeAnimation, child: scrollContent),
    );
  }

  Widget _construireCarteEntete() {
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
                  'Remplissez les informations ci-dessous pour soumettre votre demande.',
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

  Widget _construireMessageReponse() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: _couleurReponse?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_iconeReponse, color: _couleurReponse),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _messageReponse ?? '',
              style: TextStyle(
                color: _couleurReponse,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _choisirDateDebut() async {
    final maintenant = DateTime.now();
    final selectionne = await showDatePicker(
      context: context,
      initialDate: _dateDebut ?? maintenant,
      firstDate: DateTime(maintenant.year - 1),
      lastDate: DateTime(maintenant.year + 2),
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

    if (selectionne != null) {
      setState(() {
        _dateDebut = selectionne;
        _dateDebutController.text = _formaterDate(selectionne);

        if (_dateFin == null || _dateFin!.isBefore(selectionne)) {
          _dateFin = selectionne;
          _dateFinController.text = _formaterDate(selectionne);
        }
      });
    }
  }

  Future<void> _choisirDateFin() async {
    final base = _dateDebut ?? DateTime.now();
    final selectionne = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? base,
      firstDate: base,
      lastDate: DateTime(base.year + 2),
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

    if (selectionne != null) {
      setState(() {
        _dateFin = selectionne;
        _dateFinController.text = _formaterDate(selectionne);
      });
    }
  }
}