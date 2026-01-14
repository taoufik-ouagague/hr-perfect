import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_perfect/controllers/conge_controller.dart';
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

  // ✅ CRITICAL: Initialize the CongeController
  final CongeController _congeController = Get.put(CongeController());

  DateTime? _dateDebut;
  DateTime? _dateFin;

  String? _messageReponse;
  Color? _couleurReponse;
  IconData? _iconeReponse;

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

  // ✅ FIXED: Clear previous messages and display backend MSG
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

    // 🔥 Clear any previous message before making the request
    setState(() {
      _messageReponse = null;
      _couleurReponse = null;
      _iconeReponse = null;
    });

    // Use controller's addConge method
    final result = await _congeController.addConge(
      libelle: _libelleController.text.trim(),
      dateDebut: _dateDebut!,
      dateFin: _dateFin!,
    );

    if (result['success'] == true) {
      final backendMessage = result['message'] ?? 'Demande soumise avec succès';

      // 🔥 Display backend success message
      _afficherMessageReponse(
        message: backendMessage,
        couleur: const Color(0xFF4CAF50),
        icone: Icons.check_circle_outline,
      );

      // Also show snackbar for better UX
      

      // Reset form
      _libelleController.clear();
      setState(() {
        _dateDebut = DateTime.now();
        _dateFin = DateTime.now().add(const Duration(days: 1));
        _dateDebutController.text = _formaterDate(_dateDebut!);
        _dateFinController.text = _formaterDate(_dateFin!);
      });
    } else {
      // 🔥 Display backend error message
      _afficherMessageReponse(
        message: result['message'] ?? 'La soumission a échoué',
        couleur: Colors.red,
        icone: Icons.error_outline,
      );
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
                    child: Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _congeController.isLoading.value 
                            ? null 
                            : _soumettre,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5A0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _congeController.isLoading.value
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
                    )),
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