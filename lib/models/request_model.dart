import 'dart:convert';
import 'package:crypto/crypto.dart';

enum RequestStatus { demande, valide, rejete, annule }

class EmployeeProfile {
  String name;
  String email;
  String phone;
  String department;
  String position;
  String? photoPath;
  String matricule;
  String ville;
  String dateNaissance;
  String numCnss;
  String situationFamilliale;
  String sexe;
  String anciennete;

  EmployeeProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.position,
    required this.matricule,
    required this.ville,
    required this.dateNaissance,
    required this.numCnss,
    required this.situationFamilliale,
    required this.sexe,
    required this.anciennete,
    this.photoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "phone": phone,
      "department": department,
      "position": position,
      "matricule": matricule,
      "ville": ville,
      "dateNaissance": dateNaissance,
      "numCnss": numCnss,
      "situationFamilliale": situationFamilliale,
      "sexe": sexe,
      "anciennete": anciennete,
      "photoPath": photoPath,
    };
  }

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      name: json["nom"] ?? "",
      email: json["matricule"] ?? "",
      phone: json["telephoneMobile"] ?? "",
      department: json["departement"] ?? "",
      position: json["fonction"] ?? "",
      matricule: json["matricule"] ?? "",
      ville: json["ville"] ?? "",
      dateNaissance: json["dateNaissance"] ?? "",
      numCnss: json["numCnss"] ?? "",
      situationFamilliale: json["situationFamilliale"] ?? "",
      sexe: json["sexe"] ?? "",
      anciennete: json["anciente"] ?? "",
      photoPath: json["photo"], // Fixed: removed ?? Null
    );
  }
}

class Paie {
  final String dateDebut;
  final String dateFin;
  final double netPaye;
  final String encryptedId;
  final String banque;
  final String numCompte;
  final String modePaie;

  Paie({
    required this.dateDebut,
    required this.dateFin,
    required this.netPaye,
    required this.encryptedId,
    required this.banque,
    required this.numCompte,
    required this.modePaie,
  });

  factory Paie.fromJson(Map<String, dynamic> json) {
    return Paie(
      dateDebut: json['dateDebut'] ?? '',
      dateFin: json['dateFin'] ?? '',
      netPaye: (json['netPaye'] ?? 0).toDouble(),
      encryptedId: json['encryptedId'] ?? '',
      banque: json['banque'] ?? '',
      numCompte: json['numCompte'] ?? '',
      modePaie: json['modePaie'] ?? '',
    );
  }

  String get periode => '$dateDebut - $dateFin';

  String get moisAnnee {
    try {
      final parts = dateFin.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[1]);
        final year = parts[2];
        return '${_getMonthName(month)} $year';
      }
    } catch (e) {
      // Fallback
    }
    return dateFin;
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  String get formattedNetPaye => '${netPaye.toStringAsFixed(2)} MAD';

  String get formattedModePaie => modePaie.replaceAll('_', ' ');

  String get maskedNumCompte {
    if (numCompte.length > 4) {
      return '**** ${numCompte.substring(numCompte.length - 4)}';
    }
    return numCompte;
  }
}

class PersonnesACharge {
  String dateNaissance;
  String dateDeclaration;
  String typeCharge;
  String sexe;
  String nom;
  String prenom;
  
  PersonnesACharge({  
    required this.dateNaissance,
    required this.dateDeclaration,
    required this.typeCharge,
    required this.sexe,
    required this.nom,
    required this.prenom,
  });

  Map<String, dynamic> toJson() => {
        'dateNaissance': dateNaissance,
        'dateDeclaration': dateDeclaration,
        'typeCharge': typeCharge,
        'sexe': sexe,
        'nom': nom,
        'prenom': prenom,
      };
}

