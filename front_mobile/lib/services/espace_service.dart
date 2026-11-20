import 'api_client.dart';
import 'crypto_service.dart';

/// Les routes du serveur qui n'avaient pas encore d'écran : compte, sécurité,
/// parrainages, sommes dues, et la vie d'une tontine (registre, échanges, départ,
/// assistant, preuve, Mobile Money simulé). Réponses relevées sur un vrai serveur.
class EspaceService {
  EspaceService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> _get(String chemin) =>
      _api.get<Map<String, dynamic>>(chemin, fromJson: (j) => j as Map<String, dynamic>);

  Future<List<Map<String, dynamic>>> _liste(String chemin) => _api.get<List<Map<String, dynamic>>>(
        chemin,
        fromJson: (j) => (j as List).cast<Map<String, dynamic>>(),
      );

  Future<Map<String, dynamic>> _post(String chemin, [Map<String, dynamic> corps = const {}]) =>
      _api.post<Map<String, dynamic>>(chemin, data: corps, fromJson: (j) => j as Map<String, dynamic>);

  CryptoService get _cle {
    final c = _api.cryptoService;
    if (c == null) throw ApiException(message: 'Non connecté');
    return c;
  }

  String get moi => _api.membreId ?? '';

  // ---------------------------------------------------------------- Compte

  /// Code secret de récupération (4 à 8 chiffres).
  Future<void> definirCodeSecret(String code) => _post('/comptes/moi/code-secret', {'code': code});

