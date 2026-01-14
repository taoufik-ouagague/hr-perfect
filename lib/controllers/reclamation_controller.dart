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

      _logger.i('Envoi de la requête à: ${ApiService.addReclamations()}');
      _logger.i('Corps de la requête: ${jsonEncode(requestBody)}');
      _logger.i('Token (20 premiers caractères): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      final response = await http.post(
        Uri.parse(ApiService.addReclamations()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode(requestBody),
      );

      _logger.i('Statut de la réponse: ${response.statusCode}');
      _logger.i('Corps de la réponse: ${response.body}');
      _logger.i('Longueur du corps de la réponse: ${response.body.length}');
      _logger.i('En-têtes de la réponse: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          if (response.body.isEmpty) {
            _logger.w('Le corps de la réponse est vide mais le statut est 200');
            // Refresh reclamations list
            await fetchReclamations();
            return {
              'success': true,
              'message': 'Réclamation soumise avec succès'
            };
          }

          final responseJson = jsonDecode(response.body);
          _logger.i('Réponse analysée: $responseJson');

          String message = 'Réclamation soumise avec succès';
          bool isSuccess = true;

          if (responseJson is Map) {
            final msg = responseJson['message'] as String?;
            final status = responseJson['status'] ?? responseJson['succes'];

            if (status == false || status == 'error') {
              isSuccess = false;
              message = msg ?? 'Erreur lors de la soumission';
            } else if (msg != null && msg.isNotEmpty) {
              message = msg;
            }
          }

          _logger.i('✅ Message backend: $message');
          
          // Refresh reclamations list if successful
          if (isSuccess) {
            await fetchReclamations();
          }
          
          return {
            'success': isSuccess,
            'message': message
          };
        } catch (e) {
          _logger.e('Erreur lors de l\'analyse de la réponse: $e');
          // Still consider it success if status was 200
          await fetchReclamations();
          return {
            'success': true,
            'message': 'Réclamation soumise avec succès'
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Échec de l\'authentification. Veuillez vous reconnecter.'
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Demande invalide. Veuillez vérifier les informations.'
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Erreur du serveur. Veuillez réessayer plus tard.'
        };
      } else {
        return {
          'success': false,
          'message': 'La soumission a échoué avec le statut: ${response.statusCode}. ${response.body}'
        };
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout de la réclamation: $e');
      
      final errorString = e.toString();
      if (errorString.contains('SocketException') || 
          errorString.contains('HandshakeException')) {
        return {
          'success': false,
          'message': 'Erreur réseau. Veuillez vérifier votre connexion Internet.'
        };
      }
      
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi de la requête: $e'
      };
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _logger.i('ReclamationController disposing');
    super.onClose();
  }
}