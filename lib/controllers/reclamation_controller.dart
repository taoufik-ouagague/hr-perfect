import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_perfect/services/api_service.dart';

class ReclamationController extends GetxController {
  final Logger _logger = Logger();
  
  // Loading states
  var isLoading = false.obs;
  
  // Data observables
  var reclamations = <dynamic>[].obs;
  
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

  // ==================== FETCH RECLAMATIONS ====================
  Future<void> fetchReclamations() async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      
      if (token == null) {
        _logger.e('Aucun jeton disponible');
        reclamations.value = [];
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.reclamations()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      _logger.i('Réponse des réclamations: ${response.statusCode}');
      _logger.d('Corps des réclamations: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          reclamations.value = data;
          _logger.i('✅ ${reclamations.length} réclamations chargées');
        } else if (data is Map && data['reclamations'] != null) {
          reclamations.value = data['reclamations'];
          _logger.i('✅ ${reclamations.length} réclamations chargées');
        } else {
          reclamations.value = [];
        }
      } else {
        _logger.e('Échec de la récupération des réclamations: ${response.statusCode}');
        reclamations.value = [];
      }
    } catch (e) {
      _logger.e('Erreur lors de la récupération des réclamations: $e');
      reclamations.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== ADD RECLAMATION ====================
  Future<Map<String, dynamic>> addReclamation({
    required String libelle,
    required DateTime dateReclamation,
    required DateTime dateTraitement,
    required String type,
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
        'libelle': libelle,
        'dateReclamation': _formatDate(dateReclamation),
        'dateTraitement': _formatDate(dateTraitement),
        'type': type,
      };

      _logger.i('📤 Envoi de la requête à: ${ApiService.addReclamations()}');
      _logger.i('📦 Corps de la requête: ${jsonEncode(requestBody)}');
      _logger.i('🔑 Token (20 premiers caractères): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      final response = await http.post(
        Uri.parse(ApiService.addReclamations()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode(requestBody),
      );

      _logger.i('📥 Statut de la réponse: ${response.statusCode}');
      _logger.i('📄 Corps de la réponse: ${response.body}');
      _logger.i('📏 Longueur du corps: ${response.body.length}');

      // ==================== HANDLE SUCCESS RESPONSES ====================
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          // Handle empty response body
          if (response.body.isEmpty) {
            _logger.w('⚠️ Le corps de la réponse est vide mais le statut est ${response.statusCode}');
            await fetchReclamations();
            return {
              'success': true,
              'message': 'Réclamation soumise avec succès'
            };
          }

          // Parse JSON response
          final responseJson = jsonDecode(response.body);
          _logger.i('✅ Réponse analysée: $responseJson');

          String message = 'Réclamation soumise avec succès';
          bool isSuccess = true;

          // Extract message from various response formats
          if (responseJson is List && responseJson.isNotEmpty) {
            // Handle array responses: [{"MSG": "..."}]
            final firstItem = responseJson[0];
            if (firstItem is Map) {
              final msg = firstItem['MSG'] as String? ?? 
                          firstItem['message'] as String? ?? 
                          firstItem['msg'] as String?;
              
              if (msg != null && msg.isNotEmpty) {
                message = msg;
                _logger.i('💬 Message backend (array): $message');
              }
              
              // Check status in array item
              final status = firstItem['status'] ?? 
                            firstItem['succes'] ?? 
                            firstItem['success'];
              
              if (status == false || status == 'error' || status == 'failed') {
                isSuccess = false;
                _logger.e('❌ Échec backend: $message');
              }
            }
          } else if (responseJson is Map) {
            // Handle object responses: {"message": "..."}
            final msg = responseJson['MSG'] as String? ??
                        responseJson['message'] as String? ?? 
                        responseJson['msg'] as String? ?? 
                        responseJson['description'] as String?;
            
            // Try to get status from different fields
            final status = responseJson['status'] ?? 
                          responseJson['succes'] ?? 
                          responseJson['success'];

            // Check if operation failed
            if (status == false || status == 'error' || status == 'failed') {
              isSuccess = false;
              message = msg ?? 'Erreur lors de la soumission';
              _logger.e('❌ Échec backend: $message');
            } else if (msg != null && msg.isNotEmpty) {
              message = msg;
              _logger.i('💬 Message backend: $message');
            }
          } else if (responseJson is String) {
            // Handle string responses
            message = responseJson;
            _logger.i('💬 Message texte backend: $message');
          }

          _logger.i('✅ Résultat final - Succès: $isSuccess, Message: $message');
          
          // Refresh reclamations list if successful
          if (isSuccess) {
            await fetchReclamations();
            _logger.i('🔄 Liste des réclamations rafraîchie');
          }
          
          return {
            'success': isSuccess,
            'message': message
          };
        } catch (e) {
          _logger.e('⚠️ Erreur lors de l\'analyse de la réponse: $e');
          // Still consider it success if status was 200/201
          await fetchReclamations();
          return {
            'success': true,
            'message': 'Réclamation soumise avec succès'
          };
        }
      } 
      
      // ==================== HANDLE ERROR RESPONSES ====================
      else if (response.statusCode == 401) {
        _logger.e('🔒 Erreur 401: Non autorisé');
        return {
          'success': false,
          'message': 'Échec de l\'authentification. Veuillez vous reconnecter.'
        };
      } else if (response.statusCode == 400) {
        _logger.e('⚠️ Erreur 400: Requête invalide');
        
        // Try to extract error message from response
        String errorMessage = 'Demande invalide. Veuillez vérifier les informations.';
        try {
          if (response.body.isNotEmpty) {
            final errorJson = jsonDecode(response.body);
            if (errorJson is Map && errorJson['message'] != null) {
              errorMessage = errorJson['message'];
            }
          }
        } catch (e) {
          _logger.w('Impossible d\'extraire le message d\'erreur: $e');
        }
        
        return {
          'success': false,
          'message': errorMessage
        };
      } else if (response.statusCode == 500) {
        _logger.e('💥 Erreur 500: Erreur serveur');
        return {
          'success': false,
          'message': 'Erreur du serveur. Veuillez réessayer plus tard.'
        };
      } else {
        _logger.e('❌ Erreur ${response.statusCode}: ${response.body}');
        
        // Try to extract error message
        String errorMessage = 'La soumission a échoué avec le statut: ${response.statusCode}';
        try {
          if (response.body.isNotEmpty) {
            final errorJson = jsonDecode(response.body);
            if (errorJson is Map && errorJson['message'] != null) {
              errorMessage = errorJson['message'];
            }
          }
        } catch (e) {
          // Keep default error message
        }
        
        return {
          'success': false,
          'message': errorMessage
        };
      }
    } catch (e) {
      _logger.e('💥 Erreur lors de l\'ajout de la réclamation: $e');
      
      final errorString = e.toString();
      
      // Handle network errors
      if (errorString.contains('SocketException') || 
          errorString.contains('HandshakeException')) {
        return {
          'success': false,
          'message': 'Erreur réseau. Veuillez vérifier votre connexion Internet.'
        };
      }
      
      // Handle timeout errors
      if (errorString.contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Délai d\'attente dépassé. Veuillez réessayer.'
        };
      }
      
      // Generic error
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi de la requête: $e'
      };
    } finally {
      isLoading.value = false;
      _logger.i('🏁 Opération terminée');
    }
  }

  @override
  void onClose() {
    _logger.i('🔌 ReclamationController disposing');
    super.onClose();
  }
}