class MissionFormData {
  String accompagnateur;
  String matricule;
  String objet;
  String carburant;
  String marque;
  String etrange;
  String dateDepart;
  String heureDepart;
  String minDepart;
  String dateRetour;
  String heureRetour;
  String minRetour;
  String nbCheveaux;
  String moyenTransport;
  String designation;

  MissionFormData({
    required this.accompagnateur,
    required this.matricule,
    required this.objet,
    required this.carburant,
    required this.marque,
    required this.etrange,
    required this.dateDepart,
    required this.heureDepart,
    required this.minDepart,
    required this.dateRetour,
    required this.heureRetour,
    required this.minRetour,
    required this.nbCheveaux,
    required this.moyenTransport,
    required this.designation,
  });

  Map<String, dynamic> toJson() => {
        'accompagnateur': accompagnateur,
        'matricule': matricule,
        'objet': objet,
        'carburant': carburant,
        'marque': marque,
        'etrange': etrange,
        'dateDepart': dateDepart,
        'heureDepart': heureDepart,
        'minDepart': minDepart,
        'dateRetour': dateRetour,
        'heureRetour': heureRetour,
        'minRetour': minRetour,
        'nbCheveaux': nbCheveaux,
        'moyenTransport': moyenTransport,
        'designation': designation,
        'statut': 'Actif',
        'nbJour': '0',
      };
}

class RequestModel {
  final String id;
  final String type;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? moyenTransport;
  final String? nbCheveaux;
  final String? heureSortieDebut;
  final String? heureSortieFin;
  final String? dateSortie;
  final String? dateDepart;
  final String? heureDepart;
  final String? minDepart;
  final String? dateRetour;
  final String? heureRetour;
  final String? minRetour;
  final DateTime createdAt;
  final RequestStatus status;
  final String? adminComment;
  final String? derniereDemande;

  RequestModel({
    required this.id,
    required this.type,
    this.moyenTransport,
    this.nbCheveaux,
    this.heureSortieDebut,
    this.heureSortieFin,
    this.dateSortie,
    this.dateDepart,
    this.heureDepart,
    this.minDepart,
    this.dateRetour,
    this.heureRetour,
    this.minRetour,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.adminComment,
    this.derniereDemande,
  });

  int get createdYear => createdAt.year;
  String get typeKey => type;

  String? get formattedMissionDepart {
    if (dateDepart == null) return null;
    String result = dateDepart!;
    if (heureDepart != null && minDepart != null) {
      result += ' à ${heureDepart}h$minDepart';
    }
    return result;
  }

  String? get formattedMissionRetour {
    if (dateRetour == null) return null;
    String result = dateRetour!;
    if (heureRetour != null && minRetour != null) {
      result += ' à ${heureRetour}h$minRetour';
    }
    return result;
  }

  static String _stableId({
    required String type,
    required String title,
    required String dateDebut,
    required String dateFin,
    required String annee,
  }) {
    final raw = '$type|$title|$dateDebut|$dateFin|$annee';
    return md5.convert(utf8.encode(raw)).toString();
  }

  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    String cleaned = dateStr.trim();
    
