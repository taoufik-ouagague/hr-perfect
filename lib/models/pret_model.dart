import 'dart:convert';
import 'package:crypto/crypto.dart';

enum RequestStatus { demande, valide, rejete, annule, enCours }

class PretModel {
  final String id;
  final String motifPret;
  final double montantPret;
  final DateTime datePret;
  final DateTime dateCreation;
  final DateTime? dateValidation;
  final DateTime? dateRejet;
  final DateTime dateDemande;
  final RequestStatus status;
  final String? adminComment;
  final String? dateTraitement;

  PretModel({
    required this.id,
    required this.motifPret,
    required this.montantPret,
    required this.datePret,
    required this.dateCreation,
    this.dateValidation,
    this.dateRejet,
    required this.dateDemande,
    required this.status,
    this.adminComment,
    this.dateTraitement,
  });

  String get formattedMontant => '${montantPret.toStringAsFixed(2)} MAD';
  
  String get title {
    return 'Demande de prêt - ${montantPret.toStringAsFixed(0)} MAD';
  }

  static String _generateId({
    required String montant,
    required String datePret,
    required String dateCreation,
  }) {
    final raw = 'pret|$montant|$datePret|$dateCreation';
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

  // ✅ Factory for creating from API response
  factory PretModel.fromJson(Map<String, dynamic> json) {
    final motifPret = json['motifPret']?.toString() ?? json['libelle']?.toString() ?? '';
    
    final montantPret = (json['montant'] is int)
        ? (json['montant'] as int).toDouble()
        : (json['montantPret'] is int)
            ? (json['montantPret'] as int).toDouble()
            : (json['montant'] as num?)?.toDouble() ?? 
              (json['montantPret'] as num?)?.toDouble() ?? 
              0.0;
    
    final datePretStr = json['datePret']?.toString() ?? '';
    final dateCreationStr = json['dateCreation']?.toString() ?? '';
    final dateValidationStr = json['dateValidation']?.toString() ?? '';
    final dateRejetStr = json['dateRejet']?.toString() ?? '';
    final dateDemandeStr = json['dateDemande']?.toString() ?? '';
    
    final status = _parseStatus(json['statut']?.toString() ?? 'Demande');
    
    DateTime? datePret = _parseDate(datePretStr);
    DateTime? dateCreation = _parseDate(dateCreationStr);
    DateTime? dateValidation = _parseDate(dateValidationStr);
    DateTime? dateRejet = _parseDate(dateRejetStr);
    DateTime? dateDemande = _parseDate(dateDemandeStr);

    // Fallback dates
    datePret ??= DateTime.now();
    dateCreation ??= datePret;
    dateDemande ??= dateCreation;

    return PretModel(
      id: _generateId(
        montant: montantPret.toString(),
        datePret: datePret.toIso8601String(),
        dateCreation: dateCreation.toIso8601String(),
      ),
      motifPret: motifPret,
      montantPret: montantPret,
      datePret: datePret,
      dateCreation: dateCreation,
      dateValidation: dateValidation,
      dateRejet: dateRejet,
      dateDemande: dateDemande,
      status: status,
      adminComment: json['adminComment']?.toString(),
      dateTraitement: json['dateTraitement']?.toString(),
    );
  }

  // ✅ Convert to JSON for API request (matches Postman format)
  Map<String, dynamic> toRequestJson() {
    final day = datePret.day.toString().padLeft(2, '0');
    final month = datePret.month.toString().padLeft(2, '0');
    final year = datePret.year.toString();
    
    return {
      'motifPret': motifPret,
      'datePret': '$day/$month/$year',  // Format: "11/11/2026"
      'montantPret': montantPret.toInt(), // Send as integer
    };
  }

  // ✅ Convert to JSON (full data)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motifPret': motifPret,
      'montant': montantPret,
      'montantPret': montantPret,
      'datePret': datePret.toIso8601String(),
      'dateCreation': dateCreation.toIso8601String(),
      'dateValidation': dateValidation?.toIso8601String(),
      'dateRejet': dateRejet?.toIso8601String(),
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

  String get formattedDatePret => formatDate(datePret);
  String get formattedDateCreation => formatDate(dateCreation);
  String get formattedDateValidation => 
      dateValidation != null ? formatDate(dateValidation!) : '-';
  String get formattedDateRejet => 
      dateRejet != null ? formatDate(dateRejet!) : '-';
  String get formattedDateDemande => formatDate(dateDemande);
  String get statusText => _statusToString(status);
}