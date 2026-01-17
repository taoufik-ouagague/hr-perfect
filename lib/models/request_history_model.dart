import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Enum for request status
enum RequestStatus { 
  demande, 
  valide, 
  rejete, 
  annule, 
  enCours 
}

/// Enum for request type
enum RequestType {
  conge,
  attestation,
  sortie,
  mission,
  reclamation,
  pret
}

/// Model for Request History
class RequestHistoryModel {
  final String id;
  final RequestType requestType;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final DateTime createdAt;
  final RequestStatus status;
  final String? adminComment;

  // Type-specific fields
  final CongeDetails? congeDetails;
  final AttestationDetails? attestationDetails;
  final SortieDetails? sortieDetails;
  final MissionDetails? missionDetails;
  final ReclamationDetails? reclamationDetails;
  final PretDetails? pretDetails;

  RequestHistoryModel({
    required this.id,
    required this.requestType,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.adminComment,
    this.congeDetails,
    this.attestationDetails,
    this.sortieDetails,
    this.missionDetails,
    this.reclamationDetails,
    this.pretDetails,
  });

  /// Get request type as string key
  String get typeKey => requestType.name;

  /// Get year from creation date
  int get createdYear => createdAt.year;

  /// Factory constructor from JSON
  factory RequestHistoryModel.fromJson(Map<String, dynamic> json) {
    // Parse status
    final status = _parseStatus(json['statut']?.toString() ?? 'Demande');
    
    // Determine request type and parse specific details
    final typeInfo = _determineType(json);
    final requestType = typeInfo['type'] as RequestType;
    
    // Parse dates
    final dateInfo = _parseDates(json, requestType);
    
    // Generate title
    final title = _generateTitle(json, requestType, typeInfo);
    
    // Create type-specific details
    final details = _createTypeDetails(json, requestType);

    return RequestHistoryModel(
      id: _generateStableId(
        type: requestType.name,
        title: title,
        dateDebut: dateInfo['d1'] as String,
        dateFin: dateInfo['d2'] as String,
        annee: dateInfo['annee'] as String,
      ),
      requestType: requestType,
      title: title,
      startDate: dateInfo['startDate'] as DateTime,
      endDate: dateInfo['endDate'] as DateTime,
      reason: title,
      createdAt: dateInfo['createdAt'] as DateTime,
      status: status,
      adminComment: json['adminComment']?.toString(),
      congeDetails: details['conge'] as CongeDetails?,
      attestationDetails: details['attestation'] as AttestationDetails?,
      sortieDetails: details['sortie'] as SortieDetails?,
      missionDetails: details['mission'] as MissionDetails?,
      reclamationDetails: details['reclamation'] as ReclamationDetails?,
      pretDetails: details['pret'] as PretDetails?,
    );
  }

