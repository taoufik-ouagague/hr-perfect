import 'dart:convert';
import 'package:crypto/crypto.dart';

enum RequestStatus { demande, valide, rejete, annule, enCours }

class RequestModel {
  final String id;
  final String type;
  final RequestStatus status;
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  int get createdYear => createdAt.year;
  String get typeKey => type;

  static String _stableId({
    required String type,
    required String dateDebut,
    required String dateFin,
    required String annee,
  }) {
    final raw = '$type|$dateDebut|$dateFin|$annee';
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
          // Continue to next attempt
        }
      }
    }

    // Try yyyy-MM-dd format
    if (cleaned.contains('-') && !cleaned.contains(':')) {
      final parts = cleaned.split('-');
      if (parts.length == 3) {
        try {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        } catch (e) {
          // Continue
        }
      }
    }

    return null;
  }

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    // Parse status
    final statut = (json['statut'] ?? 'Demande').toString();
    late RequestStatus status;

    switch (statut) {
      case 'Validé':
        status = RequestStatus.valide;
        break;
      case 'Rejeté':
        status = RequestStatus.rejete;
        break;
      case 'Annulé':
        status = RequestStatus.annule;
        break;
      case 'En cours':
        status = RequestStatus.enCours;
        break;
      case 'Demande':
      default:
        status = RequestStatus.demande;
        break;
    }

    // Determine type
    String type = '';
    
    if (json.containsKey('montant') && json['montant'] != null) {
      type = 'pret';
    } else if (json.containsKey('type') &&
        json['type'] != null &&
        json['type'].toString().isNotEmpty) {
      final typeValue = json['type'].toString().toUpperCase();
      if (typeValue == 'ALERTE' || typeValue == 'RECLAMATION') {
        type = 'reclamation';
      }
    }

    if (type.isEmpty) {
      if (json.containsKey('typeConge') && json['typeConge'] != null) {
        type = 'conge';
      } else if (json.containsKey('typeAttestation') && json['typeAttestation'] != null) {
        type = 'attestation';
      } else if (json.containsKey('typeSortie') && json['typeSortie'] != null) {
        type = 'sortie';
      } else if (json.containsKey('typeMission') && json['typeMission'] != null) {
        type = 'mission';
      } else {
        // Fallback detection
        if (json.containsKey('moyenTransport') || json.containsKey('designation')) {
          type = 'mission';
        } else if (json.containsKey('heureSortieDebut') ||
            json.containsKey('heureSortieFin') ||
            json.containsKey('dateSortie')) {
          type = 'sortie';
        } else if (json.containsKey('typeConge')) {
          type = 'conge';
        } else {
          type = 'attestation';
        }
      }
    }

    // Parse dates for ID generation
    final d1 = (json['dateDebut'] ??
            json['dateDemande'] ??
            json['dateSortie'] ??
            json['dateDepart'] ??
            json['dateReclamation'] ??
            json['dateCreation'] ??
            json['datePret'] ??
            json['derniere_demande'] ??
            '')
        .toString();
    
    final d2 = (json['dateFin'] ??
            json['dateRetour'] ??
            json['dateSortie'] ??
            json['dateReclamation'] ??
            json['datePret'] ??
            json['dateValidation'] ??
            json['derniere_demande'] ??
            '')
        .toString();
    
    final yearStr = (json['annee'] ?? '2000').toString();

    // Parse creation date
    final dateDemande = _parseDate(json['dateDemande']?.toString() ?? '');
    DateTime? startDate = _parseDate(d1);
    
    startDate ??= DateTime(2000, 1, 1);
    DateTime createdAt = dateDemande ?? startDate;

    return RequestModel(
      id: _stableId(
        type: type,
        dateDebut: d1,
        dateFin: d2,
        annee: yearStr,
      ),
      type: type,
      status: status,
      createdAt: createdAt,
    );
  }
}