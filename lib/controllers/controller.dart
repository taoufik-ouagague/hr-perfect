import 'dart:ui';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_perfect/services/api_service.dart';

class HRController extends GetxController {
  final Logger _logger = Logger();
  
  // Loading states
  var isLoading = false.obs;
  var isLoadingConges = false.obs;
  var isLoadingPaies = false.obs;
  var isLoadingFormations = false.obs;
  
  // User session data
  var userToken = ''.obs;
  var userId = ''.obs;
  var isAuthenticated = false.obs;
  
  // User profile data
  var ville = ''.obs;
  var departement = ''.obs;
  var matricule = ''.obs;
  var numCnss = ''.obs;
  var categorie = ''.obs;
  var dateNaissance = ''.obs;
  var telephoneMobile = ''.obs;
  var nom = ''.obs;
  var prenom = ''.obs;
  var sexe = ''.obs;
  
  // Data observables
  var conges = <dynamic>[].obs;
  var personnesACharges = <dynamic>[].obs;
  var notifications = <dynamic>[].obs;
  var avantagesNatures = <dynamic>[].obs;
  var sanctions = <dynamic>[].obs;
  var formations = <dynamic>[].obs;
  var diplomes = <dynamic>[].obs;
  var experiences = <dynamic>[].obs;
  var transportsChevaux = <dynamic>[].obs;
  var moyensTransports = <dynamic>[].obs;
  var jourOuvrable = <dynamic>[].obs;
  var organismesRetraites = <dynamic>[].obs;
  var organismesMutuelles = <dynamic>[].obs;
  var modesPaies = <dynamic>[].obs;
  var carrieres = <dynamic>[].obs;
  var typesAttestations = <dynamic>[].obs;
  var paies = <dynamic>[].obs;
  var demandesPrets = <dynamic>[].obs;
  var prets = <dynamic>[].obs;
  var absences = <dynamic>[].obs;
  var demandesSorties = <dynamic>[].obs;
  var missions = <dynamic>[].obs;
  var missionsHierarchy = <dynamic>[].obs;
  var reclamations = <dynamic>[].obs;
  var congesHierarchy = <dynamic>[].obs;
  var demandesSortiesHierarchy = <dynamic>[].obs;
  var organismesUser = <dynamic>[].obs;
  var typesPlannings = <dynamic>[].obs;
  var plannings = <dynamic>[].obs;

