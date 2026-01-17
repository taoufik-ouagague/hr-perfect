// ============================================================
// conge_model.dart - Leave Request Model
// ============================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';

enum RequestStatus { demande, valide, rejete, annule, enCours }

class CongeModel {
  final String id;
  final String typeConge;
  final String libelle;
  final DateTime dateDebut;
  final DateTime dateFin;
  final DateTime dateDemande;
  final RequestStatus status;
  final String? adminComment;
  final String? dateTraitement;

  CongeModel({
    required this.id,
    required this.typeConge,
    required this.libelle,
    required this.dateDebut,
    required this.dateFin,
    required this.dateDemande,
    required this.status,
    this.adminComment,
    this.dateTraitement,
  });

  int get numberOfDays {
    return dateFin.difference(dateDebut).inDays + 1;
  }

  static String _generateId({
    required String typeConge,
    required String libelle,
    required String dateDebut,
    required String dateFin,
  }) {
    final raw = 'conge|$typeConge|$libelle|$dateDebut|$dateFin';
    return md5.convert(utf8.encode(raw)).toString();
  }

  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    String cleaned = dateStr.trim();

    // Try ISO format
    DateTime? parsed = DateTime.tryParse(cleaned);
    if (parsed != null) return parsed;

    // Try ISO format without space
    if (cleaned.contains(' ') && cleaned.contains(':')) {
      final isoFormat = cleaned.replaceFirst(' ', 'T');
      parsed = DateTime.tryParse(isoFormat);
      if (parsed != null) return parsed;
    }

    // Try dd/MM/yyyy format
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      if (parts.length == 3) {
        try {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        } catch (e) {
          // Continue
        }
      }
    }

    return null;
  }

  static RequestStatus _parseStatus(String statut) {
    switch (statut) {
      case 'Validé':
        return RequestStatus.valide;
      case 'Rejeté':
        return RequestStatus.rejete;
      case 'Annulé':
        return RequestStatus.annule;
      case 'En cours':
        return RequestStatus.enCours;
      case 'Demande':
        return RequestStatus.demande;
      default:
        return RequestStatus.demande;
    }
  }

  factory CongeModel.fromJson(Map<String, dynamic> json) {
    final typeConge = json['typeConge']?.toString() ?? '';
    final libelle = json['libelle']?.toString() ?? json['motif']?.toString() ?? 'Sans titre';
    
    final dateDebutStr = json['dateDebut']?.toString() ?? '';
    final dateFinStr = json['dateFin']?.toString() ?? '';
    final dateDemandeStr = json['dateDemande']?.toString() ?? '';
    
    final status = _parseStatus(json['statut']?.toString() ?? 'Demande');
    
    DateTime? dateDebut = _parseDate(dateDebutStr);
    DateTime? dateFin = _parseDate(dateFinStr);
    DateTime? dateDemande = _parseDate(dateDemandeStr);

    // Fallback dates
    dateDebut ??= DateTime.now();
    dateFin ??= DateTime.now();
    dateDemande ??= dateDebut;

    return CongeModel(
      id: _generateId(
        typeConge: typeConge,
        libelle: libelle,
        dateDebut: dateDebut.toIso8601String(),
        dateFin: dateFin.toIso8601String(),
      ),
      typeConge: typeConge,
      libelle: libelle,
      dateDebut: dateDebut,
      dateFin: dateFin,
      dateDemande: dateDemande,
      status: status,
      adminComment: json['adminComment']?.toString(),
      dateTraitement: json['dateTraitement']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeConge': typeConge,
      'libelle': libelle,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'dateDemande': dateDemande.toIso8601String(),
      'statut': _statusToString(status),
      'adminComment': adminComment,
      'dateTraitement': dateTraitement,
    };
  }

  String _statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.valide:
        return 'Validé';
      case RequestStatus.rejete:
        return 'Rejeté';
      case RequestStatus.annule:
        return 'Annulé';
      case RequestStatus.enCours:
        return 'En cours';
      case RequestStatus.demande:
        return 'Demande';
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String get formattedDateDebut => formatDate(dateDebut);
  String get formattedDateFin => formatDate(dateFin);
  String get formattedDateDemande => formatDate(dateDemande);
  
  String get periode => '$formattedDateDebut - $formattedDateFin';
  String get statusText => _statusToString(status);
}