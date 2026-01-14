import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_perfect/services/api_service.dart';

class PlanningController extends GetxController {
  final Logger _logger = Logger();
  
  // Loading states
  var isLoading = false.obs;
  var isLoadingTypes = false.obs;
  
  // Data observables
  var typesVisites = <Map<String, dynamic>>[].obs;
  var plannings = <dynamic>[].obs;
  
  // Helper method to get token
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      _logger.i('Token récupéré: ${token != null ? "existe" : "null"}');
      return token;
    } catch (e) {
      _logger.e('Erreur token: $e');
      return null;
    }
  }

  // ==================== FETCH TYPES VISITES ====================
  Future<void> fetchTypesVisites() async {
    try {
      isLoadingTypes.value = true;
      final token = await _getToken();
      
      if (token == null) {
        _logger.e('Aucun jeton disponible');
        typesVisites.value = [];
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.getTypesPlannings()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      _logger.i('Réponse des types de visite: ${response.statusCode}');
      _logger.i('Corps des types de visite: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          typesVisites.value = data.cast<Map<String, dynamic>>();
          _logger.i('✅ ${typesVisites.length} types de visite chargés');
        } else {
          _logger.e('Format de données inattendu pour les types de visite');
          typesVisites.value = [];
        }
      } else {
        _logger.e('Échec de la récupération des types de visite: ${response.statusCode}');
        typesVisites.value = [];
      }
    } catch (e) {
      _logger.e('Erreur lors de la récupération des types de visite: $e');
      typesVisites.value = [];
    } finally {
      isLoadingTypes.value = false;
    }
  }

  // ==================== FETCH PLANNINGS ====================
  Future<void> fetchPlannings() async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      
      if (token == null) {
        _logger.e('Aucun jeton disponible');
        plannings.value = [];
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.listPlannings()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      _logger.i('Réponse des plannings: ${response.statusCode}');
      _logger.d('Corps des plannings: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          plannings.value = data;
          _logger.i('✅ ${plannings.length} plannings chargés');
        } else if (data is Map && data['plannings'] != null) {
          plannings.value = data['plannings'];
          _logger.i('✅ ${plannings.length} plannings chargés');
        } else {
          plannings.value = [];
        }
      } else {
        _logger.e('Échec de la récupération des plannings: ${response.statusCode}');
        plannings.value = [];
      }
    } catch (e) {
      _logger.e('Erreur lors de la récupération des plannings: $e');
      plannings.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== ADD PLANNING ====================
  Future<Map<String, dynamic>> addPlanning({
    required String idTypeVisite,
    required String client,
    required String objet,
    required String datePrevu,
  }) async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Impossible de s\'authentifier'
        };
      }

      final requestBody = {
        'idTypeVisite': idTypeVisite,
        'client': client,
        'objet': objet,
        'datePrevu': datePrevu,
      };

      _logger.i('Envoi planning vers: ${ApiService.addPlannings()}');
      _logger.i('Corps: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(ApiService.addPlannings()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode(requestBody),
      );

      _logger.i('Add planning response: ${response.statusCode}');
      _logger.i('Add planning body: ${response.body}');

      if (response.statusCode == 200) {
        String message = 'Planning ajouté avec succès';
        
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map && responseData['MSG'] != null) {
            message = responseData['MSG'];
          } else if (responseData is List &&
              responseData.isNotEmpty &&
              responseData[0]['MSG'] != null) {
            message = responseData[0]['MSG'];
          }
        } catch (e) {
          _logger.e('Erreur lors de l\'extraction du message: $e');
        }

        _logger.i('✅ Message backend: $message');
        
        // Refresh plannings list
        await fetchPlannings();
        
        return {
          'success': true,
          'message': message
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur: ${response.statusCode}'
        };
      }
    } catch (e) {
      _logger.e('Error adding planning: $e');
      
      final errorString = e.toString();
      if (errorString.contains('SocketException') || 
          errorString.contains('HandshakeException')) {
        return {
          'success': false,
          'message': 'Erreur de connexion: Vérifiez votre réseau'
        };
      }
      
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Load types visites when controller is initialized
    fetchTypesVisites();
  }

  @override
  void onClose() {
    _logger.i('PlanningController disposing');
    super.onClose();
  }
}