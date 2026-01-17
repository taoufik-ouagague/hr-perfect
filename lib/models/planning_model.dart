// ============================================================
// planning_model.dart - Planning/Visit Model
// ============================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';

enum RequestStatus { demande, valide, rejete, annule, enCours }

class PlanningModel {
  final String id;
  final String idTypeVisite;
  final String typeVisite;
  final String client;
  final String objet;
  final DateTime datePrevu;
  final DateTime dateDemande;
  final RequestStatus status;
  final String? adminComment;
  final String? dateTraitement;

  PlanningModel({
    required this.id,
    required this.idTypeVisite,
    required this.typeVisite,
    required this.client,
    required this.objet,
    required this.datePrevu,
    required this.dateDemande,
    required this.status,
    this.adminComment,
    this.dateTraitement,
  });

  static String _generateId({
    required String typeVisite,
    required String client,
    required String datePrevu,
  }) {
    final raw = 'planning|$typeVisite|$client|$datePrevu';
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

    // Try dd/MM/yyyy HH:mm format
    if (cleaned.contains('/')) {
      try {
        final parts = cleaned.split(' ');
        if (parts.isNotEmpty) {
          final dateParts = parts[0].split('/');
          if (dateParts.length == 3) {
            final day = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final year = int.parse(dateParts[2]);
            
            int hour = 0;
            int minute = 0;
            
            if (parts.length > 1) {
              final timeParts = parts[1].split(':');
              if (timeParts.length >= 2) {
                hour = int.parse(timeParts[0]);
                minute = int.parse(timeParts[1]);
              }
            }
            
            return DateTime(year, month, day, hour, minute);
          }
        }
      } catch (e) {
        // Continue
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

  factory PlanningModel.fromJson(Map<String, dynamic> json) {
    final idTypeVisite = json['idTypeVisite']?.toString() ?? '';
    final typeVisite = json['typedevisite']?.toString() ?? json['typeVisite']?.toString() ?? '';
    final client = json['client']?.toString() ?? '';
    final objet = json['objet']?.toString() ?? '';
    
    final datePrevuStr = json['datePrevu']?.toString() ?? '';
    final dateDemandeStr = json['dateDemande']?.toString() ?? '';
    
    final status = _parseStatus(json['statut']?.toString() ?? 'Demande');
    
    DateTime? datePrevu = _parseDate(datePrevuStr);
    DateTime? dateDemande = _parseDate(dateDemandeStr);

    // Fallback dates
    datePrevu ??= DateTime.now();
    dateDemande ??= datePrevu;

    return PlanningModel(
      id: _generateId(
        typeVisite: typeVisite,
        client: client,
        datePrevu: datePrevu.toIso8601String(),
      ),
      idTypeVisite: idTypeVisite,
      typeVisite: typeVisite,
      client: client,
      objet: objet,
      datePrevu: datePrevu,
      dateDemande: dateDemande,
      status: status,
      adminComment: json['adminComment']?.toString(),
      dateTraitement: json['dateTraitement']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idTypeVisite': idTypeVisite,
      'typedevisite': typeVisite,
      'client': client,
      'objet': objet,
      'datePrevu': datePrevu.toIso8601String(),
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

  String formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDatePrevu => formatDateTime(datePrevu);
  String get formattedDatePrevuDate => formatDate(datePrevu);
  String get formattedDatePrevuTime => formatTime(datePrevu);
  String get formattedDateDemande => formatDate(dateDemande);
  String get statusText => _statusToString(status);
}