import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_perfect/services/api_service.dart';

class CongeController extends GetxController {
  final Logger _logger = Logger();
  
  // Loading states
  var isLoading = false.obs;
  var isLoadingConges = false.obs;
  
  // Data observables
  var conges = <dynamic>[].obs;
  
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

  // Decode response body
  String _decodeBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } catch (_) {
      return response.body;
    }
  }

  // Extract MSG from response
  String? _extractMsg(dynamic decoded) {
    try {
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map && first['MSG'] != null) {
          return first['MSG'].toString();
        }
      }
      if (decoded is Map && decoded['MSG'] != null) {
        return decoded['MSG'].toString();
      }
    } catch (_) {}
    return null;
  }

  // Check if message looks like an error
  bool _looksLikeErrorMsg(String msg) {
    final m = msg.toLowerCase();
    return msg.contains('!!') ||
        m.contains('erreur') ||
        m.contains('échec') ||
        m.contains('echec') ||
        m.contains('impossible') ||
        m.contains('à cheval') ||
        m.contains('a cheval');
  }

  // ==================== FETCH CONGES ====================
  Future<void> fetchConges() async {
    try {
      isLoadingConges.value = true;
      final token = await _getToken();
      
      if (token == null) {
        _logger.e('Token manquant');
        conges.value = [];
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.mesConges()),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is List) {
          conges.value = data;
        } else if (data is Map && data['conges'] != null) {
          conges.value = data['conges'];
        } else {
          conges.value = [];
        }
        
        _logger.i('✅ Fetched ${conges.length} congés');
      } else {
        _logger.e('Failed to fetch congés: ${response.statusCode}');
        conges.value = [];
      }
    } catch (e) {
      _logger.e('Error fetching congés', error: e);
      conges.value = [];
    } finally {
      isLoadingConges.value = false;
    }
  }

  // ==================== ADD CONGE ====================
  Future<Map<String, dynamic>> addConge({
    required String libelle,
    required DateTime dateDebut,
    required DateTime dateFin,
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
        'dateDebut': _formatDate(dateDebut),
        'dateFin': _formatDate(dateFin),
        'ttjourneDebut': 'tout',
        'ttjourneFin': 'tout',
      };

      final url = ApiService.addConges();
      _logger.i('POST => $url');
      _logger.i('Body => ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode(requestBody),
      );

      final body = _decodeBody(response);
      _logger.i('Status => ${response.statusCode}');
      _logger.i('Response => $body');

      dynamic decoded;
      try {
        decoded = body.isEmpty ? null : jsonDecode(body);
      } catch (_) {
        decoded = null;
      }

      final msg = decoded != null ? _extractMsg(decoded) : null;

      if (msg != null && msg.trim().isNotEmpty) {
        final isOk = response.statusCode == 200 && !_looksLikeErrorMsg(msg.trim());
        return {
          'success': isOk,
          'message': msg.trim()
        };
      }

      if (response.statusCode == 200) {
        // Refresh the conges list
        await fetchConges();
        return {
          'success': true,
          'message': 'Demande soumise avec succès'
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Échec de l\'authentification. Veuillez vous reconnecter.'
        };
      }

      if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Requête invalide. Vérifiez les champs saisis.'
        };
      }

      if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Erreur du serveur. Veuillez réessayer plus tard.'
        };
      }

      return {
        'success': false,
        'message': 'La demande a échoué (statut: ${response.statusCode})'
      };
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout du congé: $e');

      final errorString = e.toString();
      if (errorString.contains('SocketException') || 
          errorString.contains('HandshakeException')) {
        return {
          'success': false,
          'message': 'Erreur réseau. Vérifiez votre connexion Internet.'
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
    _logger.i('CongeController disposing');
    super.onClose();
  }
}