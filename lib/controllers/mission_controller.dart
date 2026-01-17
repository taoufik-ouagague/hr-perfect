import 'dart:convert';
import 'package:get/get.dart';
import 'package:hr_perfect/models/mission_model.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_perfect/services/api_service.dart';

class MissionController extends GetxController {
  final Logger _logger = Logger();
  
  // Loading states
  var isLoading = false.obs;
  var isLoadingDropdowns = false.obs;
  
  // Data observables
  var moyensTransport = <String>[].obs;
  var nbCheveaux = <String>[].obs;
  var missions = <dynamic>[].obs;
  
  // Error states
  var dropdownError = Rx<String?>(null);
  
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

  // Helper for headers
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'token': token,
  };

  // ==================== FETCH MOYENS TRANSPORT ====================
  Future<void> fetchMoyensTransport() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Aucun jeton d\'authentification');
      }

      final response = await http.get(
        Uri.parse(ApiService.getMoyensTransports()),
        headers: _headers(token),
      );

      _logger.i('Moyens transport response: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          moyensTransport.value = data
              .map((item) => item['moyenTransport'] as String)
              .toList();
          _logger.i('✅ Loaded ${moyensTransport.length} moyens de transport');
        } else {
          throw Exception('Format de données invalide');
        }
      } else {
        throw Exception('Échec de la récupération (${response.statusCode})');
      }
    } catch (e) {
      _logger.e('Error fetching moyens transport: $e');
      rethrow;
    }
  }

  // ==================== FETCH NB CHEVEAUX ====================
  Future<void> fetchNbCheveaux() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Aucun jeton d\'authentification');
      }

      final response = await http.get(
        Uri.parse(ApiService.getTransportsChevaux()),
        headers: _headers(token),
      );

      _logger.i('Nb Cheveaux response: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          nbCheveaux.value = data
              .map((item) => item['transportCheveaux'] as String)
              .toList();
          _logger.i('✅ Loaded ${nbCheveaux.length} nb cheveaux options');
        } else {
          throw Exception('Format de données invalide');
        }
      } else {
        throw Exception('Échec de la récupération (${response.statusCode})');
      }
    } catch (e) {
      _logger.e('Error fetching nb cheveaux: $e');
      rethrow;
    }
  }

  // ==================== LOAD DROPDOWN DATA ====================
  Future<void> loadDropdownData() async {
    try {
      isLoadingDropdowns.value = true;
      dropdownError.value = null;

      await Future.wait([
        fetchMoyensTransport(),
        fetchNbCheveaux(),
      ]);

      if (moyensTransport.isEmpty || nbCheveaux.isEmpty) {
        dropdownError.value = 'Échec du chargement des options';
      }
    } catch (e) {
      _logger.e('Error loading dropdown data: $e');
      dropdownError.value = 'Erreur: $e';
    } finally {
      isLoadingDropdowns.value = false;
    }
  }

  // ==================== SUBMIT MISSION ====================
  Future<Map<String, dynamic>> submitMission(MissionFormData data) async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Impossible de s\'authentifier'
        };
      }

      final jsonData = data.toJson();
      final jsonBody = jsonEncode(jsonData);

      _logger.i('=== MISSION SUBMISSION DEBUG ===');
      _logger.i('URL: ${ApiService.addMissions()}');
      _logger.i('Headers: ${_headers(token)}');
      _logger.i('Body (formatted): ${JsonEncoder.withIndent('  ').convert(jsonData)}');
      _logger.i('Body (raw): $jsonBody');
      _logger.i('================================');

      final response = await http.post(
        Uri.parse(ApiService.addMissions()),
        headers: _headers(token),
        body: jsonBody,
      );

      _logger.i('=== RESPONSE DEBUG ===');
      _logger.i('Status code: ${response.statusCode}');
      _logger.i('Response headers: ${response.headers}');
      _logger.i('Response body: ${response.body}');
      _logger.i('=====================');

      if (response.statusCode == 200) {
        try {
          final responseJson = jsonDecode(response.body);
          _logger.i('Parsed response: $responseJson');

          String message = 'La demande a été effectuée avec succès';
          
          if (responseJson is List && responseJson.isNotEmpty) {
            message = responseJson[0]['MSG'] ?? 
                     responseJson[0]['msg'] ?? 
                     message;
          } else if (responseJson is Map) {
            message = responseJson['MSG'] ??
                     responseJson['msg'] ??
                     responseJson['message'] ??
                     message;
          }
          
          return {
            'success': true,
            'message': message
          };
        } catch (e) {
          _logger.e('Error parsing response: $e');
          return {
            'success': true,
            'message': 'Demande soumise (réponse: ${response.body})',
          };
        }
      } else {
        _logger.e('Non-200 status code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erreur ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      _logger.e('Exception during submission: $e');
      
      final errorString = e.toString();
      if (errorString.contains('SocketException') || 
          errorString.contains('HandshakeException')) {
        return {
          'success': false,
          'message': 'Erreur réseau: Impossible de se connecter au serveur'
        };
      }
      
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi: $e'
      };
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Load dropdown data when controller is initialized
    loadDropdownData();
  }

  @override
  void onClose() {
    _logger.i('MissionController disposing');
    super.onClose();
  }
}