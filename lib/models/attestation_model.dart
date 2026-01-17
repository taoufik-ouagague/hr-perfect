// ============================================================
// attestation_model.dart - Attestation Request Model
// ============================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';

enum RequestStatus { demande, valide, rejete, annule, enCours }

class AttestationModel {
  final String id;
  final String typeAttestation;
  final String libelle;
  final DateTime dateDemande;
  final DateTime? derniereDemande;
  final RequestStatus status;
  final String? adminComment;
  final String? dateTraitement;

  AttestationModel({
    required this.id,
    required this.typeAttestation,
    required this.libelle,
    required this.dateDemande,
    this.derniereDemande,
    required this.status,
    this.adminComment,
    this.dateTraitement,
  });

  static String _generateId({
    required String typeAttestation,
    required String libelle,
    required String dateDemande,
  }) {
    final raw = 'attestation|$typeAttestation|$libelle|$dateDemande';
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

  factory AttestationModel.fromJson(Map<String, dynamic> json) {
    final typeAttestation = json['typeAttestation']?.toString() ?? '';
    final libelle = json['libelle']?.toString() ?? 'Sans titre';
    final derniereDemande = json['derniere_demande']?.toString() ?? '';
    final dateDemande = json['dateDemande']?.toString() ?? '';
    
    final status = _parseStatus(json['statut']?.toString() ?? 'Demande');
    
    DateTime? parsedDateDemande = _parseDate(dateDemande);
    DateTime? parsedDerniereDemande = _parseDate(derniereDemande);

    // Use derniereDemande if dateDemande is null
    if (parsedDateDemande == null && parsedDerniereDemande != null) {
      parsedDateDemande = parsedDerniereDemande;
    }

    // Fallback to current date if both are null
    parsedDateDemande ??= DateTime.now();

    return AttestationModel(
      id: _generateId(
        typeAttestation: typeAttestation,
        libelle: libelle,
        dateDemande: parsedDateDemande.toIso8601String(),
      ),
      typeAttestation: typeAttestation,
      libelle: libelle,
      dateDemande: parsedDateDemande,
      derniereDemande: parsedDerniereDemande,
      status: status,
      adminComment: json['adminComment']?.toString(),
      dateTraitement: json['dateTraitement']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeAttestation': typeAttestation,
      'libelle': libelle,
      'dateDemande': dateDemande.toIso8601String(),
      'derniereDemande': derniereDemande?.toIso8601String(),
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

  String get formattedDate {
    return '${dateDemande.day.toString().padLeft(2, '0')}/'
        '${dateDemande.month.toString().padLeft(2, '0')}/'
        '${dateDemande.year}';
  }

  String get statusText => _statusToString(status);
}