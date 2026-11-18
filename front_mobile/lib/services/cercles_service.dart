import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';
import 'crypto_service.dart';

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

  /// Barème des frais par place (GET /cercles/bareme) : il va TEL QUEL dans le règlement.
  Future<List<FraisPlace>> getBareme({
    required int nombreMembres,
    required int montant,
  }) async {
    return _apiClient.get<List<FraisPlace>>(
      '${ApiConfig.pathCercles}/bareme',
      queryParameters: {'nombreMembres': nombreMembres, 'montant': montant},
      fromJson: (json) => (json as List)
          .map((e) => FraisPlace.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Crée un cercle : l'organisateur SIGNE le règlement, qui ne se modifie plus ensuite.
  ///
  /// Message signé : {objet: "reglement", organisateurId, reglement, placeSouhaitee}.
  Future<Cercle> createCercle({
    required int montant,
    required String frequence, // hebdomadaire, mensuelle, jours
    int? periodeJours,
    required int nombreMembres,
    required bool ouvert,
    required DateTime datePremierTour,
    required int penaliteRetard,
    required int delaiGraceJours,
    int? scoreMinimum,
    int? placeSouhaitee,
  }) async {
    final cle = _apiClient.cryptoService;
    final organisateurId = _apiClient.membreId;
    if (cle == null || organisateurId == null) {
      throw ApiException(message: 'Connecte-toi pour créer une tontine');
    }
    final bareme = await getBareme(nombreMembres: nombreMembres, montant: montant);
    final reglement = <String, dynamic>{
      'montant': montant,
      'frequence': frequence,
      if (frequence == 'jours') 'periodeJours': periodeJours,
      'nombreMembres': nombreMembres,
      'penaliteRetard': penaliteRetard,
      'delaiGraceJours': delaiGraceJours,
      'ouvert': ouvert,
      'datePremierTour': datePremierTour.toUtc().toIso8601String(),
      'bareme': bareme.map((b) => b.toJson()).toList(),
      if (scoreMinimum != null) 'scoreMinimum': scoreMinimum,
    };
    // Par défaut la dernière place : toujours permise, quel que soit le score.
    final place = placeSouhaitee ?? nombreMembres;
    final signature = cle.signMessage(CryptoService.canonique({
      'objet': 'reglement',
      'organisateurId': organisateurId,
      'reglement': reglement,
      'placeSouhaitee': place,
    }));
    return _apiClient.post<Cercle>(
      ApiConfig.pathCercles,
      data: {'reglement': reglement, 'placeSouhaitee': place, 'signature': signature},
      fromJson: (json) => Cercle.fromJson(json as Map<String, dynamic>),
    );
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
        if (nombreMembreMax != null) 'nombreMembresMax': nombreMembreMax,
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

  /// Rejoint un cercle : le membre SIGNE son engagement, qui reprend l'empreinte du règlement.
  ///
  /// Message signé : {objet: "engagement", cercleId, empreinteReglement, membreId, placeSouhaitee}.
  Future<Cercle> adhererAuCercle({
    required Cercle cercle,
    required int placeSouhaitee,
  }) async {
    final cle = _apiClient.cryptoService;
    final membreId = _apiClient.membreId;
    if (cle == null || membreId == null) {
      throw ApiException(message: 'Connecte-toi pour rejoindre une tontine');
    }
    // Le catalogue ne donne pas l'empreinte du règlement : on relit le cercle.
    if (cercle.empreinteReglement == null) cercle = await getCercle(cercle.id);
    final signature = cle.signMessage(CryptoService.canonique({
      'objet': 'engagement',
      'cercleId': cercle.id,
      'empreinteReglement': cercle.empreinteReglement,
      'membreId': membreId,
      'placeSouhaitee': placeSouhaitee,
    }));
    return _apiClient.post<Cercle>(
      '${ApiConfig.pathCercles}/${cercle.id}/adhesions',
      data: {'placeSouhaitee': placeSouhaitee, 'signature': signature},
      fromJson: (json) => Cercle.fromJson(json as Map<String, dynamic>),
    );
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

  // --- Démonstration (refusé en production par le serveur) ---

  /// Complète le cercle avec des membres fictifs, par les vrais services.
  Future<Map<String, dynamic>> demoMembresFictifs(String cercleId) => _apiClient.post<Map<String, dynamic>>(
        '/demonstration/cercles/$cercleId/membres-fictifs',
        data: const {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

  /// Les membres fictifs paient le tour en cours et confirment ce que j'ai payé.
  Future<Map<String, dynamic>> demoSuite(String cercleId) => _apiClient.post<Map<String, dynamic>>(
        '/demonstration/cercles/$cercleId/suite',
        data: const {},
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
