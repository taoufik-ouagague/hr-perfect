import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hr_perfect/controllers/reclamation_controller.dart';
import '../../widgets/app_text_field.dart';
import 'dart:ui';

class AddReclamationsPage extends StatefulWidget {
  const AddReclamationsPage({super.key});

  @override
  State<AddReclamationsPage> createState() => _AddReclamationsPageState();
}

class _AddReclamationsPageState extends State<AddReclamationsPage> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _reclamationController = TextEditingController();
  final _dateReclamationController = TextEditingController();
  final _dateTraitementController = TextEditingController();

  // Initialize ReclamationController
  final ReclamationController _reclamationCtrl = Get.put(ReclamationController());

  DateTime? _dateReclamation;
  DateTime? _dateTraitement;
  String? _messageReponse;
  Color? _couleurReponse;
  IconData? _iconeReponse;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    final maintenant = DateTime.now();
    _dateReclamation = maintenant;
    _dateTraitement = maintenant;
    _dateReclamationController.text = _formaterDate(_dateReclamation!);
    _dateTraitementController.text = _formaterDate(_dateTraitement!);
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

  // ==================== SUBMIT RECLAMATION ====================
  Future<void> _soumettre() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate dates
    if (_dateReclamation == null || _dateTraitement == null) {
      _afficherMessageReponse(
        message: 'Veuillez sélectionner les dates de réclamation et de traitement',
        couleur: Colors.red,
        icone: Icons.error_outline,
      );
      return;
    }

    // Call controller to add reclamation
    final result = await _reclamationCtrl.addReclamation(
      libelle: _reclamationController.text.trim(),
      dateReclamation: _dateReclamation!,
      dateTraitement: _dateTraitement!,
      type: 'ALERTE',
    );

    // ==================== HANDLE SUCCESS ====================
    if (result['success'] == true) {
      final backendMessage = result['message'] ?? 'Réclamation soumise avec succès';
      
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
        _reclamationController.clear();
        final maintenant = DateTime.now();
        _dateReclamation = maintenant;
        _dateTraitement = maintenant;
        _dateReclamationController.text = _formaterDate(_dateReclamation!);
        _dateTraitementController.text = _formaterDate(_dateTraitement!);
        _messageReponse = null;
        _couleurReponse = null;
        _iconeReponse = null;
      });
    } 
    // ==================== HANDLE ERROR ====================
    else {
      _afficherMessageReponse(
        message: result['message'] ?? 'Échec de la soumission de la réclamation',
        couleur: Colors.red,
        icone: Icons.error_outline,
      );
    }
  }

  // Display response message in form
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
    _reclamationController.dispose();
    _dateReclamationController.dispose();
    _dateTraitementController.dispose();
    super.dispose();
  }

  // ==================== BUILD DATE FIELD ====================
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
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
          _buildHeaderCard(),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Reclamation text field
                AppTextField(
                  controller: _reclamationController,
                  label: 'Réclamation',
                  hint: 'Décrivez brièvement votre réclamation',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Veuillez entrer une réclamation'
                      : null,
                ),
                const SizedBox(height: 16),
                
                // Date reclamation field
                _buildDateField(
                  _dateReclamationController,
                  'Date réclamation',
                  _choisirDateReclamation,
                ),
                const SizedBox(height: 16),
                
                // Date traitement field
                _buildDateField(
                  _dateTraitementController,
                  'Date traitement',
                  _choisirDateTraitement,
                ),
                const SizedBox(height: 26),

                // ==================== SUBMIT BUTTON ====================
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _reclamationCtrl.isLoading.value
                            ? null
                            : _soumettre,
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
                        child: _reclamationCtrl.isLoading.value
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
                                'Soumettre la réclamation',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    )),

                // ==================== RESPONSE MESSAGE ====================
                if (_messageReponse != null) ...[
                  const SizedBox(height: 20),
                  _buildMessageReponse(),
                ]
              ],
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
          'Nouvelle Réclamation',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        centerTitle: false,
      ),
      body: (_fadeAnimation != null)
          ? FadeTransition(opacity: _fadeAnimation!, child: scrollContent)
          : scrollContent,
    );
  }

  // ==================== BUILD HEADER CARD ====================
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A0).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
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
              ),
            ),
            child: const Icon(
              Icons.error_outline,
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
                  'Nouvelle réclamation',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remplissez les informations ci-dessous pour soumettre votre réclamation.',
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

  // ==================== BUILD MESSAGE RESPONSE ====================
  Widget _buildMessageReponse() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _couleurReponse?.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _couleurReponse ?? Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconeReponse,
              color: _couleurReponse,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _messageReponse!,
                style: GoogleFonts.poppins(
                  color: _couleurReponse,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DATE PICKERS ====================
  Future<void> _choisirDateReclamation() async {
    final maintenant = DateTime.now();
    final selectionne = await showDatePicker(
      context: context,
      initialDate: _dateReclamation ?? maintenant,
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
        _dateReclamation = selectionne;
        _dateReclamationController.text = _formaterDate(selectionne);
      });
    }
  }

  Future<void> _choisirDateTraitement() async {
    final base = _dateReclamation ?? DateTime.now();
    final selectionne = await showDatePicker(
      context: context,
      initialDate: _dateTraitement ?? base,
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
        _dateTraitement = selectionne;
        _dateTraitementController.text = _formaterDate(selectionne);
      });
    }
  }
}