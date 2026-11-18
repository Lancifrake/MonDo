// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OtpResponseImpl _$$OtpResponseImplFromJson(Map<String, dynamic> json) =>
    _$OtpResponseImpl(expireLe: json['expireLe'] as String?);

Map<String, dynamic> _$$OtpResponseImplToJson(_$OtpResponseImpl instance) =>
    <String, dynamic>{'expireLe': instance.expireLe};

_$InscriptionResponseImpl _$$InscriptionResponseImplFromJson(
  Map<String, dynamic> json,
) => _$InscriptionResponseImpl(
  id: json['id'] as String,
  numero: json['numero'] as String,
  nom: json['nom'] as String,
  niveau: (json['niveau'] as num).toInt(),
);

Map<String, dynamic> _$$InscriptionResponseImplToJson(
  _$InscriptionResponseImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'numero': instance.numero,
  'nom': instance.nom,
  'niveau': instance.niveau,
};

_$CompteImpl _$$CompteImplFromJson(Map<String, dynamic> json) => _$CompteImpl(
  id: json['id'] as String,
  numero: json['numero'] as String,
  nom: json['nom'] as String,
  niveau: (json['niveau'] as num).toInt(),
);

Map<String, dynamic> _$$CompteImplToJson(_$CompteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'numero': instance.numero,
      'nom': instance.nom,
      'niveau': instance.niveau,
    };

_$FraisPlaceImpl _$$FraisPlaceImplFromJson(Map<String, dynamic> json) =>
    _$FraisPlaceImpl(
      place: (json['place'] as num).toInt(),
      frais: (json['frais'] as num).toInt(),
      partMonDo: (json['partMonDo'] as num).toInt(),
      remiseParPlaceDeFin: (json['remiseParPlaceDeFin'] as num).toInt(),
    );

Map<String, dynamic> _$$FraisPlaceImplToJson(_$FraisPlaceImpl instance) =>
    <String, dynamic>{
      'place': instance.place,
      'frais': instance.frais,
      'partMonDo': instance.partMonDo,
      'remiseParPlaceDeFin': instance.remiseParPlaceDeFin,
    };

