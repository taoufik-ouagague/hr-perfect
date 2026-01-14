import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_perfect/services/api_service.dart';

class SortieController extends GetxController {
  final Logger _logger = Logger();
  
  // Loading states
  var isLoading = false.obs;
  
  // Data observables
  var sorties = <dynamic>[].obs;
  
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

  // Format time to HH:mm
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ==================== FETCH SORTIES ====================
  Future<void> fetchSorties() async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      
      if (token == null) {
        _logger.e('Aucun jeton disponible');
        sorties.value = [];
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.demandesSorties()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      _logger.i('Réponse des sorties: ${response.statusCode}');
      _logger.d('Corps des sorties: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          sorties.value = data;
          _logger.i('✅ ${sorties.length} sorties chargées');
        } else if (data is Map && data['sorties'] != null) {
          sorties.value = data['sorties'];
          _logger.i('✅ ${sorties.length} sorties chargées');
        } else {
          sorties.value = [];
        }
      } else {
        _logger.e('Échec de la récupération des sorties: ${response.statusCode}');
        sorties.value = [];
      }
    } catch (e) {
      _logger.e('Erreur lors de la récupération des sorties: $e');
      sorties.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== ADD SORTIE ====================
  Future<Map<String, dynamic>> addSortie({
    required String motif,
    required DateTime dateSortie,
    required TimeOfDay heureDebut,
    required TimeOfDay heureFin,
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
        'motif': motif,
        'dateSortie': _formatDate(dateSortie),
        'heureDebut': _formatTime(heureDebut),
        'heureFin': _formatTime(heureFin),
      };

      _logger.i('Envoi de la requête à: ${ApiService.addDemandesSorties()}');
      _logger.i('Corps de la requête: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(ApiService.addDemandesSorties()),
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
          final data = jsonDecode(response.body);
          
          String message = 'Sortie demandée avec succès';
          
          if (data is List && data.isNotEmpty) {
            message = data[0]['MSG'] ?? message;
          } else if (data is Map) {
            message = data['MSG'] ?? data['message'] ?? message;
          }

          _logger.i('✅ Message backend: $message');
          
          // Refresh sorties list
          await fetchSorties();
          
          return {
            'success': true,
            'message': message
          };
        } catch (e) {
          _logger.e('Erreur lors de l\'analyse de la réponse: $e');
          // Still consider it success if status was 200
          await fetchSorties();
          return {
            'success': true,
            'message': 'Sortie demandée avec succès'
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
          'message': 'Erreur ${response.statusCode}'
        };
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout de la sortie: $e');
      
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
        'message': 'Erreur: $e'
      };
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _logger.i('SortieController disposing');
    super.onClose();
  }
}