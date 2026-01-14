import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_perfect/services/api_service.dart';

class AttestationController extends GetxController {
  final Logger _logger = Logger();
  
  // Loading states
  var isLoading = false.obs;
  var isLoadingTypes = false.obs;
  
  // Data observables
  var attestationTypes = <Map<String, dynamic>>[].obs;
  
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

  // Format date to dd/MM/yyyy
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // ==================== FETCH ATTESTATION TYPES ====================
  Future<void> fetchAttestationTypes() async {
    try {
      isLoadingTypes.value = true;
      final token = await _getToken();

      if (token == null) {
        _logger.e('Token manquant');
        attestationTypes.value = [];
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.getTypesAttestations()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      _logger.i('Types attestation response: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> data = jsonDecode(response.body);
        attestationTypes.value = data
            .map((item) => {
                  'libelle': item['libelle'],
                  'id': item['id']
                })
            .toList();
        
        _logger.i('✅ Loaded ${attestationTypes.length} attestation types');
      } else {
        _logger.e('Failed to load attestation types: ${response.statusCode}');
        attestationTypes.value = [];
      }
    } catch (e) {
      _logger.e('Error fetching attestation types: $e');
      attestationTypes.value = [];
    } finally {
      isLoadingTypes.value = false;
    }
  }

  // ==================== ADD ATTESTATION ====================
  Future<Map<String, dynamic>> addAttestation({
    required String typeId,
    required DateTime requestDate,
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

      final url = ApiService.addAttestations(int.parse(typeId));
      final requestBody = {
        'dateDebut': _formatDate(requestDate),
        'dateFin': _formatDate(requestDate),
      };

      _logger.i('Envoi de la requête vers: $url');
      _logger.i('Corps de la requête: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode(requestBody),
      );

      _logger.i('Statut de la réponse: ${response.statusCode}');
      _logger.i('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseJson = jsonDecode(response.body);
          
          String message = 'La demande a été effectuée avec succès';
          
          if (responseJson is List && responseJson.isNotEmpty) {
            message = responseJson[0]['MSG'] ?? message;
          } else if (responseJson is Map) {
            message = responseJson['MSG'] ?? 
                     responseJson['message'] ?? 
                     message;
          }
          
          return {
            'success': true,
            'message': message
          };
        } catch (e) {
          _logger.e('Erreur lors de l\'analyse de la réponse: $e');
          return {
            'success': true,
            'message': 'La demande a été effectuée avec succès'
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Échec de l\'authentification. Veuillez vous reconnecter.'
        };
      } else {
        return {
          'success': false,
          'message': 'La demande a échoué avec le statut: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'envoi de la requête: $e');
      
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
        'message': 'Erreur: $e'
      };
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Load attestation types when controller is initialized
    fetchAttestationTypes();
  }

  @override
  void onClose() {
    _logger.i('AttestationController disposing');
    super.onClose();
  }
}