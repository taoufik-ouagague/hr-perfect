
class ApiService {
  static const String baseUrl = 'https://my.hrperfect.ma:3746/HRPERFECT/rhapi.do';

  // Authentification
  static String authentificationMobile() {
    return '$baseUrl?do=authentificationMobile';
  }

  // Conges
  static String mesConges() {
    return '$baseUrl?do=mesConges';
  }

  static String addConges() {
    return '$baseUrl?do=addConges';
  }

  // Personnes à charges
  static String mesPersonnesACharges() {
    return '$baseUrl?do=mesPersonnesACharges';
  }

    // mesNotifications
  static String mesNotifications() {
    return '$baseUrl?do=mesnotification';
  }

  // Avantages en natures
  static String mesAvantagesNatures() {
    return '$baseUrl?do=mesAvantagesNatures';
  }



  // Sanctions
  static String mesSanctions() {
    return '$baseUrl?do=mesSanctions';
  }

  // Formations
  static String mesFormations() {
    return '$baseUrl?do=mesFormations';
  }

  // Diplomes
  static String mesDiplomes() {
    return '$baseUrl?do=mesDiplomes';
  }

  // Expériences
  static String mesExperiences() {
    return '$baseUrl?do=mesExperiences';
  }
    static String getTransportsChevaux() {
    return '$baseUrl?do=getTransportsChevaux';
  }
    static String getMoyensTransports() {
    return '$baseUrl?do=getMoyensTransports';
  }
  // Jours ouvrables
  static String mesJourOuvrable() {
    return '$baseUrl?do=mesJourOuvrable';
  }

  // Organismes retraites
  static String mesOrganismesRetraites() {
    return '$baseUrl?do=mesOrganismesRetraites';
  }

  // Organismes mutuelles
  static String mesOrganismesMutuelles() {
    return '$baseUrl?do=mesOrganismesMutuelles';
  }

  // Mode de paiement
  static String mesModesPaies() {
    return '$baseUrl?do=mesModesPaies';
  }

  // Carrières
  static String mesCarrieres() {
    return '$baseUrl?do=mesCarrieres';
  }

  // Attestations
  static String getTypesAttestations() {
    return '$baseUrl?do=getTypesAttestations';
  }

  static String addAttestations(int idType) {
    return '$baseUrl?do=addAttestations&idType=$idType';
  }

  // Paies
  static String mesPaies() {
    return '$baseUrl?do=mesPaies';
  }

  // Gestion des prêts
  static String listDemandesPrets() {
    return '$baseUrl?do=listDemandesPrets';
  }

  static String addDemandesPrets() {
    return '$baseUrl?do=addDemandesPrets';
  }

  static String listPrets() {
    return '$baseUrl?do=listPrets';
  }

  static String detailPret(String encryptedId) {
    return '$baseUrl?do=detailPret&encryptedId=$encryptedId';
  }

  // Absences
  static String mesAbsences() {
    return '$baseUrl?do=mesAbsences';
  }

  // Demandes de sorties
  static String demandesSorties() {
    return '$baseUrl?do=demandesSorties';
  }

  static String addDemandesSorties() {
    return '$baseUrl?do=demandesSorties';
  }

  // Missions
  static String missions() {
    return '$baseUrl?do=missions';
  }

  static String addMissions() {
    return '$baseUrl?do=addMissions';
  }

  static String missionsHierarchy() {
    return '$baseUrl?do=listMissionsHierarchy';
  }

  // Réclamations
  static String reclamations() {
    return '$baseUrl?do=reclamations';
  }

  static String addReclamations() {
    return '$baseUrl?do=addReclamations';
  }

  // Congés Hiérarchies
  static String listCongesHierarchy() {
    return '$baseUrl?do=listCongesHierarchy';
  }

  static String saveCongesHierarchy() {
    return '$baseUrl?do=saveCongesHierarchy';
  }

  static String saveRejetCongeHierarchy() {
    return '$baseUrl?do=saveRejetCongeHierarchy';
  }

  // Demandes sorties Hiérarchies
  static String demandesSortiesHierarchy() {
    return '$baseUrl?do=demandesSortiesHierarchy';
  }

  static String validerDemandesSortiesHierarchy() {
    return '$baseUrl?do=validerDemandesSortiesHierarchy';
  }

  static String rejeterDemandesSortiesHierarchy() {
    return '$baseUrl?do=rejeterDemandesSortiesHierarchy';
  }

  // Edition fiche de paie
  static String fichePaie() {
    return '$baseUrl?do=fichePaie';
  }

  // Missions Hiérarchies
  static String addMissionsHierarchy() {
    return '$baseUrl?do=addMissionsHierarchy';
  }

  static String deleteMissionsHierarchy(String encryptedId) {
    return '$baseUrl?do=deleteMissionsHierarchy&encryptedId=$encryptedId';
  }

  static String listMissionsDetails(String encryptedId) {
    return '$baseUrl?do=listMissionsDetails&encryptedId=$encryptedId';
  }

  static String saveMissionsDetails() {
    return '$baseUrl?do=saveMissionsDetails';
  }

  static String deleteMissionsDetails(String encryptedId) {
    return '$baseUrl?do=deleteMissionsDetails&encryptedId=$encryptedId';
  }

  // Situation de paie
  static String getOrganismesUser() {
    return '$baseUrl?do=getOrganismesUser';
  }

  static String getStatisticsPaie(String encryptedId) {
    return '$baseUrl?do=getStatisticsPaie&encryptedId=$encryptedId';
  }

  static String validerPaie(String encryptedId) {
    return '$baseUrl?do=validerPaie&encryptedId=$encryptedId';
  }

  // Gestion de plannings
  static String getTypesPlannings() {
    return '$baseUrl?do=getTypesPlannings';
  }

  static String addPlannings() {
    return '$baseUrl?do=addPlannings';
  }

  static String listPlannings() {
    return '$baseUrl?do=listPlannings';
  }

  static String executerPlannings() {
    return '$baseUrl?do=executerPlannings';
  }

  static String annulerPlannings() {
    return '$baseUrl?do=annulerPlannings';
  }

  static String reporterPlannings() {
    return '$baseUrl?do=reporterPlannings';
  }
}
