import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_perfect/controllers/mission_controller.dart';
import 'package:hr_perfect/models/mission_model.dart';
import '../../widgets/app_text_field.dart';

// Custom Dropdown Widget
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
                offset: Offset(0, size.height + -15),
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
                                      final isSelected = widget.selectedValue == item;
                                      return InkWell(
                                        onTap: () {
                                          widget.onChanged(item);
                                          _removeOverlay();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                          color: isSelected 
                                            ? const Color(0xFF00C6FF).withValues(alpha: 0.1)
                                            : Colors.transparent,
                                          child: Text(item, 
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
                  color: _isOpen ? const Color(0xFF00C6FF) : Colors.transparent, width: 2),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Icon(widget.prefixIcon, color: const Color(0xFF00C6FF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    widget.selectedValue ?? widget.hint,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: widget.selectedValue == null ? Colors.grey : const Color(0xFF111827),
                      fontWeight: widget.selectedValue == null ? FontWeight.w400 : FontWeight.w500,
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
class AddMissionPage extends StatefulWidget {
  const AddMissionPage({super.key});

  @override
  State<AddMissionPage> createState() => _AddMissionPageState();
}

class _AddMissionPageState extends State<AddMissionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // ✅ Initialize the MissionController
  final MissionController _missionController = Get.put(MissionController());

  late final TextEditingController _accompagnateurController;
  late final TextEditingController _matriculeController;
  late final TextEditingController _objetController;
  late final TextEditingController _marqueController;
  late final TextEditingController _dateDepartController;
  late final TextEditingController _dateRetourController;
  late final TextEditingController _designationController;

  DateTime? _dateDepart;
  DateTime? _dateRetour;

  String _selectedHeureDepart = '08';
  String _selectedMinDepart = '00';
  String _selectedHeureRetour = '17';
  String _selectedMinRetour = '00';
  String? _selectedMoyenTransport;
  String? _selectedNbCheveaux;
  String _selectedCarburant = 'Diesel';
  String _selectedEtranger = 'Non';

  final List<String> _carburantOptions = ['Diesel', 'Essence'];
  final List<String> _etrangerOptions = ['Non', 'Oui'];

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  List<String> get _hours => List.generate(24, (i) => i.toString().padLeft(2, '0'));
  List<String> get _minutes => List.generate(60, (i) => i.toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeControllers();
    _initializeDates();
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

  // ✅ UPDATED: Use controller method with MissionFormData from mission_model.dart
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Use MissionFormData from mission_model.dart
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
      nbCheveaux: _selectedNbCheveaux ?? (_missionController.nbCheveaux.isNotEmpty 
          ? _missionController.nbCheveaux.first : ''),
      moyenTransport: _selectedMoyenTransport ?? (_missionController.moyensTransport.isNotEmpty 
          ? _missionController.moyensTransport.first : ''),
      designation: _designationController.text.trim(),
    );

    final response = await _missionController.submitMission(formData);

    if (response['success'] == true) {
      final backendMessage = response['message'] ?? 'Demande soumise avec succès';

      Get.snackbar(
        'Succès',
        backendMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        colorText: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      );

      // Reset form
      _accompagnateurController.clear();
      _matriculeController.clear();
      _objetController.clear();
      _marqueController.clear();
      _designationController.clear();
      _initializeDates();

      setState(() {
        _selectedMoyenTransport = _missionController.moyensTransport.isNotEmpty
            ? _missionController.moyensTransport.first : null;
        _selectedNbCheveaux = _missionController.nbCheveaux.isNotEmpty
            ? _missionController.nbCheveaux.first : null;
        _selectedCarburant = 'Diesel';
        _selectedEtranger = 'Non';
      });
    } else {
      Get.snackbar(
        'Erreur',
        response['message'] ?? 'Échec de la soumission',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red.shade700,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Demande de mission',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, 
            color: const Color(0xFF111827))),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          // ✅ Show loading state
          if (_missionController.isLoadingDropdowns.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00E5A0)),
                  const SizedBox(height: 16),
                  Text('Chargement des données...',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          // ✅ Show error state
          if (_missionController.dropdownError.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(_missionController.dropdownError.value!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.red)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _missionController.loadDropdownData,
                      icon: const Icon(Icons.refresh),
                      label: Text('Réessayer', 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5A0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ✅ Show form
          return _buildForm();
        }),
      ),
    );
  }

  Widget _buildForm() {
    Widget scrollContent = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 18, right: 18, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 22),
            AppTextField(controller: _objetController, label: 'Objet',
              hint: 'Entrez l\'objet de la mission', icon: Icons.note,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
            const SizedBox(height: 16),
            AppTextField(controller: _accompagnateurController, label: 'Accompagnateur',
              hint: 'Entrez la personne accompagnatrice', icon: Icons.person,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
            const SizedBox(height: 16),
            _buildDateField(_dateDepartController, 'Date de Départ', true),
            const SizedBox(height: 16),
            _buildTimeRow(_selectedHeureDepart, _selectedMinDepart,
              (h) => setState(() => _selectedHeureDepart = h!),
              (m) => setState(() => _selectedMinDepart = m!)),
            const SizedBox(height: 16),
            _buildDateField(_dateRetourController, 'Date de Retour', false),
            const SizedBox(height: 16),
            _buildTimeRow(_selectedHeureRetour, _selectedMinRetour,
              (h) => setState(() => _selectedHeureRetour = h!),
              (m) => setState(() => _selectedMinRetour = m!)),
            const SizedBox(height: 16),
            AppTextField(controller: _designationController, label: 'Désignation',
              hint: 'Entrez la désignation', icon: Icons.label,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
            const SizedBox(height: 16),
            
            _buildDropdown('Étranger', Icons.public, _selectedEtranger,
              _etrangerOptions, (v) => setState(() => _selectedEtranger = v!)),
            const SizedBox(height: 16),
            
            Obx(() {
              final transports = _missionController.moyensTransport.toList();
              return _buildDropdown('Moyen de Transport', Icons.directions_car,
                _selectedMoyenTransport, transports,
                (v) => setState(() => _selectedMoyenTransport = v));
            }),
            const SizedBox(height: 16),
            AppTextField(controller: _marqueController, label: 'Marque',
              hint: 'Entrez la marque du véhicule', icon: Icons.car_repair,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
            const SizedBox(height: 16),
            
            Obx(() {
              final cheveaux = _missionController.nbCheveaux.toList();
              return _buildDropdown('Nb Cheveaux', Icons.speed, _selectedNbCheveaux,
                cheveaux, (v) => setState(() => _selectedNbCheveaux = v));
            }),
            const SizedBox(height: 16),
            AppTextField(controller: _matriculeController, label: 'Matricule',
              hint: 'Entrez le matricule', icon: Icons.card_membership,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
            const SizedBox(height: 16),
            
            _buildDropdown('Carburant', Icons.local_gas_station,
              _selectedCarburant, _carburantOptions,
              (v) => setState(() => _selectedCarburant = v!)),
            const SizedBox(height: 24),
            
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _missionController.isLoading.value ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5A0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _missionController.isLoading.value
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text('Soumettre la demande',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            )),
          ],
        ),
      ),
    );

    return (_fadeAnimation != null)
        ? FadeTransition(opacity: _fadeAnimation!, child: scrollContent)
        : scrollContent;
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5A0), Color(0xFF00C6FF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
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
              Text('Remplissez les informations ci-dessous',
                style: GoogleFonts.poppins(fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85))),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, bool isDeparture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isDeparture),
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
                  child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(controller.text.isEmpty ? 'Sélectionner' : controller.text,
                  style: GoogleFonts.poppins(fontSize: 14,
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
    );
  }

  Widget _buildTimeRow(String hourValue, String minValue,
      void Function(String?) onHourChanged, void Function(String?) onMinChanged) {
    return Row(
      children: [
        Expanded(child: CustomDropdown(label: 'Heure', hint: 'HH', items: _hours,
          selectedValue: hourValue, prefixIcon: Icons.access_time, onChanged: onHourChanged)),
        const SizedBox(width: 12),
        Expanded(child: CustomDropdown(label: 'Minute', hint: 'MM', items: _minutes,
          selectedValue: minValue, prefixIcon: Icons.timer, onChanged: onMinChanged)),
      ],
    );
  }

  Widget _buildDropdown(String label, IconData icon, String? currentValue,
      List<String> items, void Function(String?) onChanged) {
    return CustomDropdown(
      label: label,
      hint: 'Sélectionner ${label.toLowerCase()}',
      items: items,
      selectedValue: items.contains(currentValue) ? currentValue : 
        (items.isNotEmpty ? items.first : null),
      prefixIcon: icon,
      onChanged: onChanged,
      validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
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