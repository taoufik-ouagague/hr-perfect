import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_perfect/services/api_service.dart';

class PretController extends GetxController {
  final Logger _logger = Logger();
  
  // Loading states
  var isLoading = false.obs;
  
  // Data observables
  var prets = <dynamic>[].obs;
  
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

  // Check if message looks like an error
  bool _looksLikeErrorMsg(String msg) {
    final m = msg.toLowerCase();
    return msg.contains('!!') ||
        m.contains('erreur') ||
        m.contains('échec') ||
        m.contains('echec') ||
        m.contains('impossible');
  }

  // ==================== FETCH PRETS ====================
  Future<void> fetchPrets() async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      
      if (token == null) {
        _logger.e('Aucun jeton disponible');
        prets.value = [];
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.listDemandesPrets()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      _logger.i('Réponse des prêts: ${response.statusCode}');
      _logger.d('Corps des prêts: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          prets.value = data;
          _logger.i('✅ ${prets.length} prêts chargés');
        } else if (data is Map && data['prets'] != null) {
          prets.value = data['prets'];
          _logger.i('✅ ${prets.length} prêts chargés');
        } else {
          prets.value = [];
        }
      } else {
        _logger.e('Échec de la récupération des prêts: ${response.statusCode}');
        prets.value = [];
      }
    } catch (e) {
      _logger.e('Erreur lors de la récupération des prêts: $e');
      prets.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== ADD PRET ====================
  Future<Map<String, dynamic>> addPret({
    required String motifPret,
    required DateTime datePret,
    required double montantPret,
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
        'motifPret': motifPret,
        'datePret': _formatDate(datePret),
        'montantPret': montantPret,
      };

      _logger.i('Envoi de la requête à: ${ApiService.addDemandesPrets()}');
      _logger.i('Corps de la requête: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(ApiService.addDemandesPrets()),
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
          if (response.body.isEmpty) {
            _logger.w('Le corps de la réponse est vide');
            return {
              'success': false,
              'message': 'Réponse vide du serveur'
            };
          }

          final responseJson = jsonDecode(response.body);
          _logger.i('Réponse analysée: $responseJson');

          String message = 'Demande de prêt soumise avec succès';
          bool isSuccess = true;

          if (responseJson is List && responseJson.isNotEmpty) {
            final firstElement = responseJson[0];
            final msg = firstElement['MSG'] as String?;
            
            if (msg != null && msg.isNotEmpty) {
              message = msg;
              isSuccess = !_looksLikeErrorMsg(msg);
            }
          } else if (responseJson is Map) {
            final msg = responseJson['MSG'] as String?;
            
            if (msg != null && msg.isNotEmpty) {
              message = msg;
              isSuccess = !_looksLikeErrorMsg(msg);
            }
          }

          _logger.i('✅ Message backend: $message');
          
          // Refresh prets list if successful
          if (isSuccess) {
            await fetchPrets();
          }
          
          return {
            'success': isSuccess,
            'message': message
          };
        } catch (e) {
          _logger.e('Erreur lors de l\'analyse de la réponse: $e');
          return {
            'success': false,
            'message': 'Erreur lors de l\'analyse de la réponse'
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
          'message': 'La demande a échoué avec le statut: ${response.statusCode}'
        };
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout du prêt: $e');
      
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
    _logger.i('PretController disposing');
    super.onClose();
  }
}