import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hr_perfect/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_text_field.dart';
import 'dart:ui';


class AddPretPage extends StatefulWidget {
  const AddPretPage({super.key});

  @override
  State<AddPretPage> createState() => _AddPretPageState();
}

class _AddPretPageState extends State<AddPretPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _motifPretController = TextEditingController();
  final _datePretController = TextEditingController();
  final _montantPretController = TextEditingController();

  DateTime? _datePret;
  bool _enCoursDesoumission = false;
  String? _messageReponse;
  Color? _couleurReponse;
  IconData? _iconeReponse;

  final Logger _logger = Logger();

  // Animation controller
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    final maintenant = DateTime.now();
    _datePret = maintenant;
    _datePretController.text = _formaterDate(_datePret!);
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

  String _formaterDate(DateTime d) {
    final jour = d.day.toString().padLeft(2, '0');
    final mois = d.month.toString().padLeft(2, '0');
    final annee = d.year.toString();
    return '$jour/$mois/$annee';
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_datePret == null || _montantPretController.text.isEmpty) {
      _afficherMessageReponse(
        message: 'Veuillez remplir tous les champs requis',
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
        'motifPret': _motifPretController.text.trim(),
        'datePret': _datePret!,
        'montantPret': double.tryParse(_montantPretController.text) ?? 0,
      };

      final reponse = await _envoyerRequete(requete);

      if (reponse['succes'] == true) {
        // Extract MSG from backend response
        final backendMessage = reponse['message'] ?? 'Demande de prêt soumise avec succès';
        _logger.i('✅ Message du backend (MSG): $backendMessage');
        
        // Show success snackbar with backend message
        Get.snackbar(
          'Succès',
          backendMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          colorText: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        
        // Reset the form after successful submission
        _motifPretController.clear();
        _montantPretController.clear();
        final maintenant = DateTime.now();
        setState(() {
          _datePret = maintenant;
          _datePretController.text = _formaterDate(_datePret!);
        });
      } else {
        // Show error with backend message
        final errorMessage = reponse['message'] ?? 'La soumission de la demande a échoué';
        _logger.e('❌ Erreur du backend: $errorMessage');
        
        _afficherMessageReponse(
          message: errorMessage,
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
      setState(() {
        _enCoursDesoumission = false;
      });
    }
  }

  Future<Map<String, dynamic>> _envoyerRequete(Map<String, dynamic> requete) async {
    String url = ApiService.addDemandesPrets();
    final token = await obtenirToken();

    if (token == null) {
      _logger.w('Le token est null - échec de l\'authentification');
      return {'succes': false, 'message': 'Impossible de s\'authentifier'};
    }

    try {
      final corpsRequete = {
        'motifPret': requete['motifPret'],
        'datePret': _formaterDate(requete['datePret']),
        'montantPret': requete['montantPret'],
      };

      _logger.i('Envoi de la requête à: $url');
      _logger.i('Corps de la requête: ${jsonEncode(corpsRequete)}');

      final reponse = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode(corpsRequete),
      );

      _logger.i('Statut de la réponse: ${reponse.statusCode}');
      _logger.i('Corps de la réponse: ${reponse.body}');

      if (reponse.statusCode == 200) {
        try {
          if (reponse.body.isEmpty) {
            _logger.w('Le corps de la réponse est vide');
            return {'succes': false, 'message': 'Réponse vide du serveur'};
          }

          final reponseJson = jsonDecode(reponse.body);
          _logger.i('Réponse analysée: $reponseJson');

          if (reponseJson is List && reponseJson.isNotEmpty) {
            final premierElement = reponseJson[0];
            final msg = premierElement['MSG'] as String?;
            
            if (msg == null || msg.isEmpty) {
              return {'succes': true, 'message': 'Demande soumise avec succès'};
            }
            
            final estErreur = msg.contains('!!') || 
                             msg.toLowerCase().contains('erreur') ||
                             msg.toLowerCase().contains('échec') ||
                             msg.toLowerCase().contains('impossible');
            
            return {
              'succes': !estErreur,
              'message': msg,
            };
          } else if (reponseJson is Map) {
            final msg = reponseJson['MSG'] as String?;
            
            if (msg == null || msg.isEmpty) {
              return {'succes': true, 'message': 'Demande soumise avec succès'};
            }
            
            final estErreur = msg.contains('!!') || 
                             msg.toLowerCase().contains('erreur') ||
                             msg.toLowerCase().contains('échec') ||
                             msg.toLowerCase().contains('impossible');
            
            return {
              'succes': !estErreur,
              'message': msg,
            };
          } else {
            return {'succes': false, 'message': 'Format de réponse inattendu'};
          }
        } catch (e) {
          _logger.e('Erreur lors de l\'analyse de la réponse: $e');
          return {'succes': false, 'message': 'Erreur lors de l\'analyse de la réponse'};
        }
      } else if (reponse.statusCode == 401) {
        return {
          'succes': false, 
          'message': 'Échec de l\'authentification. Veuillez vous reconnecter.'
        };
      } else if (reponse.statusCode == 400) {
        return {
          'succes': false, 
          'message': 'Demande invalide. Veuillez vérifier les informations.'
        };
      } else if (reponse.statusCode == 500) {
        return {
          'succes': false, 
          'message': 'Erreur du serveur. Veuillez réessayer plus tard.'
        };
      } else {
        return {
          'succes': false,
          'message': 'La demande a échoué avec le statut: ${reponse.statusCode}',
        };
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'envoi de la requête: $e');
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('HandshakeException')) {
        return {
          'succes': false, 
          'message': 'Erreur réseau. Veuillez vérifier votre connexion Internet.'
        };
      }
      
      return {'succes': false, 'message': 'Erreur lors de l\'envoi de la requête: $e'};
    }
  }

  Future<String?> obtenirToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      _logger.i('Token récupéré: ${token != null ? "existe" : "null"}');
      return token;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du token: $e');
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
    _animationController?.dispose();
    _motifPretController.dispose();
    _datePretController.dispose();
    _montantPretController.dispose();
    super.dispose();
  }

  // New date field builder matching AddCongePage design
  Widget _buildDateField(
    TextEditingController controller,
    String label,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.transparent,
                  width: 2,
                ),
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
                    child: Text(
                      controller.text.isEmpty ? 'Sélectionner' : controller.text,
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
    Widget scrollContent = SingleChildScrollView(
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
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
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
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _motifPretController,
                    label: 'Motif du prêt',
                    hint: 'Indiquez le motif du prêt',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    validator: (valeur) {
                      if (valeur == null || valeur.trim().isEmpty) {
                        return 'Veuillez entrer un motif';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _montantPretController,
                    label: 'Montant du prêt',
                    hint: 'Indiquez le montant du prêt',
                    icon: Icons.attach_money_outlined,
                    keyboardType: TextInputType.number,
                    validator: (valeur) {
                      if (valeur == null || valeur.trim().isEmpty) {
                        return 'Veuillez entrer un montant';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Updated date field with new design
                  _buildDateField(
                    _datePretController,
                    'Date du prêt',
                    _choisirDatePret,
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
                          child: Opacity(
                            opacity: safeOpacity,
                            child: child,
                          ),
                        );
                      },
                      child: _construireMessageReponse(),
                    ),
                  ]
                ],
              ),
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
          'Demande de prêt',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        centerTitle: false,
      ),
      body: animatedContent,
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
          Icon(
            _iconeReponse,
            color: _couleurReponse,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _messageReponse!,
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

  Future<void> _choisirDatePret() async {
    final maintenant = DateTime.now();
    final selectionne = await showDatePicker(
  context: context,
  initialDate: _datePret ?? maintenant,
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
        _datePret = selectionne;
        _datePretController.text = _formaterDate(selectionne);
      });
    }
  }
}