  /// Parse request status from string
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
      default:
        return RequestStatus.demande;
    }
  }

  /// Determine request type from JSON
  static Map<String, dynamic> _determineType(Map<String, dynamic> json) {
    // Check for Prêt
    if (json.containsKey('montant') && json['montant'] != null) {
      return {'type': RequestType.pret};
    }

    // Check for Réclamation
    if (json.containsKey('type') && json['type'] != null) {
      final typeValue = json['type'].toString().toUpperCase();
      if (typeValue == 'ALERTE' || typeValue == 'RECLAMATION') {
        return {'type': RequestType.reclamation};
      }
    }

    // Check for Congé
    if (json.containsKey('typeConge') && 
        json['typeConge'] != null && 
        json['typeConge'].toString().isNotEmpty) {
      return {'type': RequestType.conge};
    }

    // Check for Attestation
    if (json.containsKey('typeAttestation') && json['typeAttestation'] != null) {
      return {'type': RequestType.attestation};
    }

    // Check for Sortie
    if (json.containsKey('typeSortie') && json['typeSortie'] != null) {
      return {'type': RequestType.sortie};
    }

    // Check for Mission
    if (json.containsKey('typeMission') && json['typeMission'] != null) {
      return {'type': RequestType.mission};
    }

    // Fallback detection by fields
    if (json.containsKey('moyenTransport') || json.containsKey('designation')) {
      return {'type': RequestType.mission};
    }
    
    if (json.containsKey('heureSortieDebut') || 
        json.containsKey('heureSortieFin') || 
        json.containsKey('dateSortie')) {
      return {'type': RequestType.sortie};
    }

    // Default to attestation
    return {'type': RequestType.attestation};
  }

  /// Parse dates from JSON
  static Map<String, dynamic> _parseDates(
    Map<String, dynamic> json, 
    RequestType type,
  ) {
    final d1 = (json['dateDebut'] ??
        json['dateDemande'] ??
        json['dateSortie'] ??
        json['dateDepart'] ??
        json['dateReclamation'] ??
        json['dateCreation'] ??
        json['datePret'] ??
        json['derniere_demande'] ??
        '').toString();

    final d2 = (json['dateFin'] ??
        json['dateRetour'] ??
        json['dateSortie'] ??
        json['dateReclamation'] ??
        json['datePret'] ??
        json['dateValidation'] ??
        json['derniere_demande'] ??
        '').toString();

    final yearStr = (json['annee'] ?? '2000').toString();

    DateTime? startDate = _parseDate(d1);
    DateTime? endDate = _parseDate(d2);
    final dateDemande = _parseDate(json['dateDemande']?.toString() ?? '');

    startDate ??= DateTime(2000, 1, 1);
    endDate ??= DateTime(2000, 1, 1);

    // Special handling for attestation
    if (type == RequestType.attestation) {
      final derniereDemande = json['derniere_demande']?.toString();
      if (derniereDemande != null && derniereDemande.isNotEmpty) {
        final parsed = _parseDate(derniereDemande);
        if (parsed != null) {
          startDate = parsed;
          endDate = parsed;
        }
      }
    }

    // Special handling for prêt
    if (type == RequestType.pret) {
      final dateCreationPret = json['dateCreation']?.toString();
      if (dateCreationPret != null && dateCreationPret.isNotEmpty) {
        final parsed = _parseDate(dateCreationPret);
        if (parsed != null) {
          startDate = parsed;
          endDate = parsed;
        }
      }
    }

    final createdAt = dateDemande ?? startDate;

    return {
      'd1': d1,
      'd2': d2,
      'annee': yearStr,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': createdAt,
    };
  }

  /// Generate title based on type
  static String _generateTitle(
    Map<String, dynamic> json,
    RequestType type,
    Map<String, dynamic> typeInfo,
  ) {
    switch (type) {
      case RequestType.mission:
        return json['objet']?.toString() ??
            json['designation']?.toString() ??
            'Mission';
      
      case RequestType.reclamation:
        return json['libelle']?.toString() ?? 'Réclamation';
      
      case RequestType.pret:
        final montant = (json['montant'] is int)
            ? (json['montant'] as int).toDouble()
            : (json['montant'] as num?)?.toDouble();
        String title = 'Demande de prêt';
        if (montant != null) {
          title += ' - ${montant.toStringAsFixed(0)} MAD';
        }
        return title;
      
      default:
        return (json['libelle'] ?? 
                json['motif'] ?? 
                json['objet'] ?? 
                'Sans titre').toString();
    }
  }

  /// Create type-specific details
  static Map<String, dynamic> _createTypeDetails(
    Map<String, dynamic> json,
    RequestType type,
  ) {
    return {
      'conge': type == RequestType.conge ? CongeDetails.fromJson(json) : null,
      'attestation': type == RequestType.attestation 
          ? AttestationDetails.fromJson(json) 
          : null,
      'sortie': type == RequestType.sortie ? SortieDetails.fromJson(json) : null,
      'mission': type == RequestType.mission 
          ? MissionDetails.fromJson(json) 
          : null,
      'reclamation': type == RequestType.reclamation 
          ? ReclamationDetails.fromJson(json) 
          : null,
      'pret': type == RequestType.pret ? PretDetails.fromJson(json) : null,
    };
  }

  /// Parse date string to DateTime
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    String cleaned = dateStr.trim();

    // Try ISO format
    DateTime? parsed = DateTime.tryParse(cleaned);
    if (parsed != null) return parsed;

    // Try ISO format with space instead of T
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

  /// Generate stable ID for the request
  static String _generateStableId({
    required String type,
    required String title,
    required String dateDebut,
    required String dateFin,
    required String annee,
  }) {
    final raw = '$type|$title|$dateDebut|$dateFin|$annee';
    return md5.convert(utf8.encode(raw)).toString();
  }
}

// ============================================================================
// Type-Specific Detail Models
// ============================================================================

/// Details for Congé (Leave) requests
class CongeDetails {
  final String? typeConge;

  CongeDetails({this.typeConge});

  factory CongeDetails.fromJson(Map<String, dynamic> json) {
    return CongeDetails(
      typeConge: json['typeConge']?.toString(),
    );
  }
}

/// Details for Attestation (Certificate) requests
class AttestationDetails {
  final String? typeAttestation;
  final String? derniereDemande;

  AttestationDetails({
    this.typeAttestation,
    this.derniereDemande,
  });