_$ReglementImpl _$$ReglementImplFromJson(Map<String, dynamic> json) =>
    _$ReglementImpl(
      montant: (json['montant'] as num).toInt(),
      frequence: json['frequence'] as String,
      periodeJours: (json['periodeJours'] as num?)?.toInt(),
      nombreMembres: (json['nombreMembres'] as num).toInt(),
      penaliteRetard: (json['penaliteRetard'] as num).toInt(),
      delaiGraceJours: (json['delaiGraceJours'] as num).toInt(),
      ouvert: json['ouvert'] as bool,
      datePremierTour: json['datePremierTour'] as String,
      bareme: (json['bareme'] as List<dynamic>)
          .map((e) => FraisPlace.fromJson(e as Map<String, dynamic>))
          .toList(),
      rappelsAvantEcheanceJours:
          (json['rappelsAvantEcheanceJours'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(),
      scoreMinimum: (json['scoreMinimum'] as num?)?.toInt(),
      ordreFixe: (json['ordreFixe'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      parrainageAccepte: json['parrainageAccepte'] as bool?,
    );

Map<String, dynamic> _$$ReglementImplToJson(_$ReglementImpl instance) =>
    <String, dynamic>{
      'montant': instance.montant,
      'frequence': instance.frequence,
      'periodeJours': instance.periodeJours,
      'nombreMembres': instance.nombreMembres,
      'penaliteRetard': instance.penaliteRetard,
      'delaiGraceJours': instance.delaiGraceJours,
      'ouvert': instance.ouvert,
      'datePremierTour': instance.datePremierTour,
      'bareme': instance.bareme,
      'rappelsAvantEcheanceJours': instance.rappelsAvantEcheanceJours,
      'scoreMinimum': instance.scoreMinimum,
      'ordreFixe': instance.ordreFixe,
      'parrainageAccepte': instance.parrainageAccepte,
    };

_$PlaceOrdreImpl _$$PlaceOrdreImplFromJson(Map<String, dynamic> json) =>
    _$PlaceOrdreImpl(
      membreId: json['membreId'] as String,
      position: (json['position'] as num).toInt(),
      zone: json['zone'] as String?,
      placeSouhaitee: (json['placeSouhaitee'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PlaceOrdreImplToJson(_$PlaceOrdreImpl instance) =>
    <String, dynamic>{
      'membreId': instance.membreId,
      'position': instance.position,
      'zone': instance.zone,
      'placeSouhaitee': instance.placeSouhaitee,
    };

_$CercleImpl _$$CercleImplFromJson(Map<String, dynamic> json) => _$CercleImpl(
  id: json['id'] as String,
  organisateurId: json['organisateurId'] as String?,
  reglement: Reglement.fromJson(json['reglement'] as Map<String, dynamic>),
  empreinteReglement: json['empreinteReglement'] as String?,
  membres:
      (json['membres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  partis: (json['partis'] as List<dynamic>?)?.map((e) => e as String).toList(),
  statut: json['statut'] as String,
  ordre: (json['ordre'] as List<dynamic>?)
      ?.map((e) => PlaceOrdre.fromJson(e as Map<String, dynamic>))
      .toList(),
  termineLe: json['termineLe'] as String?,
  placesRestantes: (json['placesRestantes'] as num?)?.toInt(),
  premierePlaceAutorisee: (json['premierePlaceAutorisee'] as num?)?.toInt(),
  scoreSuffisant: json['scoreSuffisant'] as bool?,
);

Map<String, dynamic> _$$CercleImplToJson(_$CercleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organisateurId': instance.organisateurId,
      'reglement': instance.reglement,
      'empreinteReglement': instance.empreinteReglement,
      'membres': instance.membres,
      'partis': instance.partis,
      'statut': instance.statut,
      'ordre': instance.ordre,
      'termineLe': instance.termineLe,
      'placesRestantes': instance.placesRestantes,
      'premierePlaceAutorisee': instance.premierePlaceAutorisee,
      'scoreSuffisant': instance.scoreSuffisant,
    };

_$ResumeCercleImpl _$$ResumeCercleImplFromJson(Map<String, dynamic> json) =>
    _$ResumeCercleImpl(
      id: json['id'] as String,
      organisateur: json['organisateur'] as bool? ?? false,
      reglement: Reglement.fromJson(json['reglement'] as Map<String, dynamic>),
      statut: json['statut'] as String,
      nombreInscrits: (json['nombreInscrits'] as num?)?.toInt() ?? 0,
      maPlace: (json['maPlace'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ResumeCercleImplToJson(_$ResumeCercleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organisateur': instance.organisateur,
      'reglement': instance.reglement,
      'statut': instance.statut,
      'nombreInscrits': instance.nombreInscrits,
      'maPlace': instance.maPlace,
    };

_$CotisationImpl _$$CotisationImplFromJson(Map<String, dynamic> json) =>
    _$CotisationImpl(
      id: json['id'] as String,
      cercleId: json['cercleId'] as String,
      payeurId: json['payeurId'] as String,
      beneficiaireId: json['beneficiaireId'] as String,
      montant: (json['montant'] as num).toInt(),
      tour: (json['tour'] as num).toInt(),
      dateLimite: json['dateLimite'] as String,
      finGrace: json['finGrace'] as String?,
      statut: json['statut'] as String,
      referenceTransaction: json['referenceTransaction'] as String?,
      declareeLe: json['declareeLe'] as String?,
      confirmeeLe: json['confirmeeLe'] as String?,
      enLitige: json['enLitige'] as bool? ?? false,
      penalite: (json['penalite'] as num?)?.toInt() ?? 0,
      penaliteDue: (json['penaliteDue'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$CotisationImplToJson(_$CotisationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cercleId': instance.cercleId,
      'payeurId': instance.payeurId,
      'beneficiaireId': instance.beneficiaireId,
      'montant': instance.montant,
      'tour': instance.tour,
      'dateLimite': instance.dateLimite,
      'finGrace': instance.finGrace,
      'statut': instance.statut,
      'referenceTransaction': instance.referenceTransaction,
      'declareeLe': instance.declareeLe,
      'confirmeeLe': instance.confirmeeLe,
      'enLitige': instance.enLitige,
      'penalite': instance.penalite,
      'penaliteDue': instance.penaliteDue,
    };

_$EtatCotisationsImpl _$$EtatCotisationsImplFromJson(
  Map<String, dynamic> json,
) => _$EtatCotisationsImpl(
  cercleId: json['cercleId'] as String,
  tours: (json['tours'] as List<dynamic>)
      .map((e) => EtatTour.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$EtatCotisationsImplToJson(
  _$EtatCotisationsImpl instance,
) => <String, dynamic>{'cercleId': instance.cercleId, 'tours': instance.tours};

_$EtatTourImpl _$$EtatTourImplFromJson(Map<String, dynamic> json) =>
    _$EtatTourImpl(
      numero: (json['numero'] as num).toInt(),
      beneficiaireId: json['beneficiaireId'] as String,
      dateLimite: json['dateLimite'] as String?,
      paiements: (json['paiements'] as List<dynamic>)
          .map((e) => EtatMembre.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$EtatTourImplToJson(_$EtatTourImpl instance) =>
    <String, dynamic>{
      'numero': instance.numero,
      'beneficiaireId': instance.beneficiaireId,
      'dateLimite': instance.dateLimite,
      'paiements': instance.paiements,
    };

_$EtatMembreImpl _$$EtatMembreImplFromJson(Map<String, dynamic> json) =>
    _$EtatMembreImpl(
      payeurId: json['payeurId'] as String,
      montant: (json['montant'] as num).toInt(),
      statut: json['statut'] as String,
      enRetard: json['enRetard'] as bool? ?? false,
      enLitige: json['enLitige'] as bool? ?? false,
      penaliteDue: (json['penaliteDue'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$EtatMembreImplToJson(_$EtatMembreImpl instance) =>
    <String, dynamic>{
      'payeurId': instance.payeurId,
      'montant': instance.montant,
      'statut': instance.statut,
      'enRetard': instance.enRetard,
      'enLitige': instance.enLitige,
      'penaliteDue': instance.penaliteDue,
    };

_$ScoreMembreImpl _$$ScoreMembreImplFromJson(Map<String, dynamic> json) =>
    _$ScoreMembreImpl(
      membreId: json['membreId'] as String,
      score: (json['score'] as num).toInt(),
      cyclesTermines: (json['cyclesTermines'] as num?)?.toInt() ?? 0,
      defauts: (json['defauts'] as num?)?.toInt() ?? 0,
      premieresPlacesFermees: json['premieresPlacesFermees'] as bool? ?? false,
      explication:
          (json['explication'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      historique:
          (json['historique'] as List<dynamic>?)
              ?.map((e) => EvenementScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <EvenementScore>[],
    );

Map<String, dynamic> _$$ScoreMembreImplToJson(_$ScoreMembreImpl instance) =>
    <String, dynamic>{
      'membreId': instance.membreId,
      'score': instance.score,
      'cyclesTermines': instance.cyclesTermines,
      'defauts': instance.defauts,
      'premieresPlacesFermees': instance.premieresPlacesFermees,
      'explication': instance.explication,
      'historique': instance.historique,
    };

_$EvenementScoreImpl _$$EvenementScoreImplFromJson(Map<String, dynamic> json) =>
    _$EvenementScoreImpl(
      date: json['date'] as String,
      type: json['type'] as String,
      cercleId: json['cercleId'] as String?,
      cerclePrive: json['cerclePrive'] as bool? ?? false,
      points: json['points'] as num,
      scoreApres: json['scoreApres'] as num,
    );

Map<String, dynamic> _$$EvenementScoreImplToJson(
  _$EvenementScoreImpl instance,
) => <String, dynamic>{
  'date': instance.date,
  'type': instance.type,
  'cercleId': instance.cercleId,
  'cerclePrive': instance.cerclePrive,
  'points': instance.points,
  'scoreApres': instance.scoreApres,
};

_$LitigeImpl _$$LitigeImplFromJson(Map<String, dynamic> json) => _$LitigeImpl(
  id: json['id'] as String,
  cotisationId: json['cotisationId'] as String,
  cercleId: json['cercleId'] as String,
  payeurId: json['payeurId'] as String,
  beneficiaireId: json['beneficiaireId'] as String,
  ouvertPar: json['ouvertPar'] as String,
  motif: json['motif'] as String,
  ouvertLe: json['ouvertLe'] as String,
  statut: json['statut'] as String,
  decision: json['decision'] as String?,
  motifDecision: json['motifDecision'] as String?,
  tranchePar: json['tranchePar'] as String?,
  trancheLe: json['trancheLe'] as String?,
);

Map<String, dynamic> _$$LitigeImplToJson(_$LitigeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cotisationId': instance.cotisationId,
      'cercleId': instance.cercleId,
      'payeurId': instance.payeurId,
      'beneficiaireId': instance.beneficiaireId,
      'ouvertPar': instance.ouvertPar,
      'motif': instance.motif,
      'ouvertLe': instance.ouvertLe,
      'statut': instance.statut,
      'decision': instance.decision,
      'motifDecision': instance.motifDecision,
      'tranchePar': instance.tranchePar,
      'trancheLe': instance.trancheLe,
    };

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      id: json['id'] as String,
      texte: json['texte'] as String,
      creeeLe: json['creeeLe'] as String,
      lueLe: json['lueLe'] as String?,
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'texte': instance.texte,
      'creeeLe': instance.creeeLe,
      'lueLe': instance.lueLe,
    };

_$NotificationsResponseImpl _$$NotificationsResponseImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationsResponseImpl(
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => Notification.fromJson(e as Map<String, dynamic>))
      .toList(),
  nonLues: (json['nonLues'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$NotificationsResponseImplToJson(
  _$NotificationsResponseImpl instance,
) => <String, dynamic>{
  'notifications': instance.notifications,
  'nonLues': instance.nonLues,
};

_$SommeDueImpl _$$SommeDueImplFromJson(Map<String, dynamic> json) =>
    _$SommeDueImpl(
      id: json['id'] as String,
      cercleId: json['cercleId'] as String,
      nature: json['nature'] as String,
      debiteurId: json['debiteurId'] as String?,
      creancierId: json['creancierId'] as String?,
      montant: (json['montant'] as num).toInt(),
      tour: (json['tour'] as num?)?.toInt(),
      exigibleLe: json['exigibleLe'] as String?,
      dateLimite: json['dateLimite'] as String?,
      statut: json['statut'] as String,
    );

Map<String, dynamic> _$$SommeDueImplToJson(_$SommeDueImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cercleId': instance.cercleId,
      'nature': instance.nature,
      'debiteurId': instance.debiteurId,
      'creancierId': instance.creancierId,
      'montant': instance.montant,
      'tour': instance.tour,
      'exigibleLe': instance.exigibleLe,
      'dateLimite': instance.dateLimite,
      'statut': instance.statut,
    };
