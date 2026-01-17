// ============================================================
// reclamation_model.dart
// ============================================================

class ReclamationModel {
  final String? id;
  final String libelle;
  final String type; // 'ALERTE' ou 'RECLAMATION'
  final DateTime dateReclamation;
  final DateTime dateTraitement;
  final String? dateTraitementStr;
  final String statut; // 'Demande', 'Validé', 'Rejeté', etc.
  final String? adminComment;
  final DateTime? createdAt;

  ReclamationModel({
    this.id,
    required this.libelle,
    required this.type,
    required this.dateReclamation,
    required this.dateTraitement,
    this.dateTraitementStr,
    this.statut = 'Demande',
    this.adminComment,
    this.createdAt,
  });

  // Factory constructor pour créer depuis JSON
  factory ReclamationModel.fromJson(Map<String, dynamic> json) {
    return ReclamationModel(
      id: json['id']?.toString(),
      libelle: json['libelle']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ALERTE',
      dateReclamation: _parseDate(json['dateReclamation']?.toString()) ?? DateTime.now(),
      dateTraitement: _parseDate(json['dateTraitement']?.toString()) ?? DateTime.now(),
      dateTraitementStr: json['dateTraitement']?.toString(),
      statut: json['statut']?.toString() ?? 'Demande',
      adminComment: json['adminComment']?.toString(),
      createdAt: _parseDate(json['createdAt']?.toString()),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'type': type,
      'dateReclamation': _formatDate(dateReclamation),
      'dateTraitement': _formatDate(dateTraitement),
      'statut': statut,
      'adminComment': adminComment,
    };
  }

  // Helper pour parser les dates
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      // Format dd/MM/yyyy
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
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

  // Helper pour formater les dates
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  // Getters utiles
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

  String get typeLabel {
    return type == 'ALERTE' ? 'Alerte' : 'Réclamation';
  }

  // Copie avec modifications
  ReclamationModel copyWith({
    String? id,
    String? libelle,
    String? type,
    DateTime? dateReclamation,
    DateTime? dateTraitement,
    String? dateTraitementStr,
    String? statut,
    String? adminComment,
    DateTime? createdAt,
  }) {
    return ReclamationModel(
      id: id ?? this.id,
      libelle: libelle ?? this.libelle,
      type: type ?? this.type,
      dateReclamation: dateReclamation ?? this.dateReclamation,
      dateTraitement: dateTraitement ?? this.dateTraitement,
      dateTraitementStr: dateTraitementStr ?? this.dateTraitementStr,
      statut: statut ?? this.statut,
      adminComment: adminComment ?? this.adminComment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}