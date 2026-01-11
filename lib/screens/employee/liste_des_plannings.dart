import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_perfect/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListPlanningsPage extends StatefulWidget {
  const ListPlanningsPage({super.key});

  @override
  State<ListPlanningsPage> createState() => _ListPlanningsPageState();
}

class _ListPlanningsPageState extends State<ListPlanningsPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allPlannings = [];
  List<Map<String, dynamic>> plannings = [];
  Set<String> _uniqueEmployees = {};
 

  bool isLoading = false;
  String? errorMessage;
  String? selectedStatut;
  String? selectedEmployee;
  int? selectedYear;
  int? selectedMonth;

  final Logger _logger = Logger();
  DateTime _focusedWeek = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  // Animation controller
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  final List<String> weekDays = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];
  final List<String> hours = [
    '7 AM',
    '8 AM',
    '9 AM',
    '10 AM',
    '11 AM',
    '12 PM',
    '1 PM',
    '2 PM',
    '3 PM',
    '4 PM',
    '5 PM',
    '6 PM',
  ];
  final List<String> monthNames = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchPlannings();
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
    _animationController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  DateTime _getStartOfWeek(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: diff));
  }

  List<DateTime> _getWeekDays() {
    final startOfWeek = _getStartOfWeek(_focusedWeek);
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int selectedYear = _focusedWeek.year;
        int selectedMonth = _focusedWeek.month;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sélectionner le mois',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setModalState(() => selectedYear--),
                        icon: const Icon(Icons.chevron_left, size: 28),
                        color: const Color(0xFF6366F1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedYear.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setModalState(() => selectedYear++),
                        icon: const Icon(Icons.chevron_right, size: 28),
                        color: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      const months = [
                        'Jan',
                        'Fév',
                        'Mar',
                        'Avr',
                        'Mai',
                        'Juin',
                        'Juil',
                        'Aoû',
                        'Sep',
                        'Oct',
                        'Nov',
                        'Déc',
                      ];
                      final monthIndex = index + 1;
                      final isSelected = selectedMonth == monthIndex;
                      final isCurrentMonth =
                          DateTime.now().year == selectedYear &&
                          DateTime.now().month == monthIndex;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              setModalState(() => selectedMonth = monthIndex),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isCurrentMonth
                                        ? const Color(
                                            0xFF6366F1,
                                          ).withValues(alpha: 0.1)
                                        : const Color(0xFFF5F7FB)),
                              borderRadius: BorderRadius.circular(12),
                              border: isCurrentMonth && !isSelected
                                  ? Border.all(
                                      color: const Color(0xFF6366F1),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              months[index],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isCurrentMonth
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFF111827)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: Color(0xFF6366F1)),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(
                              () => _focusedWeek = DateTime(
                                selectedYear,
                                selectedMonth,
                                1,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Confirmer',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allPlannings);

    if (selectedStatut != null && selectedStatut!.isNotEmpty) {
      filtered = filtered
          .where((p) => p['statut']?.toString() == selectedStatut)
          .toList();
    }

    if (selectedEmployee != null && selectedEmployee!.isNotEmpty) {
      filtered = filtered
          .where((p) => p['employe']?.toString() == selectedEmployee)
          .toList();
    }

    if (selectedYear != null) {
      filtered = filtered.where((p) {
        final date = _parseDateTime(p['datePrevu'] as String?);
        return date != null && date.year == selectedYear;
      }).toList();
    }

    if (selectedMonth != null) {
      filtered = filtered.where((p) {
        final date = _parseDateTime(p['datePrevu'] as String?);
        return date != null && date.month == selectedMonth;
      }).toList();
    }

    setState(() => plannings = filtered);
  }

  Future<void> _fetchPlannings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(ApiService.listPlannings()),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'token': token,
        },
        body: json.encode({'date_debut': '', 'date_fin': ''}),
      );

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = 'Erreur serveur: ${response.statusCode}';
          isLoading = false;
        });
        return;
      }

      final dynamic responseData = json.decode(response.body);
      List<Map<String, dynamic>> parsed = [];

      if (responseData is List) {
        parsed = responseData.cast<Map<String, dynamic>>();
      } else if (responseData is Map) {
        if (responseData.containsKey('error')) {
          setState(() {
            errorMessage = responseData['error'].toString();
            isLoading = false;
          });
          return;
        }
        if (responseData.containsKey('data')) {
          parsed = (responseData['data'] as List).cast<Map<String, dynamic>>();
        }
      }

      final employees = parsed
          .map((p) => p['employe']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet();

      final years = <int>{};
      final months = <int>{};
      for (var p in parsed) {
        final date = _parseDateTime(p['datePrevu'] as String?);
        if (date != null) {
          years.add(date.year);
          months.add(date.month);
        }
      }

      setState(() {
        _allPlannings = parsed;
        _uniqueEmployees = employees;
  
        isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur: $e';
        isLoading = false;
      });
    }
  }

  DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split(' ');
      if (parts.isEmpty) return null;
      final dateParts = parts[0].split('/');
      if (dateParts.length != 3) return null;
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      if (parts.length > 1) {
        final timeParts = parts[1].split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          return DateTime(year, month, day, hour, minute);
        }
      }
      return DateTime(year, month, day, 9, 0);
    } catch (e) {
      _logger.e('Error parsing date: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _getPlanningsForDay(DateTime day) {
    return plannings.where((planning) {
      final date = _parseDateTime(planning['datePrevu'] as String?);
      if (date == null) return false;
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList()..sort((a, b) {
      final dateA = _parseDateTime(a['datePrevu'] as String?);
      final dateB = _parseDateTime(b['datePrevu'] as String?);
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });
  }

  double _getEventTop(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final hourIndex = hour - 7;
    if (hourIndex < 0) return 0;
    return (hourIndex * 80.0) + (minute / 60.0 * 80.0);
  }

  double _getEventHeight(String? dateStr) => 120.0;

  int _getEventColumn(List<Map<String, dynamic>> dayEvents, int currentIndex) {
    final currentEvent = dayEvents[currentIndex];
    final currentTime = _parseDateTime(currentEvent['datePrevu'] as String?);
    if (currentTime == null) return 0;
    int column = 0;
    for (int i = 0; i < currentIndex; i++) {
      final otherTime = _parseDateTime(dayEvents[i]['datePrevu'] as String?);
      if (otherTime == null) continue;
      final diff = currentTime.difference(otherTime).inMinutes.abs();
      if (diff < 120) column++;
    }
    return column.clamp(0, 2);
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case '8':
        return const Color(0xFFF59E0B);
      case '21':
        return const Color(0xFFEF4444);
      case '25':
        return const Color(0xFF10B981);
      case '26':
        return const Color(0xFF6366F1);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String statut) {
    switch (statut) {
      case '8':
        return 'En attente';
      case '21':
        return 'Annulé';
      case '25':
        return 'Réalisé';
      case '26':
        return 'Reporté';
      default:
        return 'Inconnu';
    }
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filtres',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    if (selectedStatut != null ||
                        selectedEmployee != null ||
                        selectedYear != null ||
                        selectedMonth != null)
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            selectedStatut = null;
                            selectedEmployee = null;
                            selectedYear = null;
                            selectedMonth = null;
                          });
                          setState(() {
                            selectedStatut = null;
                            selectedEmployee = null;
                            selectedYear = null;
                            selectedMonth = null;
                          });
                          _applyFilters();
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Réinitialiser'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Year Filter
                
                const SizedBox(height: 24),

                // Status Filter
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Statut',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('Tous', '', setModalState, isStatus: true),
                    _buildFilterChip(
                      'En attente',
                      '8',
                      setModalState,
                      color: const Color(0xFFF59E0B),
                      isStatus: true,
                    ),
                    _buildFilterChip(
                      'Réalisé',
                      '25',
                      setModalState,
                      color: const Color(0xFF10B981),
                      isStatus: true,
                    ),
                    _buildFilterChip(
                      'Reporté',
                      '26',
                      setModalState,
                      color: const Color(0xFF6366F1),
                      isStatus: true,
                    ),
                    _buildFilterChip(
                      'Annulé',
                      '21',
                      setModalState,
                      color: const Color(0xFFEF4444),
                      isStatus: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Employee Filter
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Employé',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          'Tous',
                          '',
                          setModalState,
                          isEmployee: true,
                        ),
                        ..._uniqueEmployees.map(
                          (emp) => _buildFilterChip(
                            emp,
                            emp,
                            setModalState,
                            color: const Color(0xFF8B5CF6),
                            isEmployee: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Appliquer les filtres',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    dynamic value,
    StateSetter setModalState, {
    Color? color,
    bool isStatus = false,
    bool isEmployee = false,
    bool isYear = false,
    bool isMonth = false,
  }) {
    final bool isSelected;
    if (isStatus) {
      isSelected = selectedStatut == value;
    } else if (isEmployee) {
      isSelected = selectedEmployee == value;
    } else if (isYear) {
      isSelected = selectedYear == value;
    } else if (isMonth) {
      isSelected = selectedMonth == value;
    } else {
      isSelected = false;
    }

    final chipColor = color ?? Colors.grey;

    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : chipColor,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          if (isStatus) {
            selectedStatut = selected ? value : null;
          } else if (isEmployee) {
            selectedEmployee = selected ? value : null;
          } else if (isYear) {
            selectedYear = selected ? value as int? : null;
          } else if (isMonth) {
            selectedMonth = selected ? value as int? : null;
          }
        });
        setState(() {
          if (isStatus) {
            selectedStatut = selected ? value : null;
          } else if (isEmployee) {
            selectedEmployee = selected ? value : null;
          } else if (isYear) {
            selectedYear = selected ? value as int? : null;
          } else if (isMonth) {
            selectedMonth = selected ? value as int? : null;
          }
        });
      },
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showPlanningDetails(Map<String, dynamic> planning) {
    final statut = planning['statut']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(statut),
                        _getStatusColor(statut).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            statut,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(statut),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(statut),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              Icons.work_outline_rounded,
              'Type',
              (planning['typePlanning'] ?? 'N/A').toString(),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.person_outline_rounded,
              'Employé',
              (planning['employe'] ?? 'N/A').toString(),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.description_outlined,
              'Objet',
              (planning['objet'] ?? 'N/A').toString(),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.schedule_rounded,
              'Date prévue',
              (planning['datePrevu'] ?? 'N/A').toString(),
            ),
            if (planning['dateRealise'] != null &&
                planning['dateRealise'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.check_circle_outline_rounded,
                'Date réalisée',
                planning['dateRealise'].toString(),
                color: const Color(0xFF10B981),
              ),
            ],
            const SizedBox(height: 24),
            if (statut == '8') ...[
              _buildActionButton(
                'Exécuter',
                Icons.play_circle_outline_rounded,
                const Color(0xFF10B981),
                () {
                  Navigator.pop(context);
                  _executerPlanning(planning);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Reporter',
                      Icons.schedule_rounded,
                      const Color(0xFFF59E0B),
                      () {
                        Navigator.pop(context);
                        _reporterPlanning(planning);
                      },
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      'Annuler',
                      Icons.cancel_outlined,
                      const Color(0xFFEF4444),
                      () {
                        Navigator.pop(context);
                        _annulerPlanning(planning);
                      },
                      compact: true,
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.grey[600],
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Aucune action disponible',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? const Color(0xFF6366F1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: compact ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDaysList = _getWeekDays();

    Widget mainContent = Column(
      children: [
        // Navigation Header with animation
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _focusedWeek = _focusedWeek.subtract(
                      const Duration(days: 7),
                    ),
                  ),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showMonthYearPicker,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getMonthYear(_focusedWeek),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF6366F1),
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(
                              () => _focusedWeek = DateTime.now(),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                'Aujourd\'hui',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _focusedWeek = _focusedWeek.add(
                      const Duration(days: 7),
                    ),
                  ),
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Calendar View with animation
        Expanded(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                    width: 70,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: hours.length,
                            itemBuilder: (context, index) => Container(
                              height: 80,
                              alignment: Alignment.topCenter,
                              padding: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[100]!,
                                  ),
                                ),
                              ),
                              child: Text(
                                hours[index],
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: weekDaysList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final isToday =
                            DateTime.now().day == day.day &&
                            DateTime.now().month == day.month &&
                            DateTime.now().year == day.year;
                        
                        return Expanded(
                          child: TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 600 + (index * 80)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutCubic,
                            builder: (context, animValue, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - animValue)),
                                child: Opacity(
                                  opacity: animValue.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? const Color(
                                            0xFF6366F1,
                                          ).withValues(alpha: 0.1)
                                        : null,
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        weekDays[day.weekday - 1],
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isToday
                                              ? const Color(0xFF6366F1)
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? const Color(0xFF6366F1)
                                              : null,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${day.day}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isToday
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        ListView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: hours.length,
                                          itemBuilder: (context, index) =>
                                              Container(
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color:
                                                          Colors.grey[100]!,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        ),
                                        ...() {
                                          final dayEvents =
                                              _getPlanningsForDay(day);
                                          return dayEvents.asMap().entries.map((
                                            entry,
                                          ) {
                                            final planningIndex = entry.key;
                                            final planning = entry.value;
                                            final dateTime = _parseDateTime(
                                              planning['datePrevu']
                                                  as String?,
                                            );
                                            if (dateTime == null) {
                                              return const SizedBox.shrink();
                                            }
                                            final top = _getEventTop(
                                              dateTime,
                                            );
                                            final height = _getEventHeight(
                                              planning['datePrevu']
                                                  as String?,
                                            );
                                            final statut =
                                                planning['statut']
                                                    ?.toString() ??
                                                '';
                                            final color = _getStatusColor(
                                              statut,
                                            );
                                            final column = _getEventColumn(
                                              dayEvents,
                                              planningIndex,
                                            );
                                            final totalColumns = dayEvents
                                                .where((e) {
                                                  final t = _parseDateTime(
                                                    e['datePrevu']
                                                        as String?,
                                                  );
                                                  if (t == null) {
                                                    return false;
                                                  }
                                                  return (t
                                                          .difference(
                                                            dateTime,
                                                          )
                                                          .inMinutes
                                                          .abs() <
                                                      120);
                                                })
                                                .length;
                                            final columnWidth =
                                                totalColumns > 1
                                                ? (1.0 / totalColumns)
                                                : 1.0;
                                            final leftOffset =
                                                column * columnWidth;
                                            
                                            return Positioned(
                                              top: top,
                                              left: 2 + (leftOffset * 100),
                                              width:
                                                  (columnWidth * 100) - 4,
                                              height: height - 4,
                                              child: TweenAnimationBuilder<double>(
                                                duration: Duration(milliseconds: 800 + (planningIndex * 100)),
                                                tween: Tween(begin: 0.0, end: 1.0),
                                                curve: Curves.easeOutBack,
                                                builder: (context, eventValue, child) {
                                                  return Transform.scale(
                                                    scale: 0.8 + (0.2 * eventValue.clamp(0.0, 1.0)),
                                                    child: Opacity(
                                                      opacity: eventValue.clamp(0.0, 1.0),
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _showPlanningDetails(
                                                        planning,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        width: 1,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: color
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          blurRadius: 4,
                                                          offset:
                                                              const Offset(
                                                                0,
                                                                2,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: LayoutBuilder(
                                                      builder: (context, constraints) {
                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                (planning['typePlanning'] ??
                                                                        'Planning')
                                                                    .toString(),
                                                                style:
                                                                    GoogleFonts.poppins(
                                                                      fontSize: 11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                                                              style:
                                                                  GoogleFonts.poppins(
                                                                    fontSize: 9,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                        .white
                                                                        .withValues(
                                                                          alpha:
                                                                              0.9,
                                                                        ),
                                                                  ),
                                                            ),
                                                            if (constraints.maxHeight > 60 &&
                                                                planning['employe'] !=
                                                                    null) ...[
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                              Flexible(
                                                                child: Text(
                                                                  (planning['employe'] ??
                                                                          '')
                                                                      .toString(),
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize: 9,
                                                                    color: Colors
                                                                        .white
                                                                        .withValues(
                                                                          alpha:
                                                                              0.8,
                                                                        ),
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList();
                                        }(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Legend with animation - FIXED WITH DYNAMIC BOTTOM PADDING
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 900),
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
          child: Container(
            margin: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('En attente', const Color(0xFFF59E0B)),
                _buildLegendItem('Réalisé', const Color(0xFF10B981)),
                _buildLegendItem('Reporté', const Color(0xFF6366F1)),
                _buildLegendItem('Annulé', const Color(0xFFEF4444)),
              ],
            ),
          ),
        ),
      ],
    );

    // Wrap with fade animation
    Widget animatedContent = (_fadeAnimation != null)
        ? FadeTransition(
            opacity: _fadeAnimation!,
            child: mainContent,
          )
        : mainContent;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111827),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Planning ',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient:
                  (selectedStatut != null ||
                      selectedEmployee != null ||
                      selectedYear != null ||
                      selectedMonth != null)
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    )
                  : null,
              color:
                  (selectedStatut == null &&
                      selectedEmployee == null &&
                      selectedYear == null &&
                      selectedMonth == null)
                  ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list_rounded,
                color:
                    (selectedStatut != null ||
                        selectedEmployee != null ||
                        selectedYear != null ||
                        selectedMonth != null)
                    ? Colors.white
                    : const Color(0xFF6366F1),
              ),
              onPressed: _showFiltersBottomSheet,
              tooltip: 'Filtres',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF111827)),
            onPressed: _fetchPlannings,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              )
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchPlannings,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : animatedContent,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  void _executerPlanning(Map<String, dynamic> planning) {
    final pvController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exécuter',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            (planning['typePlanning'] ?? 'N/A').toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: pvController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Compte-rendu',
                    hintText: 'Décrivez le déroulement...',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            await _performExecuter(
                              planning['id'].toString(),
                              pvController.text,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Exécuter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _annulerPlanning(Map<String, dynamic> planning) {
    final pvController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Annuler',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            (planning['typePlanning'] ?? 'N/A').toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: pvController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Raison',
                    hintText: 'Pourquoi annulez-vous?',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            await _performAnnuler(
                              planning['id'].toString(),
                              pvController.text,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Confirmer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reporterPlanning(Map<String, dynamic> planning) {
    final pvController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reporter',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                (planning['typePlanning'] ?? 'N/A').toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Heure',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: pvController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Raison',
                        hintText: 'Pourquoi reporter?',
                        filled: true,
                        fillColor: const Color(0xFFF5F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFF59E0B),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                final dateStr =
                                    '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year} ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                                await _performReporter(
                                  planning['id'].toString(),
                                  pvController.text,
                                  dateStr,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Reporter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performExecuter(String id, String pv) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(ApiService.executerPlannings()),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'token': token,
        },
        body: json.encode({'idPlanning': id, 'pv': pv}),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planning exécuté'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _fetchPlannings();
      }
    } catch (e) {
      _logger.e('Error: $e');
    }
  }

  Future<void> _performAnnuler(String id, String pv) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(ApiService.annulerPlannings()),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'token': token,
        },
        body: json.encode({'idPlanning': id, 'pv': pv}),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planning annulé'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        _fetchPlannings();
      }
    } catch (e) {
      _logger.e('Error: $e');
    }
  }

  Future<void> _performReporter(String id, String pv, String datePrevu) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(ApiService.reporterPlannings()),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'token': token,
        },
        body: json.encode({'idPlanning': id, 'pv': pv, 'datePrevu': datePrevu}),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planning reporté'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        _fetchPlannings();
      }
    } catch (e) {
      _logger.e('Error: $e');
    }
  }
}