  /// Contact de confiance : null si aucun n'est désigné (le serveur répond 404).
  Future<Map<String, dynamic>?> contactDeConfiance() async {
    try {
      return await _get('/comptes/moi/contact-de-confiance');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> designerContact({required String nom, required String numero}) =>
      _post('/comptes/moi/contact-de-confiance', {'nom': nom, 'numero': numero});

  /// Le code que le contact a reçu par SMS et qu'il transmet.
  Future<Map<String, dynamic>> accordDuContact(String code) =>
      _post('/comptes/moi/contact-de-confiance/accord', {'code': code});

  /// Texte et version du consentement en vigueur.
  Future<Map<String, dynamic>> consentementIdentite() => _get('/comptes/moi/identite/consentement');

  /// Mon dossier d'identité : null si rien n'est déposé.
  Future<Map<String, dynamic>?> monIdentite() async {
    try {
      return await _get('/comptes/moi/identite');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Dépôt recto, verso, selfie (JPEG ou PNG en base64, 2 Mo au plus chacun).
  Future<Map<String, dynamic>> deposerIdentite({
    required String typePiece, // cni ou passeport
    required String versionConsentement,
    required String recto,
    required String verso,
    required String selfie,
  }) =>
      _post('/comptes/moi/identite', {
        'typePiece': typePiece,
        'consentement': true,
        'versionConsentement': versionConsentement,
        'recto': recto,
        'verso': verso,
        'selfie': selfie,
      });

  /// Récupération en cours sur mon compte (vue de l'ancien téléphone) ; null s'il n'y en a pas.
  Future<Map<String, dynamic>?> recuperationEnCours() async {
    try {
      return await _get('/comptes/moi/recuperation');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sOpposerALaRecuperation() => _post('/comptes/moi/recuperation/opposition');

  /// {commeParrain: [...], commeFilleul: [...]}
  Future<Map<String, dynamic>> parrainages() => _get('/comptes/moi/parrainages');

  Future<Map<String, dynamic>> proposerParrainage(String filleulId) =>
      _post('/comptes/moi/parrainages', {'filleulId': filleulId});

  Future<Map<String, dynamic>> repondreParrainage(String id, {required bool accepte}) =>
      _post('/comptes/moi/parrainages/$id/${accepte ? 'acceptation' : 'refus'}');

  // ----------------------------------------------------------- Sommes dues

  Future<List<Map<String, dynamic>>> sommesDues() => _liste('/sommes-dues');

  Future<Map<String, dynamic>> declarerSommeDue(String id, String reference) =>
      _post('/sommes-dues/$id/paiement', {'referenceTransaction': reference.trim()});

  Future<Map<String, dynamic>> confirmerSommeDue(String id) => _post('/sommes-dues/$id/confirmation');

  // ------------------------------------------------------- Vie d'un cercle

  /// Événements inscrits, documents vérifiés et intégrité.
  Future<Map<String, dynamic>> registre(String cercleId) => _get('/cercles/$cercleId/registre');

  /// Partir avant d'avoir reçu : seulement dans un cercle complet, en cours de cycle.
  Future<Map<String, dynamic>> quitter(String cercleId) => _post('/cercles/$cercleId/depart');

  Future<List<Map<String, dynamic>>> echanges(String cercleId) => _liste('/cercles/$cercleId/echanges');

  /// Le demandeur signe {objet: "echange_de_places", cercleId, demandeurId, placeDemandeur, cedantId, placeCedant}.
  Future<Map<String, dynamic>> proposerEchange({
    required String cercleId,
    required int maPlace,
    required String avecMembreId,
    required int saPlace,
  }) =>
      _post('/cercles/$cercleId/echanges', {
        'avecMembreId': avecMembreId,
        'signature': _cle.signMessage(CryptoService.canonique({
          'objet': 'echange_de_places',
          'cercleId': cercleId,
          'demandeurId': moi,
          'placeDemandeur': maPlace,
          'cedantId': avecMembreId,
          'placeCedant': saPlace,
        })),
      });

  /// Le cédant signe le MÊME message que le demandeur.
  Future<Map<String, dynamic>> accepterEchange(String cercleId, Map<String, dynamic> echange) =>
      _post('/cercles/$cercleId/echanges/${echange['id']}/acceptation', {
        'signature': _cle.signMessage(CryptoService.canonique({
          'objet': 'echange_de_places',
          'cercleId': cercleId,
          'demandeurId': echange['demandeurId'],
          'placeDemandeur': echange['placeDemandeur'],
          'cedantId': echange['cedantId'],
          'placeCedant': echange['placeCedant'],
        })),
      });

  Future<Map<String, dynamic>> refuserEchange(String cercleId, String id) =>
      _post('/cercles/$cercleId/echanges/$id/refus');

  /// Dossier de preuve d'un membre en défaut ; null si aucun défaut constaté.
  Future<Map<String, dynamic>?> dossierDePreuve(String cercleId, String membreId) async {
    try {
      return await _get('/preuve/cercles/$cercleId/membres/$membreId/dossier');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ------------------------------------------- Assistant de l'organisateur

  Future<Map<String, dynamic>> modeAssistant(String cercleId, String mode) =>
      _post('/assistant/cercles/$cercleId/mode', {'mode': mode});

  Future<String> modeActuelAssistant(String cercleId) async =>
      ((await _get('/assistant/cercles/$cercleId/mode'))['mode'] as String?) ?? 'manuel';

  Future<List<Map<String, dynamic>>> journalAssistant(String cercleId) =>
      _liste('/assistant/cercles/$cercleId/journal');

  Future<Map<String, dynamic>> deciderProposition(String id, {required bool accepte}) =>
      _post('/assistant/propositions/$id/${accepte ? 'acceptation' : 'refus'}');

  // ------------------------------------------------- Mobile Money simulé

  /// Hors production : simule un paiement Orange Money ou MTN MoMo.
  Future<Map<String, dynamic>> paiementSimule(String cotisationId, {required String operateur, required String issue}) =>
      _post('/cotisations/$cotisationId/paiement-simule', {'operateur': operateur, 'issue': issue});

  Future<List<Map<String, dynamic>>> paiementsSimules(String cotisationId) =>
      _liste('/cotisations/$cotisationId/paiements-simules');

  // ------------------------------------------- Démonstration (hors production)


  /// Avance l'horloge de la tontine : échéances, retards, défauts, assistant.
  Future<Map<String, dynamic>> demoAvancer(String cercleId, int jours) =>
      _post('/demonstration/cercles/$cercleId/avance', {'jours': jours});
}
