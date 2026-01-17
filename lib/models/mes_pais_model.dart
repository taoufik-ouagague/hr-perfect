class PaieModel {
  final String dateDebut;
  final String dateFin;
  final double netPaye;
  final String encryptedId;
  final String banque;
  final String numCompte;
  final String modePaie;

  PaieModel({
    required this.dateDebut,
    required this.dateFin,
    required this.netPaye,
    required this.encryptedId,
    required this.banque,
    required this.numCompte,
    required this.modePaie,
  });

  // Factory constructor pour créer depuis JSON
  factory PaieModel.fromJson(Map<String, dynamic> json) {
    return PaieModel(
      dateDebut: json['dateDebut']?.toString() ?? '',
      dateFin: json['dateFin']?.toString() ?? '',
      netPaye: (json['netPaye'] ?? 0).toDouble(),
      encryptedId: json['encryptedId']?.toString() ?? '',
      banque: json['banque']?.toString() ?? '',
      numCompte: json['numCompte']?.toString() ?? '',
      modePaie: json['modePaie']?.toString() ?? '',
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'dateDebut': dateDebut,
      'dateFin': dateFin,
      'netPaye': netPaye,
      'encryptedId': encryptedId,
      'banque': banque,
      'numCompte': numCompte,
      'modePaie': modePaie,
    };
  }

  // Getters utiles

  /// Période complète (ex: "01/01/2024 - 31/01/2024")
  String get periode => '$dateDebut - $dateFin';

  /// Mois et année formatés (ex: "Janvier 2024")
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

  /// Net payé formaté (ex: "12500.50 MAD")
  String get formattedNetPaye => '${netPaye.toStringAsFixed(2)} MAD';

  /// Mode de paie formaté (remplace les underscores par des espaces)
  String get formattedModePaie => modePaie.replaceAll('_', ' ');

  /// Numéro de compte masqué (ex: "**** 1234")
  String get maskedNumCompte {
    if (numCompte.length > 4) {
      return '**** ${numCompte.substring(numCompte.length - 4)}';
    }
    return numCompte;
  }

  /// Année de la paie
  int get annee {
    try {
      final parts = dateFin.split('/');
      if (parts.length == 3) {
        return int.parse(parts[2]);
      }
    } catch (e) {
      return DateTime.now().year;
    }
    return DateTime.now().year;
  }

  /// Mois de la paie (1-12)
  int get mois {
    try {
      final parts = dateFin.split('/');
      if (parts.length == 3) {
        return int.parse(parts[1]);
      }
    } catch (e) {
      return DateTime.now().month;
    }
    return DateTime.now().month;
  }

  /// Helper privé pour obtenir le nom du mois
  String _getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Inconnu';
  }

  // Copie avec modifications
  PaieModel copyWith({
    String? dateDebut,
    String? dateFin,
    double? netPaye,
    String? encryptedId,
    String? banque,
    String? numCompte,
    String? modePaie,
  }) {
    return PaieModel(
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      netPaye: netPaye ?? this.netPaye,
      encryptedId: encryptedId ?? this.encryptedId,
      banque: banque ?? this.banque,
      numCompte: numCompte ?? this.numCompte,
      modePaie: modePaie ?? this.modePaie,
    );
  }

  @override
  String toString() {
    return 'PaieModel(periode: $periode, netPaye: $formattedNetPaye, '
           'banque: $banque, compte: $maskedNumCompte)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaieModel && other.encryptedId == encryptedId;
  }

  @override
  int get hashCode => encryptedId.hashCode;
}