  // Helper method for API calls with improved error handling
  Future<dynamic> _makeRequest(
    String url, {
    Map<String, dynamic>? body,
    String method = 'POST',
    bool showErrorSnackbar = true,
  }) async {
    try {
      _logger.i('🌐 Making $method request to: $url');
      if (body != null) {
        _logger.d('📦 Request body: $body');
      }

      final headers = {
        'Content-Type': 'application/json',
        if (userToken.value.isNotEmpty) 'token': userToken.value,
      };

      http.Response response;
      if (method == 'POST') {
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout - Server took too long to respond');
          },
        );
      } else {
        response = await http.get(
          Uri.parse(url), 
          headers: headers,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout - Server took too long to respond');
          },
        );
      }

      _logger.i('📊 Response status: ${response.statusCode}');
      _logger.d('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          _logger.e('❌ JSON decode error', error: e);
          throw Exception('Invalid response format from server');
        }
      } else {
        // Try to parse error message from response
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['MSG'] != null) {
            errorMessage = errorData['MSG'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          errorMessage = response.body;
        }
        
        if (response.statusCode == 400) {
          throw Exception('Bad Request: $errorMessage');
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: $errorMessage');
        } else if (response.statusCode == 404) {
          throw Exception('API endpoint not found');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error (${response.statusCode})');
        } else {
          throw Exception(errorMessage);
        }
      }
    } on http.ClientException catch (e) {
      _logger.e('❌ Network error', error: e);
      throw Exception('Network error - Check your internet connection');
    } catch (e) {
      _logger.e('❌ Request error', error: e);
      if (showErrorSnackbar) {
        Get.snackbar(
          'Erreur',
          'Une erreur s\'est produite: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
      rethrow;
    }
  }

  // ==================== AUTHENTIFICATION ====================
  Future<bool> authenticate(String username, String password) async {
    try {
      _logger.i('🔐 Starting authentication for user: $username');
      isLoading.value = true;
      
      final apiUrl = ApiService.authentificationMobile();
      _logger.d('🔗 API URL: $apiUrl');
      
      // Try both possible parameter names for compatibility
      final data = await _makeRequest(
        apiUrl,
        body: {
          'login': username,
          'password': password,  // Try 'password' first
          'pwd': password,       // Fallback to 'pwd'
        },
        showErrorSnackbar: false,
      );
      
      _logger.i('✅ Authentication response received');
      _logger.d('📄 Response data keys: ${data.keys}');
      
      // Check if authentication was successful
      final matriculeValue = data['matricule']?.toString() ?? '';
      
      if (matriculeValue.isEmpty) {
        _logger.e('❌ No matricule found in response - Invalid credentials');
        throw Exception('Invalid credentials');
      }
      
      // Store all user data from the response
      userId.value = matriculeValue;
      userToken.value = data['idUtilisateur']?.toString() ?? '';
      matricule.value = matriculeValue;
      ville.value = data['ville']?.toString() ?? '';
      categorie.value = data['categorie']?.toString() ?? '';
      departement.value = data['departement']?.toString() ?? '';
      numCnss.value = data['numCnss']?.toString() ?? '';
      dateNaissance.value = data['dateNaissance']?.toString() ?? '';
      telephoneMobile.value = data['telephoneMobile']?.toString() ?? '';
      nom.value = data['nom']?.toString() ?? '';
      prenom.value = data['prenom']?.toString() ?? '';
      sexe.value = data['sexe']?.toString() ?? '';
      
      isAuthenticated.value = true;
      
      // ✅ CRITICAL FIX: Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', userToken.value);
      await prefs.setString('userId', userId.value);
      await prefs.setString('matricule', matricule.value);
      await prefs.setString('nom', nom.value);
      await prefs.setString('prenom', prenom.value);
      
      _logger.i('✅ Authentication successful!');
      _logger.i('   User: ${nom.value} ${prenom.value}');
      _logger.i('   Matricule: ${matricule.value}');
      _logger.i('   Departement: ${departement.value}');
      _logger.i('   Token saved to SharedPreferences: ${userToken.value}');
      
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Authentication failed: $e', error: e, stackTrace: stackTrace);
      
      String errorMessage = 'Échec de l\'authentification';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Le serveur ne répond pas';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Erreur réseau - Vérifiez votre connexion';
      } else if (e.toString().contains('Invalid credentials') || 
                 e.toString().contains('401') ||
                 e.toString().contains('Unauthorized')) {
        errorMessage = 'Identifiant ou mot de passe invalide';
      } else if (e.toString().contains('404')) {
        errorMessage = 'API non trouvée';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Erreur serveur';
      }
      
      Get.snackbar(
        'Erreur', 
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336).withValues(alpha: 0.1),
        colorText: const Color(0xFFC62828),
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    _logger.i('🚪 Logging out user');
    userToken.value = '';
    userId.value = '';
    matricule.value = '';
    nom.value = '';
    prenom.value = '';
    ville.value = '';
    departement.value = '';
    categorie.value = '';
    numCnss.value = '';
    dateNaissance.value = '';
    telephoneMobile.value = '';
    sexe.value = '';
    isAuthenticated.value = false;
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('matricule');
    await prefs.remove('nom');
    await prefs.remove('prenom');
    
    // Clear all data
    conges.clear();
    notifications.clear();
    paies.clear();
    absences.clear();
    personnesACharges.clear();
    formations.clear();
    diplomes.clear();
    experiences.clear();
    missions.clear();
    reclamations.clear();
  }

  // ==================== CONGES ====================
  Future<void> fetchConges() async {
    try {
      isLoadingConges.value = true;
      final data = await _makeRequest(ApiService.mesConges(), method: 'GET');
      
      // Handle different response formats
      if (data is List) {
        conges.value = data;
      } else if (data is Map && data['conges'] != null) {
        conges.value = data['conges'];
      } else {
        conges.value = [];
      }
      
      _logger.d('Fetched ${conges.length} congés');
    } catch (e) {
      _logger.e('Failed to fetch congés', error: e);
      conges.value = [];
    } finally {
      isLoadingConges.value = false;
    }
  }

  Future<bool> addConge(Map<String, dynamic> congeData) async {
    try {
      isLoading.value = true;
      await _makeRequest(ApiService.addConges(), body: congeData);
      _logger.i('Congé added successfully');
      Get.snackbar(
        'Succès', 
        'Congé ajouté avec succès', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        colorText: const Color(0xFF2E7D32),
      );
      await fetchConges();
      return true;
    } catch (e) {
      _logger.e('Failed to add congé', error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPersonnesACharges() async {
    try {
      isLoading.value = true;
      final data = await _makeRequest(ApiService.mesPersonnesACharges(), method: 'GET');
      
      if (data is List) {
        personnesACharges.value = data;
      } else if (data is Map && data['personnes'] != null) {
        personnesACharges.value = data['personnes'];
      } else {
        personnesACharges.value = [];
      }
      
      _logger.d('Fetched ${personnesACharges.length} personnes à charges');
    } catch (e) {
      _logger.e('Failed to fetch personnes à charges', error: e);
      personnesACharges.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final data = await _makeRequest(ApiService.mesNotifications(), method: 'GET');
      
      if (data is List) {
        notifications.value = data;
      } else if (data is Map && data['notifications'] != null) {
        notifications.value = data['notifications'];
      } else {
        notifications.value = [];
      }
      
      _logger.d('Fetched ${notifications.length} notifications');
    } catch (e) {
      _logger.e('Failed to fetch notifications', error: e);
      notifications.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPaies() async {
    try {
      isLoadingPaies.value = true;
      final data = await _makeRequest(ApiService.mesPaies(), method: 'GET');
      
      if (data is List) {
        paies.value = data;
      } else if (data is Map && data['paies'] != null) {
        paies.value = data['paies'];
      } else {
        paies.value = [];
      }
      
      _logger.d('Fetched ${paies.length} paies');
    } catch (e) {
      _logger.e('Failed to fetch paies', error: e);
      paies.value = [];
    } finally {
      isLoadingPaies.value = false;
    }
  }

  Future<void> fetchAbsences() async {
    try {
      isLoading.value = true;
      final data = await _makeRequest(ApiService.mesAbsences(), method: 'GET');
      
      if (data is List) {
        absences.value = data;
      } else if (data is Map && data['absences'] != null) {
        absences.value = data['absences'];
      } else {
        absences.value = [];
      }
      
      _logger.d('Fetched ${absences.length} absences');
    } catch (e) {
      _logger.e('Failed to fetch absences', error: e);
      absences.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDashboardData() async {
    _logger.i('Loading dashboard data');
    try {
      // Parallel loading for better performance
      await Future.wait([
        fetchConges(),
        fetchNotifications(),
        fetchPaies(),
        fetchAbsences(),
      ], eagerError: false); // Continue even if one fails
      
      _logger.i('Dashboard data loaded successfully');
    } catch (e) {
      _logger.e('Failed to load dashboard data', error: e);
    }
  }

  @override
  void onClose() {
    _logger.i('HRController disposing');
    super.onClose();
  }
}