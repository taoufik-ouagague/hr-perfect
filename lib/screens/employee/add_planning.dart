import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_perfect/controllers/planning_controller.dart';

// SearchableDropdown Widget
class SearchableDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final List<Map<String, dynamic>> items;
  final String? selectedValue;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final IconData prefixIcon;

  const SearchableDropdown({
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
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
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
        setState(() => _isOpen = false);
      });
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
                offset: Offset(0, size.height + -18),
                child: GestureDetector(
                  onTap: () {},
                  child: FadeTransition(
                    opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                    child: ScaleTransition(
                      scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                      alignment: Alignment.topCenter,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: widget.items.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text('Aucun résultat',
                                      style: GoogleFonts.poppins(color: Colors.grey)),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: widget.items.length,
                                    itemBuilder: (context, index) {
                                      final item = widget.items[index];
                                      final label = item['typedevisite'] ?? 
                                                   item['libelle'] ?? 'N/A';
                                      final isSelected = widget.selectedValue == 
                                                        item['id'].toString();
                                      return InkWell(
                                        onTap: () {
                                          widget.onChanged(item['id'].toString());
                                          _removeOverlay();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                          color: isSelected
                                              ? const Color(0xFF00C6FF).withValues(alpha: 0.1)
                                              : Colors.transparent,
                                          child: Text(label,
                                            style: GoogleFonts.poppins(
                                              fontWeight: isSelected 
                                                ? FontWeight.w600 
                                                : FontWeight.w500,
                                              color: isSelected
                                                  ? const Color(0xFF00C6FF)
                                                  : const Color(0xFF374151),
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
    setState(() => _isOpen = true);
    _dropdownAnimationController?.forward();
  }

  String _getSelectedLabel() {
    if (widget.selectedValue == null) return widget.hint;
    final selectedItem = widget.items.firstWhere(
      (item) => item['id'].toString() == widget.selectedValue,
      orElse: () => {},
    );
    return selectedItem['typedevisite'] ?? selectedItem['libelle'] ?? widget.hint;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOpen ? const Color(0xFF00C6FF) : Colors.transparent,
                  width: 2),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Icon(widget.prefixIcon, color: const Color(0xFF00C6FF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_getSelectedLabel(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: widget.selectedValue == null 
                        ? Colors.grey 
                        : const Color(0xFF111827),
                      fontWeight: widget.selectedValue == null
                          ? FontWeight.w400
                          : FontWeight.w500,
                    ),
                  )),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF00C6FF)),
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

// Main Page
class AddPlanningPage extends StatefulWidget {
  const AddPlanningPage({super.key});

  @override
  State<AddPlanningPage> createState() => _AddPlanningPageState();
}

class _AddPlanningPageState extends State<AddPlanningPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _objetController = TextEditingController();

  // ✅ Initialize the PlanningController
  final PlanningController _planningController = Get.put(PlanningController());

  String? selectedTypeVisiteId;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
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

  @override
  void dispose() {
    _clientController.dispose();
    _objetController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
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

    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
           '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
           '${t.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    return '${_formatDate(date)} ${_formatTime(time)}';
  }

  // ✅ UPDATED: Use controller method with correct parameter names
  Future<void> _savePlanning() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedTypeVisiteId == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner un type de visite',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red.shade700,
      );
      return;
    }

    final result = await _planningController.addPlanning(
      idTypeVisite: selectedTypeVisiteId!,
      client: _clientController.text,
      objet: _objetController.text,
      datePrevu: _formatDateTime(selectedDate, selectedTime),
    );

    if (result['success'] == true) {
      final backendMessage = result['message'] ?? 'Planning ajouté avec succès';

      Get.snackbar(
        'Succès',
        backendMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        colorText: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      );

      // Reset form
      _clientController.clear();
      _objetController.clear();
      setState(() {
        selectedDate = DateTime.now();
        selectedTime = TimeOfDay.now();
        if (_planningController.typesVisites.isNotEmpty) {
          selectedTypeVisiteId = _planningController.typesVisites[0]['id'].toString();
        }
      });
    } else {
      Get.snackbar(
        'Erreur',
        result['message'] ?? 'Échec de l\'ajout',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red.shade700,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget scrollContent = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 18, right: 18, top: 18,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // ✅ Use Obx to react to controller state
            Obx(() {
              if (_planningController.isLoadingTypes.value) {
                return Center(child: CircularProgressIndicator(
                  color: const Color(0xFF00E5A0)));
              }
              
              return SearchableDropdown(
                label: 'Type de visite',
                hint: 'Sélectionner un type',
                items: _planningController.typesVisites.toList(),
                selectedValue: selectedTypeVisiteId,
                prefixIcon: Icons.category_outlined,
                onChanged: (value) {
                  setState(() => selectedTypeVisiteId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un type de visite';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 20),

            _buildTextField(_clientController, 'Client', 'Nom du client', Icons.person_outline),
            const SizedBox(height: 20),

            _buildTextField(_objetController, 'Objet', 'Description de l\'objet', 
              Icons.notes_outlined, maxLines: 3),
            const SizedBox(height: 20),

            _buildDateField('Date prévue'),
            const SizedBox(height: 20),

            _buildTimeField('Heure prévue'),
            const SizedBox(height: 32),

            // ✅ Submit button with loading state
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _planningController.isLoading.value ? null : _savePlanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C6FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _planningController.isLoading.value
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Ajouter le planning',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            )),
          ],
        ),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, 
            color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ajouter un planning',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600,
            color: const Color(0xFF111827))),
        centerTitle: false,
      ),
      body: SafeArea(bottom: false, child: animatedContent),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0099CC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
          color: const Color(0xFF00C6FF).withValues(alpha: 0.35),
          blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(height: 44, width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)),
            child: const Icon(Icons.add_circle_outline_rounded, 
              color: Colors.white, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouveau planning', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Remplissez les informations', style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, 
      String hint, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: maxLines > 1 ? 43 : 0),
                child: Icon(icon, color: const Color(0xFF00C6FF)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer ${label.toLowerCase()}';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
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
                Expanded(child: Text(_formatDate(selectedDate),
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, 
                    color: const Color(0xFF111827)))),
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
    );
  }

  Widget _buildTimeField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)]),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(_formatTime(selectedTime),
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, 
                    color: const Color(0xFF111827)))),
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
    );
  }
}