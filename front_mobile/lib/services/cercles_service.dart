import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Service pour gérer les cercles (tontines)
/// 
/// Gère :
/// - Création de cercles
/// - Récupération de la liste des cercles de l'utilisateur
/// - Récupération des détails d'un cercle
/// - Consultation du catalogue des cercles ouverts
/// - Adhésion à un cercle
/// - Invitation de membres
/// - Gestion des échanges de places
/// - Accès au registre du cercle
class CerclesService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  CerclesService(this._apiClient);

  /// Récupère le barème des frais (avant création)
  Future<Map<String, dynamic>> getBareme({
    required int nombreMembres,
    required int montant,
  }) async {
    try {
      _logger.i('Récupération barème: $nombreMembres membres, $montant francs');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.pathCercles}/bareme',
        queryParameters: {
          'nombreMembres': nombreMembres,
          'montant': montant,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Barème récupéré');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du barème: $e');
      rethrow;
    }
  }

  /// Crée un nouveau cercle
  /// 
  /// Les paramètres du cercle sont dans le règlement
  Future<Cercle> createCercle({
    required String nom,
    required String? description,
    required int montant,
    required String frequence,
    required int nombreMembres,
    required bool isPrivate,
    required String signature, // Signature du règlement
    int? penaliteRetard,
    int? delaiGraceJours,
    List<String>? ordreFixe,
    int? scoreMinimum,
  }) async {
    try {
      _logger.i('Création cercle: $nom');

      final reglement = {
        'montant': montant,
        'frequence': frequence,
        'nombreMembres': nombreMembres,
        'ouvert': !isPrivate,
        if (penaliteRetard != null) 'penaliteRetard': penaliteRetard,
        if (delaiGraceJours != null) 'delaiGraceJours': delaiGraceJours,
        if (ordreFixe != null) 'ordreFixe': ordreFixe,
        if (scoreMinimum != null) 'scoreMinimum': scoreMinimum,
      };

      final request = {
        'nom': nom,
        if (description != null) 'description': description,
        'reglement': reglement,
        'signature': signature, // À signer par le créateur
        'placeSouhaitee': 1, // Première place par défaut
      };

      final response = await _apiClient.post<Cercle>(
        ApiConfig.pathCercles,
        data: request,
        fromJson: (json) => Cercle.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Cercle créé: ${response.id}');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la création du cercle: $e');
      rethrow;
    }
  }

  /// Récupère la liste des cercles de l'utilisateur
  Future<List<ResumeCercle>> getMesCercles() async {
    try {
      _logger.i('Récupération des cercles de l\'utilisateur');

      final response = await _apiClient.get<List<ResumeCercle>>(
        ApiConfig.pathCercles,
        fromJson: (json) {
          final list = json as List;
          return list
              .map((item) =>
                  ResumeCercle.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      _logger.i('${response.length} cercles récupérés');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des cercles: $e');
      rethrow;
    }
  }

  /// Récupère le catalogue des cercles ouverts
  /// 
  /// Permet de découvrir et rejoindre des cercles existants
  Future<List<Cercle>> getCatalogue({
    int? montantMin,
    int? montantMax,
    String? frequence,
    int? nombreMembreMax,
  }) async {
    try {
      _logger.i('Récupération du catalogue des cercles');

      final queryParams = <String, dynamic>{
        if (montantMin != null) 'montantMin': montantMin,
        if (montantMax != null) 'montantMax': montantMax,
        if (frequence != null) 'frequence': frequence,
        if (nombreMembreMax != null) 'nombreMembreMax': nombreMembreMax,
      };

      final response = await _apiClient.get<List<Cercle>>(
        '${ApiConfig.pathCercles}/catalogue',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final list = json as List;
          return list
              .map((item) => Cercle.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      _logger.i('${response.length} cercles trouvés');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du catalogue: $e');
      rethrow;
    }
  }

  /// Récupère les détails d'un cercle
  Future<Cercle> getCercle(String cercleId) async {
    try {
      _logger.i('Récupération cercle: $cercleId');

      final response = await _apiClient.get<Cercle>(
        '${ApiConfig.pathCercles}/$cercleId',
        fromJson: (json) => Cercle.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Cercle récupéré: ${response.nom}');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du cercle: $e');
      rethrow;
    }
  }

  /// Adhère à un cercle
  /// 
  /// Place souhaitée et signature de l'engagement sont requis
  Future<Cercle> adhererAuCercle({
    required String cercleId,
    required int placeSouhaitee,
    required String signature, // Signature de l'engagement
  }) async {
    try {
      _logger.i('Adhésion au cercle: $cercleId');

      final request = {
        'placeSouhaitee': placeSouhaitee,
        'signature': signature,
      };

      final response = await _apiClient.post<Cercle>(
        '${ApiConfig.pathCercles}/$cercleId/adhesions',
        data: request,
        fromJson: (json) => Cercle.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Adhésion réussie au cercle: $cercleId');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de l\'adhésion: $e');
      rethrow;
    }
  }

  /// Invite un nouveau membre par SMS
  Future<Map<String, dynamic>> inviterMembre({
    required String cercleId,
    required String numeroTelephone,
  }) async {
    try {
      _logger.i('Invitation de $numeroTelephone au cercle $cercleId');

      final request = {
        'numero': numeroTelephone,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathCercles}/$cercleId/invitations',
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Invitation envoyée');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de l\'invitation: $e');
      rethrow;
    }
  }

  /// Quitte un cercle avant d'avoir reçu
  Future<Map<String, dynamic>> quitterCercle(String cercleId) async {
    try {
      _logger.i('Départ du cercle: $cercleId');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathCercles}/$cercleId/depart',
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Départ confirmé');
      return response;
    } catch (e) {
      _logger.e('Erreur lors du départ: $e');
      rethrow;
    }
  }

  /// Récupère le registre du cercle (transactions, intégrité)
  Future<Map<String, dynamic>> getRegistre(String cercleId) async {
    try {
      _logger.i('Récupération registre: $cercleId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.pathCercles}/$cercleId/registre',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Registre récupéré');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du registre: $e');
      rethrow;
    }
  }

  /// Propose un échange de place avec un autre membre
  Future<Map<String, dynamic>> proposerEchange({
    required String cercleId,
    required String avecMembreId,
    required String signature, // Signature de la proposition
  }) async {
    try {
      _logger.i('Proposition d\'échange au cercle: $cercleId');

      final request = {
        'avecMembreId': avecMembreId,
        'signature': signature,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathCercles}/$cercleId/echanges',
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Échange proposé');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la proposition d\'échange: $e');
      rethrow;
    }
  }

  /// Récupère les échanges de place en cours du cercle
  Future<List<Map<String, dynamic>>> getEchanges(String cercleId) async {
    try {
      _logger.i('Récupération échanges: $cercleId');

      final response = await _apiClient.get<List<Map<String, dynamic>>>(
        '${ApiConfig.pathCercles}/$cercleId/echanges',
        fromJson: (json) {
          final list = json as List;
          return list.map((item) => item as Map<String, dynamic>).toList();
        },
      );

      _logger.i('${response.length} échanges trouvés');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des échanges: $e');
      rethrow;
    }
  }

  /// Accepte un échange de place
  Future<void> accepterEchange({
    required String cercleId,
    required String echangeId,
    required String signature, // Signature d'acceptation
  }) async {
    try {
      _logger.i('Acceptation échange: $echangeId');

      final request = {
        'signature': signature,
      };

      await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathCercles}/$cercleId/echanges/$echangeId/acceptation',
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Échange accepté');
    } catch (e) {
      _logger.e('Erreur lors de l\'acceptation: $e');
      rethrow;
    }
  }

  /// Refuse un échange de place
  Future<void> refuserEchange({
    required String cercleId,
    required String echangeId,
  }) async {
    try {
      _logger.i('Refus échange: $echangeId');

      await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathCercles}/$cercleId/echanges/$echangeId/refus',
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Échange refusé');
    } catch (e) {
      _logger.e('Erreur lors du refus: $e');
      rethrow;
    }
  }
}