  factory AttestationDetails.fromJson(Map<String, dynamic> json) {
    return AttestationDetails(
      typeAttestation: json['typeAttestation']?.toString(),
      derniereDemande: json['derniere_demande']?.toString(),
    );
  }
}

/// Details for Sortie (Exit) requests
class SortieDetails {
  final String? typeSortie;
  final String? heureSortieDebut;
  final String? heureSortieFin;
  final String? dateSortie;

  SortieDetails({
    this.typeSortie,
    this.heureSortieDebut,
    this.heureSortieFin,
    this.dateSortie,
  });

  factory SortieDetails.fromJson(Map<String, dynamic> json) {
    return SortieDetails(
      typeSortie: json['typeSortie']?.toString(),
      heureSortieDebut: json['heureSortieDebut']?.toString(),
      heureSortieFin: json['heureSortieFin']?.toString(),
      dateSortie: json['dateSortie']?.toString(),
    );
  }

  /// Get formatted time range
  String? get formattedTimeRange {
    if (heureSortieDebut != null && heureSortieFin != null) {
      return '$heureSortieDebut - $heureSortieFin';
    }
    return null;
  }
}

/// Details for Mission requests
class MissionDetails {
  final String? typeMission;
  final String? moyenTransport;
  final String? nbCheveaux;
  final String? dateDepart;
  final String? heureDepart;
  final String? minDepart;
  final String? dateRetour;
  final String? heureRetour;
  final String? minRetour;
  final String? objet;
  final String? designation;

  MissionDetails({
    this.typeMission,
    this.moyenTransport,
    this.nbCheveaux,
    this.dateDepart,
    this.heureDepart,
    this.minDepart,
    this.dateRetour,
    this.heureRetour,
    this.minRetour,
    this.objet,
    this.designation,
  });

  factory MissionDetails.fromJson(Map<String, dynamic> json) {
    return MissionDetails(
      typeMission: json['typeMission']?.toString(),
      moyenTransport: json['moyenTransport']?.toString(),
      nbCheveaux: json['nbCheveaux']?.toString(),
      dateDepart: json['dateDepart']?.toString(),
      heureDepart: json['heureDepart']?.toString(),
      minDepart: json['minDepart']?.toString(),
      dateRetour: json['dateRetour']?.toString(),
      heureRetour: json['heureRetour']?.toString(),
      minRetour: json['minRetour']?.toString(),
      objet: json['objet']?.toString(),
      designation: json['designation']?.toString(),
    );
  }

  /// Get formatted departure datetime
  String? get formattedDepart {
    if (dateDepart == null) return null;
    String result = dateDepart!;
    if (heureDepart != null && minDepart != null) {
      result += ' à ${heureDepart}h$minDepart';
    }
    return result;
  }

  /// Get formatted return datetime
  String? get formattedRetour {
    if (dateRetour == null) return null;
    String result = dateRetour!;
    if (heureRetour != null && minRetour != null) {
      result += ' à ${heureRetour}h$minRetour';
    }
    return result;
  }
}

/// Details for Réclamation (Complaint) requests
class ReclamationDetails {
  final String? typeReclamation;
  final String? dateReclamation;
  final String? dateTraitement;
  final String? libelle;

  ReclamationDetails({
    this.typeReclamation,
    this.dateReclamation,
    this.dateTraitement,
    this.libelle,
  });

  factory ReclamationDetails.fromJson(Map<String, dynamic> json) {
    return ReclamationDetails(
      typeReclamation: json['type']?.toString(),
      dateReclamation: json['dateReclamation']?.toString(),
      dateTraitement: json['dateTraitement']?.toString(),
      libelle: json['libelle']?.toString(),
    );
  }
}

/// Details for Prêt (Loan) requests
class PretDetails {
  final double? montant;
  final String? dateCreation;
  final String? datePret;
  final String? dateValidation;
  final String? dateRejet;

  PretDetails({
    this.montant,
    this.dateCreation,
    this.datePret,
    this.dateValidation,
    this.dateRejet,
  });

  factory PretDetails.fromJson(Map<String, dynamic> json) {
    final montant = (json['montant'] is int)
        ? (json['montant'] as int).toDouble()
        : (json['montant'] as num?)?.toDouble();

    return PretDetails(
      montant: montant,
      dateCreation: json['dateCreation']?.toString(),
      datePret: json['datePret']?.toString(),
      dateValidation: json['dateValidation']?.toString(),
      dateRejet: json['dateRejet']?.toString(),
    );
  }

  /// Get formatted amount
  String get formattedMontant {
    if (montant == null) return '';
    return '${montant!.toStringAsFixed(0)} MAD';
  }
}