import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hr_perfect/services/api_service.dart';
import 'package:hr_perfect/widgets/app_text_field.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddSortiePage extends StatefulWidget {
  const AddSortiePage({super.key});

  @override
  State<AddSortiePage> createState() => _AddSortiePageState();
}

class _AddSortiePageState extends State<AddSortiePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _dateSortieController = TextEditingController();

  DateTime? _dateSortie;
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;
  bool _submitting = false;
  String? _responseMessage;
  Color? _responseColor;
  IconData? _responseIcon;

  final Logger _logger = Logger();

  // Animation controller
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    final now = DateTime.now();
    _dateSortie = now;
    _heureDebut = TimeOfDay.now();
    _heureFin = TimeOfDay(hour: now.hour + 2, minute: now.minute);
    _dateSortieController.text = _formatDate(_dateSortie!);
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

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateSortie == null || _heureDebut == null || _heureFin == null) {
      _showResponseMessage(
        message: 'Veuillez remplir tous les champs',
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
      final response = await _sendRequest();
      if (response['success'] == true) {
        final backendMessage =
            response['message'] ?? 'Sortie demandée avec succès';
        _logger.i('✅ Message: $backendMessage');

        Get.snackbar(
          'Succès',
          backendMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          colorText: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        );

        _motifController.clear();
        final now = DateTime.now();
        setState(() {
          _dateSortie = now;
          _heureDebut = TimeOfDay.now();
          _heureFin = TimeOfDay(hour: now.hour + 2, minute: now.minute);
          _dateSortieController.text = _formatDate(_dateSortie!);
        });
      } else {
        _showResponseMessage(
          message: response['message'] ?? 'Échec de la soumission',
          color: Colors.red,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      _showResponseMessage(
        message: 'Erreur: $e',
        color: Colors.red,
        icon: Icons.error_outline,
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<Map<String, dynamic>> _sendRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final body = {
        'motif': _motifController.text.trim(),
        'dateSortie': _formatDate(_dateSortie!),
        'heureDebut': _formatTime(_heureDebut!),
        'heureFin': _formatTime(_heureFin!),
      };

      final response = await http.post(
        Uri.parse(ApiService.addDemandesSorties()),
        headers: {'Content-Type': 'application/json', 'token': token},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String msg = 'Sortie demandée avec succès';
        if (data is List && data.isNotEmpty) {
          msg = data[0]['MSG'] ?? msg;
        } else if (data is Map) {
          msg = data['MSG'] ?? data['message'] ?? msg;
        }
        return {'success': true, 'message': msg};
      }
      return {'success': false, 'message': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

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
    _motifController.dispose();
    _dateSortieController.dispose();
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

  // New time field builder matching AddCongePage design
  Widget _buildTimeField(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onPicked,
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
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time ?? TimeOfDay.now(),
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
              if (picked != null) onPicked(picked);
            },
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
                      Icons.access_time_rounded,
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
                          time != null ? _formatTime(time) : 'Sélectionner',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: time != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: time != null
                                ? const Color(0xFF111827)
                                : Colors.grey,
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
    Widget scrollContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
            child: _buildHeaderCard(),
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
                  AppTextField(
                    controller: _motifController,
                    label: 'Motif',
                    hint: 'Raison de la sortie',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Updated date field with blur animation
                  _buildDateField(
                    _dateSortieController,
                    'Date de sortie',
                    () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateSortie ?? DateTime.now(),
                        firstDate: DateTime.now(),
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
                          _dateSortie = picked;
                          _dateSortieController.text = _formatDate(picked);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Updated time fields with blur animation
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          'Heure début',
                          _heureDebut,
                          (picked) => setState(() => _heureDebut = picked),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeField(
                          'Heure fin',
                          _heureFin,
                          (picked) => setState(() => _heureFin = picked),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
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
                    child: SizedBox(
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
                        final safeOpacity = value.clamp(0.0, 1.0);
                        final safeScale = value.clamp(0.0, 1.25);

                        return Transform.scale(
                          scale: safeScale,
                          child: Opacity(opacity: safeOpacity, child: child),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _responseColor?.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(_responseIcon, color: _responseColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _responseMessage!,
                                style: TextStyle(
                                  color: _responseColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
          'Demande de sortie',
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
}