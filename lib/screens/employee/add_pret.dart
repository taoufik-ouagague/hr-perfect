import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hr_perfect/controllers/pret_controller.dart';
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

  // ✅ Initialize PretController
  final PretController _pretController = Get.put(PretController());

  DateTime? _datePret;
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

  // ✅ SIMPLIFIED: Use controller method
  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_datePret == null || _montantPretController.text.isEmpty) {
      _afficherMessageReponse(
        message: 'Veuillez remplir tous les champs requis',
        couleur: Colors.red,
        icone: Icons.error_outline,
      );
      return;
    }

    final montant = double.tryParse(_montantPretController.text);
    if (montant == null) {
      _afficherMessageReponse(
        message: 'Montant invalide',
        couleur: Colors.red,
        icone: Icons.error_outline,
      );
      return;
    }

    final result = await _pretController.addPret(
      motifPret: _motifPretController.text.trim(),
      datePret: _datePret!,
      montantPret: montant,
    );

    if (result['success'] == true) {
      final backendMessage = result['message'] ?? 'Demande de prêt soumise avec succès';
      
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
      
      // Reset form
      _motifPretController.clear();
      _montantPretController.clear();
      final maintenant = DateTime.now();
      setState(() {
        _datePret = maintenant;
        _datePretController.text = _formaterDate(_datePret!);
      });
    } else {
      _afficherMessageReponse(
        message: result['message'] ?? 'La soumission de la demande a échoué',
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
    _animationController?.dispose();
    _motifPretController.dispose();
    _datePretController.dispose();
    _montantPretController.dispose();
    super.dispose();
  }

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
          Text(label, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)]),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    controller.text.isEmpty ? 'Sélectionner' : controller.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: controller.text.isEmpty ? FontWeight.w400 : FontWeight.w600,
                      color: controller.text.isEmpty ? Colors.grey : const Color(0xFF111827)))),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5A0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.arrow_forward_ios_rounded, 
                      color: Color(0xFF00E5A0), size: 16)),
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
                AppTextField(
                  controller: _motifPretController,
                  label: 'Motif du prêt',
                  hint: 'Indiquez le motif du prêt',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez entrer un motif' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _montantPretController,
                  label: 'Montant du prêt',
                  hint: 'Indiquez le montant du prêt',
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez entrer un montant' : null,
                ),
                const SizedBox(height: 16),
                _buildDateField(_datePretController, 'Date du prêt', _choisirDatePret),
                const SizedBox(height: 26),
                
                // ✅ Submit button with loading state
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _pretController.isLoading.value ? null : _soumettre,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5A0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _pretController.isLoading.value
                        ? const SizedBox(height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : Text('Soumettre la demande',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                )),
                
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Demande de prêt',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, 
            color: const Color(0xFF111827))),
        centerTitle: false,
      ),
      body: (_fadeAnimation != null)
          ? FadeTransition(opacity: _fadeAnimation!, child: scrollContent)
          : scrollContent,
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)]),
        boxShadow: [BoxShadow(
          color: const Color(0xFF00E5A0).withValues(alpha: 0.35),
          blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(height: 44, width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
            child: const Icon(Icons.send_outlined, color: Colors.white, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvelle demande', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Remplissez les informations ci-dessous pour soumettre votre demande.',
                style: GoogleFonts.poppins(fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85))),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildMessageReponse() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: _couleurReponse?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(_iconeReponse, color: _couleurReponse),
          const SizedBox(width: 10),
          Expanded(child: Text(_messageReponse!,
            style: TextStyle(color: _couleurReponse, fontWeight: FontWeight.bold, fontSize: 16))),
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
              filter: ImageFilter.blur(sigmaX: 10 * value, sigmaY: 10 * value),
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child!),
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