

import 'dart:convert';
import 'package:crypto/crypto.dart';

enum RequestStatus { demande, valide, rejete, annule, enCours }

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

class MissionModel {
  final String id;
  final String typeMission;
  final String objet;
  final String designation;
  final String accompagnateur;
  final String matricule;
  final DateTime dateDepart;
  final String heureDepart;
  final String minDepart;
  final DateTime dateRetour;
  final String heureRetour;
  final String minRetour;
  final String moyenTransport;
  final String nbCheveaux;
  final String marque;
  final String carburant;
  final String etranger;
  final DateTime dateDemande;
  final RequestStatus status;
  final String? adminComment;
  final String? dateTraitement;

  MissionModel({
    required this.id,
    required this.typeMission,
    required this.objet,
    required this.designation,
    required this.accompagnateur,
    required this.matricule,
    required this.dateDepart,
    required this.heureDepart,
    required this.minDepart,
    required this.dateRetour,
    required this.heureRetour,
    required this.minRetour,
    required this.moyenTransport,
    required this.nbCheveaux,
    required this.marque,
    required this.carburant,
    required this.etranger,
    required this.dateDemande,
    required this.status,
    this.adminComment,
    this.dateTraitement,
  });

  String get formattedDateDepart {
    final dateStr = '${dateDepart.day.toString().padLeft(2, '0')}/'
        '${dateDepart.month.toString().padLeft(2, '0')}/'
        '${dateDepart.year}';
    return '$dateStr à ${heureDepart}h$minDepart';
  }

  String get formattedDateRetour {
    final dateStr = '${dateRetour.day.toString().padLeft(2, '0')}/'
        '${dateRetour.month.toString().padLeft(2, '0')}/'
        '${dateRetour.year}';
    return '$dateStr à ${heureRetour}h$minRetour';
  }

  int get numberOfDays {
    return dateRetour.difference(dateDepart).inDays + 1;
  }

  static String _generateId({
    required String objet,
    required String dateDepart,
    required String dateRetour,
  }) {
    final raw = 'mission|$objet|$dateDepart|$dateRetour';
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

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    final typeMission = json['typeMission']?.toString() ?? '';
    final objet = json['objet']?.toString() ?? json['designation']?.toString() ?? 'Mission';
    final designation = json['designation']?.toString() ?? '';
    final accompagnateur = json['accompagnateur']?.toString() ?? '';
    final matricule = json['matricule']?.toString() ?? '';
    
    final dateDepartStr = json['dateDepart']?.toString() ?? '';
    final dateRetourStr = json['dateRetour']?.toString() ?? '';
    final dateDemandeStr = json['dateDemande']?.toString() ?? '';
    
    final heureDepart = json['heureDepart']?.toString() ?? '08';
    final minDepart = json['minDepart']?.toString() ?? '00';
    final heureRetour = json['heureRetour']?.toString() ?? '17';
    final minRetour = json['minRetour']?.toString() ?? '00';
    
    final moyenTransport = json['moyenTransport']?.toString() ?? '';
    final nbCheveaux = json['nbCheveaux']?.toString() ?? '';
    final marque = json['marque']?.toString() ?? '';
    final carburant = json['carburant']?.toString() ?? '';
    final etranger = json['etrange']?.toString() ?? 'Non';
    
    final status = _parseStatus(json['statut']?.toString() ?? 'Demande');
    
    DateTime? dateDepart = _parseDate(dateDepartStr);
    DateTime? dateRetour = _parseDate(dateRetourStr);
    DateTime? dateDemande = _parseDate(dateDemandeStr);

    // Fallback dates
    dateDepart ??= DateTime.now();
    dateRetour ??= DateTime.now();
    dateDemande ??= dateDepart;

    return MissionModel(
      id: _generateId(
        objet: objet,
        dateDepart: dateDepart.toIso8601String(),
        dateRetour: dateRetour.toIso8601String(),
      ),
      typeMission: typeMission,
      objet: objet,
      designation: designation,
      accompagnateur: accompagnateur,
      matricule: matricule,
      dateDepart: dateDepart,
      heureDepart: heureDepart,
      minDepart: minDepart,
      dateRetour: dateRetour,
      heureRetour: heureRetour,
      minRetour: minRetour,
      moyenTransport: moyenTransport,
      nbCheveaux: nbCheveaux,
      marque: marque,
      carburant: carburant,
      etranger: etranger,
      dateDemande: dateDemande,
      status: status,
      adminComment: json['adminComment']?.toString(),
      dateTraitement: json['dateTraitement']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeMission': typeMission,
      'objet': objet,
      'designation': designation,
      'accompagnateur': accompagnateur,
      'matricule': matricule,
      'dateDepart': dateDepart.toIso8601String(),
      'heureDepart': heureDepart,
      'minDepart': minDepart,
      'dateRetour': dateRetour.toIso8601String(),
      'heureRetour': heureRetour,
      'minRetour': minRetour,
      'moyenTransport': moyenTransport,
      'nbCheveaux': nbCheveaux,
      'marque': marque,
      'carburant': carburant,
      'etrange': etranger,
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

  String get statusText => _statusToString(status);
}