    // Try ISO format with microseconds
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
      case 'Demande':
      default:
        status = RequestStatus.demande;
        break;
    }

    String type = '';
    String? derniereDemande;
    String? moyenTransport;
    String? nbCheveaux;
    String? heureSortieDebut;
    String? heureSortieFin;
    String? dateSortie;
    String? dateDepart;
    String? heureDepart;
    String? minDepart;
    String? dateRetour;
    String? heureRetour;
    String? minRetour;
    
    if (json.containsKey('typeConge') && json['typeConge'] != null && json['typeConge'].toString().isNotEmpty) {
      type = 'conge';
    } else if (json.containsKey('typeAttestation') && json['typeAttestation'] != null) {
      type = 'attestation';
      derniereDemande = json['derniere_demande']?.toString();
    } else if (json.containsKey('typeSortie') && json['typeSortie'] != null) {
      type = 'sortie';
      heureSortieDebut = json['heureSortieDebut']?.toString();
      heureSortieFin = json['heureSortieFin']?.toString();
      dateSortie = json['dateSortie']?.toString();
    } else if (json.containsKey('typeMission') && json['typeMission'] != null) {
      type = 'mission';
      moyenTransport = json['moyenTransport']?.toString();
      nbCheveaux = json['nbCheveaux']?.toString();
      dateDepart = json['dateDepart']?.toString();
      heureDepart = json['heureDepart']?.toString();
      minDepart = json['minDepart']?.toString();
      dateRetour = json['dateRetour']?.toString();
      heureRetour = json['heureRetour']?.toString();
      minRetour = json['minRetour']?.toString();
    } else {
      if (json.containsKey('moyenTransport') || json.containsKey('designation')) {
        type = 'mission';
        moyenTransport = json['moyenTransport']?.toString();
        nbCheveaux = json['nbCheveaux']?.toString();
        dateDepart = json['dateDepart']?.toString();
        heureDepart = json['heureDepart']?.toString();
        minDepart = json['minDepart']?.toString();
        dateRetour = json['dateRetour']?.toString();
        heureRetour = json['heureRetour']?.toString();
        minRetour = json['minRetour']?.toString();
      } else if (json.containsKey('heureSortieDebut') || json.containsKey('heureSortieFin') || json.containsKey('dateSortie')) {
        type = 'sortie';
        heureSortieDebut = json['heureSortieDebut']?.toString();
        heureSortieFin = json['heureSortieFin']?.toString();
        dateSortie = json['dateSortie']?.toString();
      } else if (json.containsKey('typeConge')) {
        type = 'conge';
      } else {
        type = 'attestation';
        derniereDemande = json['derniere_demande']?.toString();
      }
    }

    String title = '';
    if (type == 'mission') {
      title = json['objet']?.toString() ?? json['designation']?.toString() ?? 'Mission';
    } else {
      title = (json['libelle'] ?? json['motif'] ?? json['objet'] ?? 'Sans titre').toString();
    }

    final d1 = (json['dateDebut'] ?? json['dateDemande'] ?? json['dateSortie'] ?? json['dateDepart'] ?? json['derniere_demande'] ?? '').toString();
    final d2 = (json['dateFin'] ?? json['dateRetour'] ?? json['dateSortie'] ?? json['derniere_demande'] ?? '').toString();
    final yearStr = (json['annee'] ?? '2000').toString();

    DateTime? startDate = _parseDate(d1);
    DateTime? endDate = _parseDate(d2);

    startDate ??= DateTime(2000, 1, 1);
    endDate ??= DateTime(2000, 1, 1);

    if (type == 'attestation' && derniereDemande != null && derniereDemande.isNotEmpty) {
      final parsedDerniereDemande = _parseDate(derniereDemande);
      if (parsedDerniereDemande != null) {
        startDate = parsedDerniereDemande;
        endDate = parsedDerniereDemande;
      }
    }

    int year = int.tryParse(yearStr) ?? startDate.year;
    DateTime createdAt = DateTime(year);

    return RequestModel(
      id: _stableId(
        type: type,
        title: title,
        dateDebut: d1,
        dateFin: d2,
        annee: yearStr,
      ),
      type: type,
      title: title,
      startDate: startDate,
      endDate: endDate,
      reason: title,
      createdAt: createdAt,
      status: status,
      adminComment: json['adminComment']?.toString(),
      derniereDemande: derniereDemande,
      moyenTransport: moyenTransport,
      nbCheveaux: nbCheveaux,
      heureSortieDebut: heureSortieDebut,
      heureSortieFin: heureSortieFin,
      dateSortie: dateSortie,
      dateDepart: dateDepart,
      heureDepart: heureDepart,
      minDepart: minDepart,
      dateRetour: dateRetour,
      heureRetour: heureRetour,
      minRetour: minRetour,
    );
  }
}