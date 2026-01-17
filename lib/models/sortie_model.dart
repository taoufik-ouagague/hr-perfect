// ============================================================
// sortie_model.dart
// ============================================================

import 'package:flutter/material.dart';

class SortieModel {
  final String? id;
  final String motif;
  final DateTime dateSortie;
  final TimeOfDay heureDebut;
  final TimeOfDay heureFin;
  final String? heureSortieDebut;
  final String? heureSortieFin;
  final String statut; // 'Demande', 'Validé', 'Rejeté', 'Annulé'
  final String? adminComment;
  final DateTime? createdAt;
  final String? typeSortie;

  SortieModel({
    this.id,
    required this.motif,
    required this.dateSortie,
    required this.heureDebut,
    required this.heureFin,
    this.heureSortieDebut,
    this.heureSortieFin,
    this.statut = 'Demande',
    this.adminComment,
    this.createdAt,
    this.typeSortie,
  });

  // Factory constructor pour créer depuis JSON
  factory SortieModel.fromJson(Map<String, dynamic> json) {
    final dateSortie = _parseDate(json['dateSortie']?.toString()) ?? DateTime.now();
    final heureDebut = _parseTime(json['heureSortieDebut']?.toString()) ?? TimeOfDay.now();
    final heureFin = _parseTime(json['heureSortieFin']?.toString()) ?? 
                     TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));

    return SortieModel(
      id: json['id']?.toString(),
      motif: json['motif']?.toString() ?? json['libelle']?.toString() ?? '',
      dateSortie: dateSortie,
      heureDebut: heureDebut,
      heureFin: heureFin,
      heureSortieDebut: json['heureSortieDebut']?.toString(),
      heureSortieFin: json['heureSortieFin']?.toString(),
      statut: json['statut']?.toString() ?? 'Demande',
      adminComment: json['adminComment']?.toString(),
      createdAt: _parseDate(json['createdAt']?.toString()),
      typeSortie: json['typeSortie']?.toString(),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motif': motif,
      'dateSortie': _formatDate(dateSortie),
      'heureSortieDebut': _formatTime(heureDebut),
      'heureSortieFin': _formatTime(heureFin),
      'statut': statut,
      'adminComment': adminComment,
      'typeSortie': typeSortie,
    };
  }

  // Helper pour parser les dates
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      // Format dd/MM/yyyy
      if (dateStr.contains('/')) {
        final parts = dateStr.split(' ')[0].split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      // Format ISO
      return DateTime.tryParse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // Helper pour parser les heures
  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Helper pour formater les dates
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  // Helper pour formater les heures
  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }

  // Getters utiles
  String get formattedDateSortie => _formatDate(dateSortie);
  
  String get formattedHeureDebut => _formatTime(heureDebut);
  
  String get formattedHeureFin => _formatTime(heureFin);

  String get plageHoraire => '$formattedHeureDebut - $formattedHeureFin';

  Duration get duree {
    final debut = heureDebut.hour * 60 + heureDebut.minute;
    final fin = heureFin.hour * 60 + heureFin.minute;
    return Duration(minutes: fin - debut);
  }

  String get dureeFormatted {
    final minutes = duree.inMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hours h ${mins.toString().padLeft(2, '0')} min';
    }
    return '$mins min';
  }

  String get statusLabel {
    switch (statut) {
      case 'Validé':
        return 'Validée';
      case 'Rejeté':
        return 'Rejetée';
      case 'En cours':
        return 'En cours';
      case 'Annulé':
        return 'Annulée';
      default:
        return 'En attente';
    }
  }

  // Copie avec modifications
  SortieModel copyWith({
    String? id,
    String? motif,
    DateTime? dateSortie,
    TimeOfDay? heureDebut,
    TimeOfDay? heureFin,
    String? heureSortieDebut,
    String? heureSortieFin,
    String? statut,
    String? adminComment,
    DateTime? createdAt,
    String? typeSortie,
  }) {
    return SortieModel(
      id: id ?? this.id,
      motif: motif ?? this.motif,
      dateSortie: dateSortie ?? this.dateSortie,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      heureSortieDebut: heureSortieDebut ?? this.heureSortieDebut,
      heureSortieFin: heureSortieFin ?? this.heureSortieFin,
      statut: statut ?? this.statut,
      adminComment: adminComment ?? this.adminComment,
      createdAt: createdAt ?? this.createdAt,
      typeSortie: typeSortie ?? this.typeSortie,
    );
  }
}