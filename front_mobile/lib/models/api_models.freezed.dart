// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OtpResponse _$OtpResponseFromJson(Map<String, dynamic> json) {
  return _OtpResponse.fromJson(json);
}

/// @nodoc
mixin _$OtpResponse {
  String? get expireLe => throw _privateConstructorUsedError;

  /// Serializes this OtpResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OtpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OtpResponseCopyWith<OtpResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtpResponseCopyWith<$Res> {
  factory $OtpResponseCopyWith(
    OtpResponse value,
    $Res Function(OtpResponse) then,
  ) = _$OtpResponseCopyWithImpl<$Res, OtpResponse>;
  @useResult
  $Res call({String? expireLe});
}

/// @nodoc
class _$OtpResponseCopyWithImpl<$Res, $Val extends OtpResponse>
    implements $OtpResponseCopyWith<$Res> {
  _$OtpResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OtpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? expireLe = freezed}) {
    return _then(
      _value.copyWith(
            expireLe: freezed == expireLe
                ? _value.expireLe
                : expireLe // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OtpResponseImplCopyWith<$Res>
    implements $OtpResponseCopyWith<$Res> {
  factory _$$OtpResponseImplCopyWith(
    _$OtpResponseImpl value,
    $Res Function(_$OtpResponseImpl) then,
  ) = __$$OtpResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? expireLe});
}

/// @nodoc
class __$$OtpResponseImplCopyWithImpl<$Res>
    extends _$OtpResponseCopyWithImpl<$Res, _$OtpResponseImpl>
    implements _$$OtpResponseImplCopyWith<$Res> {
  __$$OtpResponseImplCopyWithImpl(
    _$OtpResponseImpl _value,
    $Res Function(_$OtpResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OtpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? expireLe = freezed}) {
    return _then(
      _$OtpResponseImpl(
        expireLe: freezed == expireLe
            ? _value.expireLe
            : expireLe // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OtpResponseImpl implements _OtpResponse {
  const _$OtpResponseImpl({this.expireLe});

  factory _$OtpResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$OtpResponseImplFromJson(json);

  @override
  final String? expireLe;

  @override
  String toString() {
    return 'OtpResponse(expireLe: $expireLe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtpResponseImpl &&
            (identical(other.expireLe, expireLe) ||
                other.expireLe == expireLe));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, expireLe);

  /// Create a copy of OtpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OtpResponseImplCopyWith<_$OtpResponseImpl> get copyWith =>
      __$$OtpResponseImplCopyWithImpl<_$OtpResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OtpResponseImplToJson(this);
  }
}

abstract class _OtpResponse implements OtpResponse {
  const factory _OtpResponse({final String? expireLe}) = _$OtpResponseImpl;

  factory _OtpResponse.fromJson(Map<String, dynamic> json) =
      _$OtpResponseImpl.fromJson;

  @override
  String? get expireLe;

  /// Create a copy of OtpResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OtpResponseImplCopyWith<_$OtpResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InscriptionResponse _$InscriptionResponseFromJson(Map<String, dynamic> json) {
  return _InscriptionResponse.fromJson(json);
}

/// @nodoc
mixin _$InscriptionResponse {
  String get id => throw _privateConstructorUsedError;
  String get numero => throw _privateConstructorUsedError;
  String get nom => throw _privateConstructorUsedError;
  int get niveau => throw _privateConstructorUsedError;

  /// Serializes this InscriptionResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InscriptionResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InscriptionResponseCopyWith<InscriptionResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InscriptionResponseCopyWith<$Res> {
  factory $InscriptionResponseCopyWith(
    InscriptionResponse value,
    $Res Function(InscriptionResponse) then,
  ) = _$InscriptionResponseCopyWithImpl<$Res, InscriptionResponse>;
  @useResult
  $Res call({String id, String numero, String nom, int niveau});
}

/// @nodoc
class _$InscriptionResponseCopyWithImpl<$Res, $Val extends InscriptionResponse>
    implements $InscriptionResponseCopyWith<$Res> {
  _$InscriptionResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InscriptionResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? numero = null,
    Object? nom = null,
    Object? niveau = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            numero: null == numero
                ? _value.numero
                : numero // ignore: cast_nullable_to_non_nullable
                      as String,
            nom: null == nom
                ? _value.nom
                : nom // ignore: cast_nullable_to_non_nullable
                      as String,
            niveau: null == niveau
                ? _value.niveau
                : niveau // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InscriptionResponseImplCopyWith<$Res>
    implements $InscriptionResponseCopyWith<$Res> {
  factory _$$InscriptionResponseImplCopyWith(
    _$InscriptionResponseImpl value,
    $Res Function(_$InscriptionResponseImpl) then,
  ) = __$$InscriptionResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String numero, String nom, int niveau});
}

/// @nodoc
class __$$InscriptionResponseImplCopyWithImpl<$Res>
    extends _$InscriptionResponseCopyWithImpl<$Res, _$InscriptionResponseImpl>
    implements _$$InscriptionResponseImplCopyWith<$Res> {
  __$$InscriptionResponseImplCopyWithImpl(
    _$InscriptionResponseImpl _value,
    $Res Function(_$InscriptionResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InscriptionResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? numero = null,
    Object? nom = null,
    Object? niveau = null,
  }) {
    return _then(
      _$InscriptionResponseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        numero: null == numero
            ? _value.numero
            : numero // ignore: cast_nullable_to_non_nullable
                  as String,
        nom: null == nom
            ? _value.nom
            : nom // ignore: cast_nullable_to_non_nullable
                  as String,
        niveau: null == niveau
            ? _value.niveau
            : niveau // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InscriptionResponseImpl implements _InscriptionResponse {
  const _$InscriptionResponseImpl({
    required this.id,
    required this.numero,
    required this.nom,
    required this.niveau,
  });

  factory _$InscriptionResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$InscriptionResponseImplFromJson(json);

  @override
  final String id;
  @override
  final String numero;
  @override
  final String nom;
  @override
  final int niveau;

  @override
  String toString() {
    return 'InscriptionResponse(id: $id, numero: $numero, nom: $nom, niveau: $niveau)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InscriptionResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.numero, numero) || other.numero == numero) &&
            (identical(other.nom, nom) || other.nom == nom) &&
            (identical(other.niveau, niveau) || other.niveau == niveau));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, numero, nom, niveau);

  /// Create a copy of InscriptionResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InscriptionResponseImplCopyWith<_$InscriptionResponseImpl> get copyWith =>
      __$$InscriptionResponseImplCopyWithImpl<_$InscriptionResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InscriptionResponseImplToJson(this);
  }
}

abstract class _InscriptionResponse implements InscriptionResponse {
  const factory _InscriptionResponse({
    required final String id,
    required final String numero,
    required final String nom,
    required final int niveau,
  }) = _$InscriptionResponseImpl;

  factory _InscriptionResponse.fromJson(Map<String, dynamic> json) =
      _$InscriptionResponseImpl.fromJson;

  @override
  String get id;
  @override
  String get numero;
  @override
  String get nom;
  @override
  int get niveau;

  /// Create a copy of InscriptionResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InscriptionResponseImplCopyWith<_$InscriptionResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Compte _$CompteFromJson(Map<String, dynamic> json) {
  return _Compte.fromJson(json);
}

/// @nodoc
mixin _$Compte {
  String get id => throw _privateConstructorUsedError;
  String get numero => throw _privateConstructorUsedError;
  String get nom => throw _privateConstructorUsedError;
  int get niveau => throw _privateConstructorUsedError;

  /// Serializes this Compte to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Compte
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompteCopyWith<Compte> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompteCopyWith<$Res> {
  factory $CompteCopyWith(Compte value, $Res Function(Compte) then) =
      _$CompteCopyWithImpl<$Res, Compte>;
  @useResult
  $Res call({String id, String numero, String nom, int niveau});
}

/// @nodoc
class _$CompteCopyWithImpl<$Res, $Val extends Compte>
    implements $CompteCopyWith<$Res> {
  _$CompteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Compte
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? numero = null,
    Object? nom = null,
    Object? niveau = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            numero: null == numero
                ? _value.numero
                : numero // ignore: cast_nullable_to_non_nullable
                      as String,
            nom: null == nom
                ? _value.nom
                : nom // ignore: cast_nullable_to_non_nullable
                      as String,
            niveau: null == niveau
                ? _value.niveau
                : niveau // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompteImplCopyWith<$Res> implements $CompteCopyWith<$Res> {
  factory _$$CompteImplCopyWith(
    _$CompteImpl value,
    $Res Function(_$CompteImpl) then,
  ) = __$$CompteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String numero, String nom, int niveau});
}

/// @nodoc
class __$$CompteImplCopyWithImpl<$Res>
    extends _$CompteCopyWithImpl<$Res, _$CompteImpl>
    implements _$$CompteImplCopyWith<$Res> {
  __$$CompteImplCopyWithImpl(
    _$CompteImpl _value,
    $Res Function(_$CompteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Compte
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? numero = null,
    Object? nom = null,
    Object? niveau = null,
  }) {
    return _then(
      _$CompteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        numero: null == numero
            ? _value.numero
            : numero // ignore: cast_nullable_to_non_nullable
                  as String,
        nom: null == nom
            ? _value.nom
            : nom // ignore: cast_nullable_to_non_nullable
                  as String,
        niveau: null == niveau
            ? _value.niveau
            : niveau // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompteImpl implements _Compte {
  const _$CompteImpl({
    required this.id,
    required this.numero,
    required this.nom,
    required this.niveau,
  });

  factory _$CompteImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompteImplFromJson(json);

  @override
  final String id;
  @override
  final String numero;
  @override
  final String nom;
  @override
  final int niveau;

  @override
  String toString() {
    return 'Compte(id: $id, numero: $numero, nom: $nom, niveau: $niveau)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.numero, numero) || other.numero == numero) &&
            (identical(other.nom, nom) || other.nom == nom) &&
            (identical(other.niveau, niveau) || other.niveau == niveau));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, numero, nom, niveau);

  /// Create a copy of Compte
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompteImplCopyWith<_$CompteImpl> get copyWith =>
      __$$CompteImplCopyWithImpl<_$CompteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompteImplToJson(this);
  }
}

abstract class _Compte implements Compte {
  const factory _Compte({
    required final String id,
    required final String numero,
    required final String nom,
    required final int niveau,
  }) = _$CompteImpl;

  factory _Compte.fromJson(Map<String, dynamic> json) = _$CompteImpl.fromJson;

  @override
  String get id;
  @override
  String get numero;
  @override
  String get nom;
  @override
  int get niveau;

  /// Create a copy of Compte
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompteImplCopyWith<_$CompteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FraisPlace _$FraisPlaceFromJson(Map<String, dynamic> json) {
  return _FraisPlace.fromJson(json);
}

/// @nodoc
mixin _$FraisPlace {
  int get place => throw _privateConstructorUsedError;
  int get frais => throw _privateConstructorUsedError;
  int get partMonDo => throw _privateConstructorUsedError;
  int get remiseParPlaceDeFin => throw _privateConstructorUsedError;

  /// Serializes this FraisPlace to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FraisPlace
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FraisPlaceCopyWith<FraisPlace> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FraisPlaceCopyWith<$Res> {
  factory $FraisPlaceCopyWith(
    FraisPlace value,
    $Res Function(FraisPlace) then,
  ) = _$FraisPlaceCopyWithImpl<$Res, FraisPlace>;
  @useResult
  $Res call({int place, int frais, int partMonDo, int remiseParPlaceDeFin});
}

/// @nodoc
class _$FraisPlaceCopyWithImpl<$Res, $Val extends FraisPlace>
    implements $FraisPlaceCopyWith<$Res> {
  _$FraisPlaceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FraisPlace
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? place = null,
    Object? frais = null,
    Object? partMonDo = null,
    Object? remiseParPlaceDeFin = null,
  }) {
    return _then(
      _value.copyWith(
            place: null == place
                ? _value.place
                : place // ignore: cast_nullable_to_non_nullable
                      as int,
            frais: null == frais
                ? _value.frais
                : frais // ignore: cast_nullable_to_non_nullable
                      as int,
            partMonDo: null == partMonDo
                ? _value.partMonDo
                : partMonDo // ignore: cast_nullable_to_non_nullable
                      as int,
            remiseParPlaceDeFin: null == remiseParPlaceDeFin
                ? _value.remiseParPlaceDeFin
                : remiseParPlaceDeFin // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FraisPlaceImplCopyWith<$Res>
    implements $FraisPlaceCopyWith<$Res> {
  factory _$$FraisPlaceImplCopyWith(
    _$FraisPlaceImpl value,
    $Res Function(_$FraisPlaceImpl) then,
  ) = __$$FraisPlaceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int place, int frais, int partMonDo, int remiseParPlaceDeFin});
}

/// @nodoc
class __$$FraisPlaceImplCopyWithImpl<$Res>
    extends _$FraisPlaceCopyWithImpl<$Res, _$FraisPlaceImpl>
    implements _$$FraisPlaceImplCopyWith<$Res> {
  __$$FraisPlaceImplCopyWithImpl(
    _$FraisPlaceImpl _value,
    $Res Function(_$FraisPlaceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FraisPlace
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? place = null,
    Object? frais = null,
    Object? partMonDo = null,
    Object? remiseParPlaceDeFin = null,
  }) {
    return _then(
      _$FraisPlaceImpl(
        place: null == place
            ? _value.place
            : place // ignore: cast_nullable_to_non_nullable
                  as int,
        frais: null == frais
            ? _value.frais
            : frais // ignore: cast_nullable_to_non_nullable
                  as int,
        partMonDo: null == partMonDo
            ? _value.partMonDo
            : partMonDo // ignore: cast_nullable_to_non_nullable
                  as int,
        remiseParPlaceDeFin: null == remiseParPlaceDeFin
            ? _value.remiseParPlaceDeFin
            : remiseParPlaceDeFin // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FraisPlaceImpl implements _FraisPlace {
  const _$FraisPlaceImpl({
    required this.place,
    required this.frais,
    required this.partMonDo,
    required this.remiseParPlaceDeFin,
  });

  factory _$FraisPlaceImpl.fromJson(Map<String, dynamic> json) =>
      _$$FraisPlaceImplFromJson(json);

  @override
  final int place;
  @override
  final int frais;
  @override
  final int partMonDo;
  @override
  final int remiseParPlaceDeFin;

  @override
  String toString() {
    return 'FraisPlace(place: $place, frais: $frais, partMonDo: $partMonDo, remiseParPlaceDeFin: $remiseParPlaceDeFin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FraisPlaceImpl &&
            (identical(other.place, place) || other.place == place) &&
            (identical(other.frais, frais) || other.frais == frais) &&
            (identical(other.partMonDo, partMonDo) ||
                other.partMonDo == partMonDo) &&
            (identical(other.remiseParPlaceDeFin, remiseParPlaceDeFin) ||
                other.remiseParPlaceDeFin == remiseParPlaceDeFin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, place, frais, partMonDo, remiseParPlaceDeFin);

  /// Create a copy of FraisPlace
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FraisPlaceImplCopyWith<_$FraisPlaceImpl> get copyWith =>
      __$$FraisPlaceImplCopyWithImpl<_$FraisPlaceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FraisPlaceImplToJson(this);
  }
}

abstract class _FraisPlace implements FraisPlace {
  const factory _FraisPlace({
    required final int place,
    required final int frais,
    required final int partMonDo,
    required final int remiseParPlaceDeFin,
  }) = _$FraisPlaceImpl;

  factory _FraisPlace.fromJson(Map<String, dynamic> json) =
      _$FraisPlaceImpl.fromJson;

  @override
  int get place;
  @override
  int get frais;
  @override
  int get partMonDo;
  @override
  int get remiseParPlaceDeFin;

  /// Create a copy of FraisPlace
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FraisPlaceImplCopyWith<_$FraisPlaceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Reglement _$ReglementFromJson(Map<String, dynamic> json) {
  return _Reglement.fromJson(json);
}

/// @nodoc
mixin _$Reglement {
  int get montant => throw _privateConstructorUsedError;
  String get frequence =>
      throw _privateConstructorUsedError; // hebdomadaire, mensuelle, jours
  int? get periodeJours => throw _privateConstructorUsedError;
  int get nombreMembres => throw _privateConstructorUsedError;
  int get penaliteRetard => throw _privateConstructorUsedError;
  int get delaiGraceJours => throw _privateConstructorUsedError;
  bool get ouvert => throw _privateConstructorUsedError;
  String get datePremierTour => throw _privateConstructorUsedError;
  List<FraisPlace> get bareme => throw _privateConstructorUsedError;
  List<int>? get rappelsAvantEcheanceJours =>
      throw _privateConstructorUsedError;
  int? get scoreMinimum => throw _privateConstructorUsedError;
  List<String>? get ordreFixe => throw _privateConstructorUsedError;
  bool? get parrainageAccepte => throw _privateConstructorUsedError;

  /// Serializes this Reglement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Reglement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReglementCopyWith<Reglement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReglementCopyWith<$Res> {
  factory $ReglementCopyWith(Reglement value, $Res Function(Reglement) then) =
      _$ReglementCopyWithImpl<$Res, Reglement>;
  @useResult
  $Res call({
    int montant,
    String frequence,
    int? periodeJours,
    int nombreMembres,
    int penaliteRetard,
    int delaiGraceJours,
    bool ouvert,
    String datePremierTour,
    List<FraisPlace> bareme,
    List<int>? rappelsAvantEcheanceJours,
    int? scoreMinimum,
    List<String>? ordreFixe,
    bool? parrainageAccepte,
  });
}

/// @nodoc
class _$ReglementCopyWithImpl<$Res, $Val extends Reglement>
    implements $ReglementCopyWith<$Res> {
  _$ReglementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reglement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? montant = null,
    Object? frequence = null,
    Object? periodeJours = freezed,
    Object? nombreMembres = null,
    Object? penaliteRetard = null,
    Object? delaiGraceJours = null,
    Object? ouvert = null,
    Object? datePremierTour = null,
    Object? bareme = null,
    Object? rappelsAvantEcheanceJours = freezed,
    Object? scoreMinimum = freezed,
    Object? ordreFixe = freezed,
    Object? parrainageAccepte = freezed,
  }) {
    return _then(
      _value.copyWith(
            montant: null == montant
                ? _value.montant
                : montant // ignore: cast_nullable_to_non_nullable
                      as int,
            frequence: null == frequence
                ? _value.frequence
                : frequence // ignore: cast_nullable_to_non_nullable
                      as String,
            periodeJours: freezed == periodeJours
                ? _value.periodeJours
                : periodeJours // ignore: cast_nullable_to_non_nullable
                      as int?,
            nombreMembres: null == nombreMembres
                ? _value.nombreMembres
                : nombreMembres // ignore: cast_nullable_to_non_nullable
                      as int,
            penaliteRetard: null == penaliteRetard
                ? _value.penaliteRetard
                : penaliteRetard // ignore: cast_nullable_to_non_nullable
                      as int,
            delaiGraceJours: null == delaiGraceJours
                ? _value.delaiGraceJours
                : delaiGraceJours // ignore: cast_nullable_to_non_nullable
                      as int,
            ouvert: null == ouvert
                ? _value.ouvert
                : ouvert // ignore: cast_nullable_to_non_nullable
                      as bool,
            datePremierTour: null == datePremierTour
                ? _value.datePremierTour
                : datePremierTour // ignore: cast_nullable_to_non_nullable
                      as String,
            bareme: null == bareme
                ? _value.bareme
                : bareme // ignore: cast_nullable_to_non_nullable
                      as List<FraisPlace>,
            rappelsAvantEcheanceJours: freezed == rappelsAvantEcheanceJours
                ? _value.rappelsAvantEcheanceJours
                : rappelsAvantEcheanceJours // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            scoreMinimum: freezed == scoreMinimum
                ? _value.scoreMinimum
                : scoreMinimum // ignore: cast_nullable_to_non_nullable
                      as int?,
            ordreFixe: freezed == ordreFixe
                ? _value.ordreFixe
                : ordreFixe // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            parrainageAccepte: freezed == parrainageAccepte
                ? _value.parrainageAccepte
                : parrainageAccepte // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReglementImplCopyWith<$Res>
    implements $ReglementCopyWith<$Res> {
  factory _$$ReglementImplCopyWith(
    _$ReglementImpl value,
    $Res Function(_$ReglementImpl) then,
  ) = __$$ReglementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int montant,
    String frequence,
    int? periodeJours,
    int nombreMembres,
    int penaliteRetard,
    int delaiGraceJours,
    bool ouvert,
    String datePremierTour,
    List<FraisPlace> bareme,
    List<int>? rappelsAvantEcheanceJours,
    int? scoreMinimum,
    List<String>? ordreFixe,
    bool? parrainageAccepte,
  });
}

/// @nodoc
class __$$ReglementImplCopyWithImpl<$Res>
    extends _$ReglementCopyWithImpl<$Res, _$ReglementImpl>
    implements _$$ReglementImplCopyWith<$Res> {
  __$$ReglementImplCopyWithImpl(
    _$ReglementImpl _value,
    $Res Function(_$ReglementImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Reglement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? montant = null,
    Object? frequence = null,
    Object? periodeJours = freezed,
    Object? nombreMembres = null,
    Object? penaliteRetard = null,
    Object? delaiGraceJours = null,
    Object? ouvert = null,
    Object? datePremierTour = null,
    Object? bareme = null,
    Object? rappelsAvantEcheanceJours = freezed,
    Object? scoreMinimum = freezed,
    Object? ordreFixe = freezed,
    Object? parrainageAccepte = freezed,
  }) {
    return _then(
      _$ReglementImpl(
        montant: null == montant
            ? _value.montant
            : montant // ignore: cast_nullable_to_non_nullable
                  as int,
        frequence: null == frequence
            ? _value.frequence
            : frequence // ignore: cast_nullable_to_non_nullable
                  as String,
        periodeJours: freezed == periodeJours
            ? _value.periodeJours
            : periodeJours // ignore: cast_nullable_to_non_nullable
                  as int?,
        nombreMembres: null == nombreMembres
            ? _value.nombreMembres
            : nombreMembres // ignore: cast_nullable_to_non_nullable
                  as int,
        penaliteRetard: null == penaliteRetard
            ? _value.penaliteRetard
            : penaliteRetard // ignore: cast_nullable_to_non_nullable
                  as int,
        delaiGraceJours: null == delaiGraceJours
            ? _value.delaiGraceJours
            : delaiGraceJours // ignore: cast_nullable_to_non_nullable
                  as int,
        ouvert: null == ouvert
            ? _value.ouvert
            : ouvert // ignore: cast_nullable_to_non_nullable
                  as bool,
        datePremierTour: null == datePremierTour
            ? _value.datePremierTour
            : datePremierTour // ignore: cast_nullable_to_non_nullable
                  as String,
        bareme: null == bareme
            ? _value._bareme
            : bareme // ignore: cast_nullable_to_non_nullable
                  as List<FraisPlace>,
        rappelsAvantEcheanceJours: freezed == rappelsAvantEcheanceJours
            ? _value._rappelsAvantEcheanceJours
            : rappelsAvantEcheanceJours // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        scoreMinimum: freezed == scoreMinimum
            ? _value.scoreMinimum
            : scoreMinimum // ignore: cast_nullable_to_non_nullable
                  as int?,
        ordreFixe: freezed == ordreFixe
            ? _value._ordreFixe
            : ordreFixe // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        parrainageAccepte: freezed == parrainageAccepte
            ? _value.parrainageAccepte
            : parrainageAccepte // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReglementImpl implements _Reglement {
  const _$ReglementImpl({
    required this.montant,
    required this.frequence,
    this.periodeJours,
    required this.nombreMembres,
    required this.penaliteRetard,
    required this.delaiGraceJours,
    required this.ouvert,
    required this.datePremierTour,
    required final List<FraisPlace> bareme,
    final List<int>? rappelsAvantEcheanceJours,
    this.scoreMinimum,
    final List<String>? ordreFixe,
    this.parrainageAccepte,
  }) : _bareme = bareme,
       _rappelsAvantEcheanceJours = rappelsAvantEcheanceJours,
       _ordreFixe = ordreFixe;

  factory _$ReglementImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReglementImplFromJson(json);

  @override
  final int montant;
  @override
  final String frequence;
  // hebdomadaire, mensuelle, jours
  @override
  final int? periodeJours;
  @override
  final int nombreMembres;
  @override
  final int penaliteRetard;
  @override
  final int delaiGraceJours;
  @override
  final bool ouvert;
  @override
  final String datePremierTour;
  final List<FraisPlace> _bareme;
  @override
  List<FraisPlace> get bareme {
    if (_bareme is EqualUnmodifiableListView) return _bareme;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bareme);
  }

  final List<int>? _rappelsAvantEcheanceJours;
  @override
  List<int>? get rappelsAvantEcheanceJours {
    final value = _rappelsAvantEcheanceJours;
    if (value == null) return null;
    if (_rappelsAvantEcheanceJours is EqualUnmodifiableListView)
      return _rappelsAvantEcheanceJours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? scoreMinimum;
  final List<String>? _ordreFixe;
  @override
  List<String>? get ordreFixe {
    final value = _ordreFixe;
    if (value == null) return null;
    if (_ordreFixe is EqualUnmodifiableListView) return _ordreFixe;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final bool? parrainageAccepte;

  @override
  String toString() {
    return 'Reglement(montant: $montant, frequence: $frequence, periodeJours: $periodeJours, nombreMembres: $nombreMembres, penaliteRetard: $penaliteRetard, delaiGraceJours: $delaiGraceJours, ouvert: $ouvert, datePremierTour: $datePremierTour, bareme: $bareme, rappelsAvantEcheanceJours: $rappelsAvantEcheanceJours, scoreMinimum: $scoreMinimum, ordreFixe: $ordreFixe, parrainageAccepte: $parrainageAccepte)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReglementImpl &&
            (identical(other.montant, montant) || other.montant == montant) &&
            (identical(other.frequence, frequence) ||
                other.frequence == frequence) &&
            (identical(other.periodeJours, periodeJours) ||
                other.periodeJours == periodeJours) &&
            (identical(other.nombreMembres, nombreMembres) ||
                other.nombreMembres == nombreMembres) &&
            (identical(other.penaliteRetard, penaliteRetard) ||
                other.penaliteRetard == penaliteRetard) &&
            (identical(other.delaiGraceJours, delaiGraceJours) ||
                other.delaiGraceJours == delaiGraceJours) &&
            (identical(other.ouvert, ouvert) || other.ouvert == ouvert) &&
            (identical(other.datePremierTour, datePremierTour) ||
                other.datePremierTour == datePremierTour) &&
            const DeepCollectionEquality().equals(other._bareme, _bareme) &&
            const DeepCollectionEquality().equals(
              other._rappelsAvantEcheanceJours,
              _rappelsAvantEcheanceJours,
            ) &&
            (identical(other.scoreMinimum, scoreMinimum) ||
                other.scoreMinimum == scoreMinimum) &&
            const DeepCollectionEquality().equals(
              other._ordreFixe,
              _ordreFixe,
            ) &&
            (identical(other.parrainageAccepte, parrainageAccepte) ||
                other.parrainageAccepte == parrainageAccepte));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    montant,
    frequence,
    periodeJours,
    nombreMembres,
    penaliteRetard,
    delaiGraceJours,
    ouvert,
    datePremierTour,
    const DeepCollectionEquality().hash(_bareme),
    const DeepCollectionEquality().hash(_rappelsAvantEcheanceJours),
    scoreMinimum,
    const DeepCollectionEquality().hash(_ordreFixe),
    parrainageAccepte,
  );

  /// Create a copy of Reglement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReglementImplCopyWith<_$ReglementImpl> get copyWith =>
      __$$ReglementImplCopyWithImpl<_$ReglementImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReglementImplToJson(this);
  }
}

abstract class _Reglement implements Reglement {
  const factory _Reglement({
    required final int montant,
    required final String frequence,
    final int? periodeJours,
    required final int nombreMembres,
    required final int penaliteRetard,
    required final int delaiGraceJours,
    required final bool ouvert,
    required final String datePremierTour,
    required final List<FraisPlace> bareme,
    final List<int>? rappelsAvantEcheanceJours,
    final int? scoreMinimum,
    final List<String>? ordreFixe,
    final bool? parrainageAccepte,
  }) = _$ReglementImpl;

  factory _Reglement.fromJson(Map<String, dynamic> json) =
      _$ReglementImpl.fromJson;

  @override
  int get montant;
  @override
  String get frequence; // hebdomadaire, mensuelle, jours
  @override
  int? get periodeJours;
  @override
  int get nombreMembres;
  @override
  int get penaliteRetard;
  @override
  int get delaiGraceJours;
  @override
  bool get ouvert;
  @override
  String get datePremierTour;
  @override
  List<FraisPlace> get bareme;
  @override
  List<int>? get rappelsAvantEcheanceJours;
  @override
  int? get scoreMinimum;
  @override
  List<String>? get ordreFixe;
  @override
  bool? get parrainageAccepte;

  /// Create a copy of Reglement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReglementImplCopyWith<_$ReglementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaceOrdre _$PlaceOrdreFromJson(Map<String, dynamic> json) {
  return _PlaceOrdre.fromJson(json);
}

/// @nodoc
mixin _$PlaceOrdre {
  String get membreId => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  String? get zone => throw _privateConstructorUsedError;
  int? get placeSouhaitee => throw _privateConstructorUsedError;

  /// Serializes this PlaceOrdre to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaceOrdre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaceOrdreCopyWith<PlaceOrdre> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaceOrdreCopyWith<$Res> {
  factory $PlaceOrdreCopyWith(
    PlaceOrdre value,
    $Res Function(PlaceOrdre) then,
  ) = _$PlaceOrdreCopyWithImpl<$Res, PlaceOrdre>;
  @useResult
  $Res call({String membreId, int position, String? zone, int? placeSouhaitee});
}

/// @nodoc
class _$PlaceOrdreCopyWithImpl<$Res, $Val extends PlaceOrdre>
    implements $PlaceOrdreCopyWith<$Res> {
  _$PlaceOrdreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaceOrdre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? membreId = null,
    Object? position = null,
    Object? zone = freezed,
    Object? placeSouhaitee = freezed,
  }) {
    return _then(
      _value.copyWith(
            membreId: null == membreId
                ? _value.membreId
                : membreId // ignore: cast_nullable_to_non_nullable
                      as String,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as int,
            zone: freezed == zone
                ? _value.zone
                : zone // ignore: cast_nullable_to_non_nullable
                      as String?,
            placeSouhaitee: freezed == placeSouhaitee
                ? _value.placeSouhaitee
                : placeSouhaitee // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaceOrdreImplCopyWith<$Res>
    implements $PlaceOrdreCopyWith<$Res> {
  factory _$$PlaceOrdreImplCopyWith(
    _$PlaceOrdreImpl value,
    $Res Function(_$PlaceOrdreImpl) then,
  ) = __$$PlaceOrdreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String membreId, int position, String? zone, int? placeSouhaitee});
}

/// @nodoc
class __$$PlaceOrdreImplCopyWithImpl<$Res>
    extends _$PlaceOrdreCopyWithImpl<$Res, _$PlaceOrdreImpl>
    implements _$$PlaceOrdreImplCopyWith<$Res> {
  __$$PlaceOrdreImplCopyWithImpl(
    _$PlaceOrdreImpl _value,
    $Res Function(_$PlaceOrdreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaceOrdre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? membreId = null,
    Object? position = null,
    Object? zone = freezed,
    Object? placeSouhaitee = freezed,
  }) {
    return _then(
      _$PlaceOrdreImpl(
        membreId: null == membreId
            ? _value.membreId
            : membreId // ignore: cast_nullable_to_non_nullable
                  as String,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as int,
        zone: freezed == zone
            ? _value.zone
            : zone // ignore: cast_nullable_to_non_nullable
                  as String?,
        placeSouhaitee: freezed == placeSouhaitee
            ? _value.placeSouhaitee
            : placeSouhaitee // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaceOrdreImpl implements _PlaceOrdre {
  const _$PlaceOrdreImpl({
    required this.membreId,
    required this.position,
    this.zone,
    this.placeSouhaitee,
  });

  factory _$PlaceOrdreImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaceOrdreImplFromJson(json);

  @override
  final String membreId;
  @override
  final int position;
  @override
  final String? zone;
  @override
  final int? placeSouhaitee;

  @override
  String toString() {
    return 'PlaceOrdre(membreId: $membreId, position: $position, zone: $zone, placeSouhaitee: $placeSouhaitee)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaceOrdreImpl &&
            (identical(other.membreId, membreId) ||
                other.membreId == membreId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.zone, zone) || other.zone == zone) &&
            (identical(other.placeSouhaitee, placeSouhaitee) ||
                other.placeSouhaitee == placeSouhaitee));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, membreId, position, zone, placeSouhaitee);

  /// Create a copy of PlaceOrdre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaceOrdreImplCopyWith<_$PlaceOrdreImpl> get copyWith =>
      __$$PlaceOrdreImplCopyWithImpl<_$PlaceOrdreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaceOrdreImplToJson(this);
  }
}

abstract class _PlaceOrdre implements PlaceOrdre {
  const factory _PlaceOrdre({
    required final String membreId,
    required final int position,
    final String? zone,
    final int? placeSouhaitee,
  }) = _$PlaceOrdreImpl;

  factory _PlaceOrdre.fromJson(Map<String, dynamic> json) =
      _$PlaceOrdreImpl.fromJson;

  @override
  String get membreId;
  @override
  int get position;
  @override
  String? get zone;
  @override
  int? get placeSouhaitee;

  /// Create a copy of PlaceOrdre
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaceOrdreImplCopyWith<_$PlaceOrdreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Cercle _$CercleFromJson(Map<String, dynamic> json) {
  return _Cercle.fromJson(json);
}

/// @nodoc
mixin _$Cercle {
  String get id => throw _privateConstructorUsedError;
  String? get organisateurId => throw _privateConstructorUsedError;
  Reglement get reglement => throw _privateConstructorUsedError;
  String? get empreinteReglement => throw _privateConstructorUsedError;
  List<String> get membres => throw _privateConstructorUsedError;
  List<String>? get partis => throw _privateConstructorUsedError;
  String get statut =>
      throw _privateConstructorUsedError; // en_attente, complet, termine
  List<PlaceOrdre>? get ordre => throw _privateConstructorUsedError;
  String? get termineLe => throw _privateConstructorUsedError;
  int? get placesRestantes => throw _privateConstructorUsedError;
  int? get premierePlaceAutorisee => throw _privateConstructorUsedError;
  bool? get scoreSuffisant => throw _privateConstructorUsedError;

  /// Serializes this Cercle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Cercle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CercleCopyWith<Cercle> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CercleCopyWith<$Res> {
  factory $CercleCopyWith(Cercle value, $Res Function(Cercle) then) =
      _$CercleCopyWithImpl<$Res, Cercle>;
  @useResult
  $Res call({
    String id,
    String? organisateurId,
    Reglement reglement,
    String? empreinteReglement,
    List<String> membres,
    List<String>? partis,
    String statut,
    List<PlaceOrdre>? ordre,
    String? termineLe,
    int? placesRestantes,
    int? premierePlaceAutorisee,
    bool? scoreSuffisant,
  });

  $ReglementCopyWith<$Res> get reglement;
}

/// @nodoc
class _$CercleCopyWithImpl<$Res, $Val extends Cercle>
    implements $CercleCopyWith<$Res> {
  _$CercleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Cercle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? organisateurId = freezed,
    Object? reglement = null,
    Object? empreinteReglement = freezed,
    Object? membres = null,
    Object? partis = freezed,
    Object? statut = null,
    Object? ordre = freezed,
    Object? termineLe = freezed,
    Object? placesRestantes = freezed,
    Object? premierePlaceAutorisee = freezed,
    Object? scoreSuffisant = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            organisateurId: freezed == organisateurId
                ? _value.organisateurId
                : organisateurId // ignore: cast_nullable_to_non_nullable
                      as String?,
            reglement: null == reglement
                ? _value.reglement
                : reglement // ignore: cast_nullable_to_non_nullable
                      as Reglement,
            empreinteReglement: freezed == empreinteReglement
                ? _value.empreinteReglement
                : empreinteReglement // ignore: cast_nullable_to_non_nullable
                      as String?,
            membres: null == membres
                ? _value.membres
                : membres // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            partis: freezed == partis
                ? _value.partis
                : partis // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            statut: null == statut
                ? _value.statut
                : statut // ignore: cast_nullable_to_non_nullable
                      as String,
            ordre: freezed == ordre
                ? _value.ordre
                : ordre // ignore: cast_nullable_to_non_nullable
                      as List<PlaceOrdre>?,
            termineLe: freezed == termineLe
                ? _value.termineLe
                : termineLe // ignore: cast_nullable_to_non_nullable
                      as String?,
            placesRestantes: freezed == placesRestantes
                ? _value.placesRestantes
                : placesRestantes // ignore: cast_nullable_to_non_nullable
                      as int?,
            premierePlaceAutorisee: freezed == premierePlaceAutorisee
                ? _value.premierePlaceAutorisee
                : premierePlaceAutorisee // ignore: cast_nullable_to_non_nullable
                      as int?,
            scoreSuffisant: freezed == scoreSuffisant
                ? _value.scoreSuffisant
                : scoreSuffisant // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }

  /// Create a copy of Cercle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReglementCopyWith<$Res> get reglement {
    return $ReglementCopyWith<$Res>(_value.reglement, (value) {
      return _then(_value.copyWith(reglement: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CercleImplCopyWith<$Res> implements $CercleCopyWith<$Res> {
  factory _$$CercleImplCopyWith(
    _$CercleImpl value,
    $Res Function(_$CercleImpl) then,
  ) = __$$CercleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? organisateurId,
    Reglement reglement,
    String? empreinteReglement,
    List<String> membres,
    List<String>? partis,
    String statut,
    List<PlaceOrdre>? ordre,
    String? termineLe,
    int? placesRestantes,
    int? premierePlaceAutorisee,
    bool? scoreSuffisant,
  });

  @override
  $ReglementCopyWith<$Res> get reglement;
}

/// @nodoc
class __$$CercleImplCopyWithImpl<$Res>
    extends _$CercleCopyWithImpl<$Res, _$CercleImpl>
    implements _$$CercleImplCopyWith<$Res> {
  __$$CercleImplCopyWithImpl(
    _$CercleImpl _value,
    $Res Function(_$CercleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Cercle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? organisateurId = freezed,
    Object? reglement = null,
    Object? empreinteReglement = freezed,
    Object? membres = null,
    Object? partis = freezed,
    Object? statut = null,
    Object? ordre = freezed,
    Object? termineLe = freezed,
    Object? placesRestantes = freezed,
    Object? premierePlaceAutorisee = freezed,
    Object? scoreSuffisant = freezed,
  }) {
    return _then(
      _$CercleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        organisateurId: freezed == organisateurId
            ? _value.organisateurId
            : organisateurId // ignore: cast_nullable_to_non_nullable
                  as String?,
        reglement: null == reglement
            ? _value.reglement
            : reglement // ignore: cast_nullable_to_non_nullable
                  as Reglement,
        empreinteReglement: freezed == empreinteReglement
            ? _value.empreinteReglement
            : empreinteReglement // ignore: cast_nullable_to_non_nullable
                  as String?,
        membres: null == membres
            ? _value._membres
            : membres // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        partis: freezed == partis
            ? _value._partis
            : partis // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        statut: null == statut
            ? _value.statut
            : statut // ignore: cast_nullable_to_non_nullable
                  as String,
        ordre: freezed == ordre
            ? _value._ordre
            : ordre // ignore: cast_nullable_to_non_nullable
                  as List<PlaceOrdre>?,
        termineLe: freezed == termineLe
            ? _value.termineLe
            : termineLe // ignore: cast_nullable_to_non_nullable
                  as String?,
        placesRestantes: freezed == placesRestantes
            ? _value.placesRestantes
            : placesRestantes // ignore: cast_nullable_to_non_nullable
                  as int?,
        premierePlaceAutorisee: freezed == premierePlaceAutorisee
            ? _value.premierePlaceAutorisee
            : premierePlaceAutorisee // ignore: cast_nullable_to_non_nullable
                  as int?,
        scoreSuffisant: freezed == scoreSuffisant
            ? _value.scoreSuffisant
            : scoreSuffisant // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CercleImpl extends _Cercle {
  const _$CercleImpl({
    required this.id,
    this.organisateurId,
    required this.reglement,
    this.empreinteReglement,
    final List<String> membres = const <String>[],
    final List<String>? partis,
    required this.statut,
    final List<PlaceOrdre>? ordre,
    this.termineLe,
    this.placesRestantes,
    this.premierePlaceAutorisee,
    this.scoreSuffisant,
  }) : _membres = membres,
       _partis = partis,
       _ordre = ordre,
       super._();

  factory _$CercleImpl.fromJson(Map<String, dynamic> json) =>
      _$$CercleImplFromJson(json);

  @override
  final String id;
  @override
  final String? organisateurId;
  @override
  final Reglement reglement;
  @override
  final String? empreinteReglement;
  final List<String> _membres;
  @override
  @JsonKey()
  List<String> get membres {
    if (_membres is EqualUnmodifiableListView) return _membres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_membres);
  }

  final List<String>? _partis;
  @override
  List<String>? get partis {
    final value = _partis;
    if (value == null) return null;
    if (_partis is EqualUnmodifiableListView) return _partis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String statut;
  // en_attente, complet, termine
  final List<PlaceOrdre>? _ordre;
  // en_attente, complet, termine
  @override
  List<PlaceOrdre>? get ordre {
    final value = _ordre;
    if (value == null) return null;
    if (_ordre is EqualUnmodifiableListView) return _ordre;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? termineLe;
  @override
  final int? placesRestantes;
  @override
  final int? premierePlaceAutorisee;
  @override
  final bool? scoreSuffisant;

  @override
  String toString() {
    return 'Cercle(id: $id, organisateurId: $organisateurId, reglement: $reglement, empreinteReglement: $empreinteReglement, membres: $membres, partis: $partis, statut: $statut, ordre: $ordre, termineLe: $termineLe, placesRestantes: $placesRestantes, premierePlaceAutorisee: $premierePlaceAutorisee, scoreSuffisant: $scoreSuffisant)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CercleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.organisateurId, organisateurId) ||
                other.organisateurId == organisateurId) &&
            (identical(other.reglement, reglement) ||
                other.reglement == reglement) &&
            (identical(other.empreinteReglement, empreinteReglement) ||
                other.empreinteReglement == empreinteReglement) &&
            const DeepCollectionEquality().equals(other._membres, _membres) &&
            const DeepCollectionEquality().equals(other._partis, _partis) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            const DeepCollectionEquality().equals(other._ordre, _ordre) &&
            (identical(other.termineLe, termineLe) ||
                other.termineLe == termineLe) &&
            (identical(other.placesRestantes, placesRestantes) ||
                other.placesRestantes == placesRestantes) &&
            (identical(other.premierePlaceAutorisee, premierePlaceAutorisee) ||
                other.premierePlaceAutorisee == premierePlaceAutorisee) &&
            (identical(other.scoreSuffisant, scoreSuffisant) ||
                other.scoreSuffisant == scoreSuffisant));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    organisateurId,
    reglement,
    empreinteReglement,
    const DeepCollectionEquality().hash(_membres),
    const DeepCollectionEquality().hash(_partis),
    statut,
    const DeepCollectionEquality().hash(_ordre),
    termineLe,
    placesRestantes,
    premierePlaceAutorisee,
    scoreSuffisant,
  );

  /// Create a copy of Cercle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CercleImplCopyWith<_$CercleImpl> get copyWith =>
      __$$CercleImplCopyWithImpl<_$CercleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CercleImplToJson(this);
  }
}

abstract class _Cercle extends Cercle {
  const factory _Cercle({
    required final String id,
    final String? organisateurId,
    required final Reglement reglement,
    final String? empreinteReglement,
    final List<String> membres,
    final List<String>? partis,
    required final String statut,
    final List<PlaceOrdre>? ordre,
    final String? termineLe,
    final int? placesRestantes,
    final int? premierePlaceAutorisee,
    final bool? scoreSuffisant,
  }) = _$CercleImpl;
  const _Cercle._() : super._();

  factory _Cercle.fromJson(Map<String, dynamic> json) = _$CercleImpl.fromJson;

  @override
  String get id;
  @override
  String? get organisateurId;
  @override
  Reglement get reglement;
  @override
  String? get empreinteReglement;
  @override
  List<String> get membres;
  @override
  List<String>? get partis;
  @override
  String get statut; // en_attente, complet, termine
  @override
  List<PlaceOrdre>? get ordre;
  @override
  String? get termineLe;
  @override
  int? get placesRestantes;
  @override
  int? get premierePlaceAutorisee;
  @override
  bool? get scoreSuffisant;

  /// Create a copy of Cercle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CercleImplCopyWith<_$CercleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ResumeCercle _$ResumeCercleFromJson(Map<String, dynamic> json) {
  return _ResumeCercle.fromJson(json);
}

/// @nodoc
mixin _$ResumeCercle {
  String get id => throw _privateConstructorUsedError;
  bool get organisateur => throw _privateConstructorUsedError;
  Reglement get reglement => throw _privateConstructorUsedError;
  String get statut => throw _privateConstructorUsedError;
  int get nombreInscrits => throw _privateConstructorUsedError;
  int? get maPlace => throw _privateConstructorUsedError;

  /// Serializes this ResumeCercle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ResumeCercle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResumeCercleCopyWith<ResumeCercle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResumeCercleCopyWith<$Res> {
  factory $ResumeCercleCopyWith(
    ResumeCercle value,
    $Res Function(ResumeCercle) then,
  ) = _$ResumeCercleCopyWithImpl<$Res, ResumeCercle>;
  @useResult
  $Res call({
    String id,
    bool organisateur,
    Reglement reglement,
    String statut,
    int nombreInscrits,
    int? maPlace,
  });

  $ReglementCopyWith<$Res> get reglement;
}

/// @nodoc
class _$ResumeCercleCopyWithImpl<$Res, $Val extends ResumeCercle>
    implements $ResumeCercleCopyWith<$Res> {
  _$ResumeCercleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ResumeCercle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? organisateur = null,
    Object? reglement = null,
    Object? statut = null,
    Object? nombreInscrits = null,
    Object? maPlace = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            organisateur: null == organisateur
                ? _value.organisateur
                : organisateur // ignore: cast_nullable_to_non_nullable
                      as bool,
            reglement: null == reglement
                ? _value.reglement
                : reglement // ignore: cast_nullable_to_non_nullable
                      as Reglement,
            statut: null == statut
                ? _value.statut
                : statut // ignore: cast_nullable_to_non_nullable
                      as String,
            nombreInscrits: null == nombreInscrits
                ? _value.nombreInscrits
                : nombreInscrits // ignore: cast_nullable_to_non_nullable
                      as int,
            maPlace: freezed == maPlace
                ? _value.maPlace
                : maPlace // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }

  /// Create a copy of ResumeCercle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReglementCopyWith<$Res> get reglement {
    return $ReglementCopyWith<$Res>(_value.reglement, (value) {
      return _then(_value.copyWith(reglement: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ResumeCercleImplCopyWith<$Res>
    implements $ResumeCercleCopyWith<$Res> {
  factory _$$ResumeCercleImplCopyWith(
    _$ResumeCercleImpl value,
    $Res Function(_$ResumeCercleImpl) then,
  ) = __$$ResumeCercleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    bool organisateur,
    Reglement reglement,
    String statut,
    int nombreInscrits,
    int? maPlace,
  });

  @override
  $ReglementCopyWith<$Res> get reglement;
}

/// @nodoc
class __$$ResumeCercleImplCopyWithImpl<$Res>
    extends _$ResumeCercleCopyWithImpl<$Res, _$ResumeCercleImpl>
    implements _$$ResumeCercleImplCopyWith<$Res> {
  __$$ResumeCercleImplCopyWithImpl(
    _$ResumeCercleImpl _value,
    $Res Function(_$ResumeCercleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ResumeCercle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? organisateur = null,
    Object? reglement = null,
    Object? statut = null,
    Object? nombreInscrits = null,
    Object? maPlace = freezed,
  }) {
    return _then(
      _$ResumeCercleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        organisateur: null == organisateur
            ? _value.organisateur
            : organisateur // ignore: cast_nullable_to_non_nullable
                  as bool,
        reglement: null == reglement
            ? _value.reglement
            : reglement // ignore: cast_nullable_to_non_nullable
                  as Reglement,
        statut: null == statut
            ? _value.statut
            : statut // ignore: cast_nullable_to_non_nullable
                  as String,
        nombreInscrits: null == nombreInscrits
            ? _value.nombreInscrits
            : nombreInscrits // ignore: cast_nullable_to_non_nullable
                  as int,
        maPlace: freezed == maPlace
            ? _value.maPlace
            : maPlace // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ResumeCercleImpl extends _ResumeCercle {
  const _$ResumeCercleImpl({
    required this.id,
    this.organisateur = false,
    required this.reglement,
    required this.statut,
    this.nombreInscrits = 0,
    this.maPlace,
  }) : super._();

  factory _$ResumeCercleImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResumeCercleImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final bool organisateur;
  @override
  final Reglement reglement;
  @override
  final String statut;
  @override
  @JsonKey()
  final int nombreInscrits;
  @override
  final int? maPlace;

  @override
  String toString() {
    return 'ResumeCercle(id: $id, organisateur: $organisateur, reglement: $reglement, statut: $statut, nombreInscrits: $nombreInscrits, maPlace: $maPlace)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResumeCercleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.organisateur, organisateur) ||
                other.organisateur == organisateur) &&
            (identical(other.reglement, reglement) ||
                other.reglement == reglement) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.nombreInscrits, nombreInscrits) ||
                other.nombreInscrits == nombreInscrits) &&
            (identical(other.maPlace, maPlace) || other.maPlace == maPlace));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    organisateur,
    reglement,
    statut,
    nombreInscrits,
    maPlace,
  );

  /// Create a copy of ResumeCercle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResumeCercleImplCopyWith<_$ResumeCercleImpl> get copyWith =>
      __$$ResumeCercleImplCopyWithImpl<_$ResumeCercleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ResumeCercleImplToJson(this);
  }
}

abstract class _ResumeCercle extends ResumeCercle {
  const factory _ResumeCercle({
    required final String id,
    final bool organisateur,
    required final Reglement reglement,
    required final String statut,
    final int nombreInscrits,
    final int? maPlace,
  }) = _$ResumeCercleImpl;
  const _ResumeCercle._() : super._();

  factory _ResumeCercle.fromJson(Map<String, dynamic> json) =
      _$ResumeCercleImpl.fromJson;

  @override
  String get id;
  @override
  bool get organisateur;
  @override
  Reglement get reglement;
  @override
  String get statut;
  @override
  int get nombreInscrits;
  @override
  int? get maPlace;

  /// Create a copy of ResumeCercle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResumeCercleImplCopyWith<_$ResumeCercleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Cotisation _$CotisationFromJson(Map<String, dynamic> json) {
  return _Cotisation.fromJson(json);
}

/// @nodoc
mixin _$Cotisation {
  String get id => throw _privateConstructorUsedError;
  String get cercleId => throw _privateConstructorUsedError;
  String get payeurId => throw _privateConstructorUsedError;
  String get beneficiaireId => throw _privateConstructorUsedError;
  int get montant => throw _privateConstructorUsedError;
  int get tour => throw _privateConstructorUsedError;
  String get dateLimite => throw _privateConstructorUsedError;
  String? get finGrace => throw _privateConstructorUsedError;
  String get statut =>
      throw _privateConstructorUsedError; // due, declaree, confirmee
  String? get referenceTransaction => throw _privateConstructorUsedError;
  String? get declareeLe => throw _privateConstructorUsedError;
  String? get confirmeeLe => throw _privateConstructorUsedError;
  bool get enLitige => throw _privateConstructorUsedError;
  int get penalite => throw _privateConstructorUsedError;
  int get penaliteDue => throw _privateConstructorUsedError;

  /// Serializes this Cotisation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Cotisation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CotisationCopyWith<Cotisation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CotisationCopyWith<$Res> {
  factory $CotisationCopyWith(
    Cotisation value,
    $Res Function(Cotisation) then,
  ) = _$CotisationCopyWithImpl<$Res, Cotisation>;
  @useResult
  $Res call({
    String id,
    String cercleId,
    String payeurId,
    String beneficiaireId,
    int montant,
    int tour,
    String dateLimite,
    String? finGrace,
    String statut,
    String? referenceTransaction,
    String? declareeLe,
    String? confirmeeLe,
    bool enLitige,
    int penalite,
    int penaliteDue,
  });
}

/// @nodoc
class _$CotisationCopyWithImpl<$Res, $Val extends Cotisation>
    implements $CotisationCopyWith<$Res> {
  _$CotisationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Cotisation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cercleId = null,
    Object? payeurId = null,
    Object? beneficiaireId = null,
    Object? montant = null,
    Object? tour = null,
    Object? dateLimite = null,
    Object? finGrace = freezed,
    Object? statut = null,
    Object? referenceTransaction = freezed,
    Object? declareeLe = freezed,
    Object? confirmeeLe = freezed,
    Object? enLitige = null,
    Object? penalite = null,
    Object? penaliteDue = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            cercleId: null == cercleId
                ? _value.cercleId
                : cercleId // ignore: cast_nullable_to_non_nullable
                      as String,
            payeurId: null == payeurId
                ? _value.payeurId
                : payeurId // ignore: cast_nullable_to_non_nullable
                      as String,
            beneficiaireId: null == beneficiaireId
                ? _value.beneficiaireId
                : beneficiaireId // ignore: cast_nullable_to_non_nullable
                      as String,
            montant: null == montant
                ? _value.montant
                : montant // ignore: cast_nullable_to_non_nullable
                      as int,
            tour: null == tour
                ? _value.tour
                : tour // ignore: cast_nullable_to_non_nullable
                      as int,
            dateLimite: null == dateLimite
                ? _value.dateLimite
                : dateLimite // ignore: cast_nullable_to_non_nullable
                      as String,
            finGrace: freezed == finGrace
                ? _value.finGrace
                : finGrace // ignore: cast_nullable_to_non_nullable
                      as String?,
            statut: null == statut
                ? _value.statut
                : statut // ignore: cast_nullable_to_non_nullable
                      as String,
            referenceTransaction: freezed == referenceTransaction
                ? _value.referenceTransaction
                : referenceTransaction // ignore: cast_nullable_to_non_nullable
                      as String?,
            declareeLe: freezed == declareeLe
                ? _value.declareeLe
                : declareeLe // ignore: cast_nullable_to_non_nullable
                      as String?,
            confirmeeLe: freezed == confirmeeLe
                ? _value.confirmeeLe
                : confirmeeLe // ignore: cast_nullable_to_non_nullable
                      as String?,
            enLitige: null == enLitige
                ? _value.enLitige
                : enLitige // ignore: cast_nullable_to_non_nullable
                      as bool,
            penalite: null == penalite
                ? _value.penalite
                : penalite // ignore: cast_nullable_to_non_nullable
                      as int,
            penaliteDue: null == penaliteDue
                ? _value.penaliteDue
                : penaliteDue // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CotisationImplCopyWith<$Res>
    implements $CotisationCopyWith<$Res> {
  factory _$$CotisationImplCopyWith(
    _$CotisationImpl value,
    $Res Function(_$CotisationImpl) then,
  ) = __$$CotisationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String cercleId,
    String payeurId,
    String beneficiaireId,
    int montant,
    int tour,
    String dateLimite,
    String? finGrace,
    String statut,
    String? referenceTransaction,
    String? declareeLe,
    String? confirmeeLe,
    bool enLitige,
    int penalite,
    int penaliteDue,
  });
}

/// @nodoc
class __$$CotisationImplCopyWithImpl<$Res>
    extends _$CotisationCopyWithImpl<$Res, _$CotisationImpl>
    implements _$$CotisationImplCopyWith<$Res> {
  __$$CotisationImplCopyWithImpl(
    _$CotisationImpl _value,
    $Res Function(_$CotisationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Cotisation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cercleId = null,
    Object? payeurId = null,
    Object? beneficiaireId = null,
    Object? montant = null,
    Object? tour = null,
    Object? dateLimite = null,
    Object? finGrace = freezed,
    Object? statut = null,
    Object? referenceTransaction = freezed,
    Object? declareeLe = freezed,
    Object? confirmeeLe = freezed,
    Object? enLitige = null,
    Object? penalite = null,
    Object? penaliteDue = null,
  }) {
    return _then(
      _$CotisationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        cercleId: null == cercleId
            ? _value.cercleId
            : cercleId // ignore: cast_nullable_to_non_nullable
                  as String,
        payeurId: null == payeurId
            ? _value.payeurId
            : payeurId // ignore: cast_nullable_to_non_nullable
                  as String,
        beneficiaireId: null == beneficiaireId
            ? _value.beneficiaireId
            : beneficiaireId // ignore: cast_nullable_to_non_nullable
                  as String,
        montant: null == montant
            ? _value.montant
            : montant // ignore: cast_nullable_to_non_nullable
                  as int,
        tour: null == tour
            ? _value.tour
            : tour // ignore: cast_nullable_to_non_nullable
                  as int,
        dateLimite: null == dateLimite
            ? _value.dateLimite
            : dateLimite // ignore: cast_nullable_to_non_nullable
                  as String,
        finGrace: freezed == finGrace
            ? _value.finGrace
            : finGrace // ignore: cast_nullable_to_non_nullable
                  as String?,
        statut: null == statut
            ? _value.statut
            : statut // ignore: cast_nullable_to_non_nullable
                  as String,
        referenceTransaction: freezed == referenceTransaction
            ? _value.referenceTransaction
            : referenceTransaction // ignore: cast_nullable_to_non_nullable
                  as String?,
        declareeLe: freezed == declareeLe
            ? _value.declareeLe
            : declareeLe // ignore: cast_nullable_to_non_nullable
                  as String?,
        confirmeeLe: freezed == confirmeeLe
            ? _value.confirmeeLe
            : confirmeeLe // ignore: cast_nullable_to_non_nullable
                  as String?,
        enLitige: null == enLitige
            ? _value.enLitige
            : enLitige // ignore: cast_nullable_to_non_nullable
                  as bool,
        penalite: null == penalite
            ? _value.penalite
            : penalite // ignore: cast_nullable_to_non_nullable
                  as int,
        penaliteDue: null == penaliteDue
            ? _value.penaliteDue
            : penaliteDue // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CotisationImpl extends _Cotisation {
  const _$CotisationImpl({
    required this.id,
    required this.cercleId,
    required this.payeurId,
    required this.beneficiaireId,
    required this.montant,
    required this.tour,
    required this.dateLimite,
    this.finGrace,
    required this.statut,
    this.referenceTransaction,
    this.declareeLe,
    this.confirmeeLe,
    this.enLitige = false,
    this.penalite = 0,
    this.penaliteDue = 0,
  }) : super._();

  factory _$CotisationImpl.fromJson(Map<String, dynamic> json) =>
      _$$CotisationImplFromJson(json);

  @override
  final String id;
  @override
  final String cercleId;
  @override
  final String payeurId;
  @override
  final String beneficiaireId;
  @override
  final int montant;
  @override
  final int tour;
  @override
  final String dateLimite;
  @override
  final String? finGrace;
  @override
  final String statut;
  // due, declaree, confirmee
  @override
  final String? referenceTransaction;
  @override
  final String? declareeLe;
  @override
  final String? confirmeeLe;
  @override
  @JsonKey()
  final bool enLitige;
  @override
  @JsonKey()
  final int penalite;
  @override
  @JsonKey()
  final int penaliteDue;

  @override
  String toString() {
    return 'Cotisation(id: $id, cercleId: $cercleId, payeurId: $payeurId, beneficiaireId: $beneficiaireId, montant: $montant, tour: $tour, dateLimite: $dateLimite, finGrace: $finGrace, statut: $statut, referenceTransaction: $referenceTransaction, declareeLe: $declareeLe, confirmeeLe: $confirmeeLe, enLitige: $enLitige, penalite: $penalite, penaliteDue: $penaliteDue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CotisationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cercleId, cercleId) ||
                other.cercleId == cercleId) &&
            (identical(other.payeurId, payeurId) ||
                other.payeurId == payeurId) &&
            (identical(other.beneficiaireId, beneficiaireId) ||
                other.beneficiaireId == beneficiaireId) &&
            (identical(other.montant, montant) || other.montant == montant) &&
            (identical(other.tour, tour) || other.tour == tour) &&
            (identical(other.dateLimite, dateLimite) ||
                other.dateLimite == dateLimite) &&
            (identical(other.finGrace, finGrace) ||
                other.finGrace == finGrace) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.referenceTransaction, referenceTransaction) ||
                other.referenceTransaction == referenceTransaction) &&
            (identical(other.declareeLe, declareeLe) ||
                other.declareeLe == declareeLe) &&
            (identical(other.confirmeeLe, confirmeeLe) ||
                other.confirmeeLe == confirmeeLe) &&
            (identical(other.enLitige, enLitige) ||
                other.enLitige == enLitige) &&
            (identical(other.penalite, penalite) ||
                other.penalite == penalite) &&
            (identical(other.penaliteDue, penaliteDue) ||
                other.penaliteDue == penaliteDue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    cercleId,
    payeurId,
    beneficiaireId,
    montant,
    tour,
    dateLimite,
    finGrace,
    statut,
    referenceTransaction,
    declareeLe,
    confirmeeLe,
    enLitige,
    penalite,
    penaliteDue,
  );

  /// Create a copy of Cotisation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CotisationImplCopyWith<_$CotisationImpl> get copyWith =>
      __$$CotisationImplCopyWithImpl<_$CotisationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CotisationImplToJson(this);
  }
}

abstract class _Cotisation extends Cotisation {
  const factory _Cotisation({
    required final String id,
    required final String cercleId,
    required final String payeurId,
    required final String beneficiaireId,
    required final int montant,
    required final int tour,
    required final String dateLimite,
    final String? finGrace,
    required final String statut,
    final String? referenceTransaction,
    final String? declareeLe,
    final String? confirmeeLe,
    final bool enLitige,
    final int penalite,
    final int penaliteDue,
  }) = _$CotisationImpl;
  const _Cotisation._() : super._();

  factory _Cotisation.fromJson(Map<String, dynamic> json) =
      _$CotisationImpl.fromJson;

  @override
  String get id;
  @override
  String get cercleId;
  @override
  String get payeurId;
  @override
  String get beneficiaireId;
  @override
  int get montant;
  @override
  int get tour;
  @override
  String get dateLimite;
  @override
  String? get finGrace;
  @override
  String get statut; // due, declaree, confirmee
  @override
  String? get referenceTransaction;
  @override
  String? get declareeLe;
  @override
  String? get confirmeeLe;
  @override
  bool get enLitige;
  @override
  int get penalite;
  @override
  int get penaliteDue;

  /// Create a copy of Cotisation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CotisationImplCopyWith<_$CotisationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EtatCotisations _$EtatCotisationsFromJson(Map<String, dynamic> json) {
  return _EtatCotisations.fromJson(json);
}

/// @nodoc
mixin _$EtatCotisations {
  String get cercleId => throw _privateConstructorUsedError;
  List<EtatTour> get tours => throw _privateConstructorUsedError;

  /// Serializes this EtatCotisations to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EtatCotisations
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EtatCotisationsCopyWith<EtatCotisations> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EtatCotisationsCopyWith<$Res> {
  factory $EtatCotisationsCopyWith(
    EtatCotisations value,
    $Res Function(EtatCotisations) then,
  ) = _$EtatCotisationsCopyWithImpl<$Res, EtatCotisations>;
  @useResult
  $Res call({String cercleId, List<EtatTour> tours});
}

/// @nodoc
class _$EtatCotisationsCopyWithImpl<$Res, $Val extends EtatCotisations>
    implements $EtatCotisationsCopyWith<$Res> {
  _$EtatCotisationsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EtatCotisations
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? cercleId = null, Object? tours = null}) {
    return _then(
      _value.copyWith(
            cercleId: null == cercleId
                ? _value.cercleId
                : cercleId // ignore: cast_nullable_to_non_nullable
                      as String,
            tours: null == tours
                ? _value.tours
                : tours // ignore: cast_nullable_to_non_nullable
                      as List<EtatTour>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EtatCotisationsImplCopyWith<$Res>
    implements $EtatCotisationsCopyWith<$Res> {
  factory _$$EtatCotisationsImplCopyWith(
    _$EtatCotisationsImpl value,
    $Res Function(_$EtatCotisationsImpl) then,
  ) = __$$EtatCotisationsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String cercleId, List<EtatTour> tours});
}

/// @nodoc
class __$$EtatCotisationsImplCopyWithImpl<$Res>
    extends _$EtatCotisationsCopyWithImpl<$Res, _$EtatCotisationsImpl>
    implements _$$EtatCotisationsImplCopyWith<$Res> {
  __$$EtatCotisationsImplCopyWithImpl(
    _$EtatCotisationsImpl _value,
    $Res Function(_$EtatCotisationsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EtatCotisations
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? cercleId = null, Object? tours = null}) {
    return _then(
      _$EtatCotisationsImpl(
        cercleId: null == cercleId
            ? _value.cercleId
            : cercleId // ignore: cast_nullable_to_non_nullable
                  as String,
        tours: null == tours
            ? _value._tours
            : tours // ignore: cast_nullable_to_non_nullable
                  as List<EtatTour>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EtatCotisationsImpl implements _EtatCotisations {
  const _$EtatCotisationsImpl({
    required this.cercleId,
    required final List<EtatTour> tours,
  }) : _tours = tours;

  factory _$EtatCotisationsImpl.fromJson(Map<String, dynamic> json) =>
      _$$EtatCotisationsImplFromJson(json);

  @override
  final String cercleId;
  final List<EtatTour> _tours;
  @override
  List<EtatTour> get tours {
    if (_tours is EqualUnmodifiableListView) return _tours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tours);
  }

  @override
  String toString() {
    return 'EtatCotisations(cercleId: $cercleId, tours: $tours)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EtatCotisationsImpl &&
            (identical(other.cercleId, cercleId) ||
                other.cercleId == cercleId) &&
            const DeepCollectionEquality().equals(other._tours, _tours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    cercleId,
    const DeepCollectionEquality().hash(_tours),
  );

  /// Create a copy of EtatCotisations
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EtatCotisationsImplCopyWith<_$EtatCotisationsImpl> get copyWith =>
      __$$EtatCotisationsImplCopyWithImpl<_$EtatCotisationsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EtatCotisationsImplToJson(this);
  }
}

abstract class _EtatCotisations implements EtatCotisations {
  const factory _EtatCotisations({
    required final String cercleId,
    required final List<EtatTour> tours,
  }) = _$EtatCotisationsImpl;

  factory _EtatCotisations.fromJson(Map<String, dynamic> json) =
      _$EtatCotisationsImpl.fromJson;

  @override
  String get cercleId;
  @override
  List<EtatTour> get tours;

  /// Create a copy of EtatCotisations
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EtatCotisationsImplCopyWith<_$EtatCotisationsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EtatTour _$EtatTourFromJson(Map<String, dynamic> json) {
  return _EtatTour.fromJson(json);
}

/// @nodoc
mixin _$EtatTour {
  int get numero => throw _privateConstructorUsedError;
  String get beneficiaireId => throw _privateConstructorUsedError;
  String? get dateLimite => throw _privateConstructorUsedError;
  List<EtatMembre> get paiements => throw _privateConstructorUsedError;

  /// Serializes this EtatTour to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EtatTour
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EtatTourCopyWith<EtatTour> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EtatTourCopyWith<$Res> {
  factory $EtatTourCopyWith(EtatTour value, $Res Function(EtatTour) then) =
      _$EtatTourCopyWithImpl<$Res, EtatTour>;
  @useResult
  $Res call({
    int numero,
    String beneficiaireId,
    String? dateLimite,
    List<EtatMembre> paiements,
  });
}

/// @nodoc
class _$EtatTourCopyWithImpl<$Res, $Val extends EtatTour>
    implements $EtatTourCopyWith<$Res> {
  _$EtatTourCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EtatTour
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? numero = null,
    Object? beneficiaireId = null,
    Object? dateLimite = freezed,
    Object? paiements = null,
  }) {
    return _then(
      _value.copyWith(
            numero: null == numero
                ? _value.numero
                : numero // ignore: cast_nullable_to_non_nullable
                      as int,
            beneficiaireId: null == beneficiaireId
                ? _value.beneficiaireId
                : beneficiaireId // ignore: cast_nullable_to_non_nullable
                      as String,
            dateLimite: freezed == dateLimite
                ? _value.dateLimite
                : dateLimite // ignore: cast_nullable_to_non_nullable
                      as String?,
            paiements: null == paiements
                ? _value.paiements
                : paiements // ignore: cast_nullable_to_non_nullable
                      as List<EtatMembre>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EtatTourImplCopyWith<$Res>
    implements $EtatTourCopyWith<$Res> {
  factory _$$EtatTourImplCopyWith(
    _$EtatTourImpl value,
    $Res Function(_$EtatTourImpl) then,
  ) = __$$EtatTourImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int numero,
    String beneficiaireId,
    String? dateLimite,
    List<EtatMembre> paiements,
  });
}

/// @nodoc
class __$$EtatTourImplCopyWithImpl<$Res>
    extends _$EtatTourCopyWithImpl<$Res, _$EtatTourImpl>
    implements _$$EtatTourImplCopyWith<$Res> {
  __$$EtatTourImplCopyWithImpl(
    _$EtatTourImpl _value,
    $Res Function(_$EtatTourImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EtatTour
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? numero = null,
    Object? beneficiaireId = null,
    Object? dateLimite = freezed,
    Object? paiements = null,
  }) {
    return _then(
      _$EtatTourImpl(
        numero: null == numero
            ? _value.numero
            : numero // ignore: cast_nullable_to_non_nullable
                  as int,
        beneficiaireId: null == beneficiaireId
            ? _value.beneficiaireId
            : beneficiaireId // ignore: cast_nullable_to_non_nullable
                  as String,
        dateLimite: freezed == dateLimite
            ? _value.dateLimite
            : dateLimite // ignore: cast_nullable_to_non_nullable
                  as String?,
        paiements: null == paiements
            ? _value._paiements
            : paiements // ignore: cast_nullable_to_non_nullable
                  as List<EtatMembre>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EtatTourImpl extends _EtatTour {
  const _$EtatTourImpl({
    required this.numero,
    required this.beneficiaireId,
    this.dateLimite,
    required final List<EtatMembre> paiements,
  }) : _paiements = paiements,
       super._();

  factory _$EtatTourImpl.fromJson(Map<String, dynamic> json) =>
      _$$EtatTourImplFromJson(json);

  @override
  final int numero;
  @override
  final String beneficiaireId;
  @override
  final String? dateLimite;
  final List<EtatMembre> _paiements;
  @override
  List<EtatMembre> get paiements {
    if (_paiements is EqualUnmodifiableListView) return _paiements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_paiements);
  }

  @override
  String toString() {
    return 'EtatTour(numero: $numero, beneficiaireId: $beneficiaireId, dateLimite: $dateLimite, paiements: $paiements)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EtatTourImpl &&
            (identical(other.numero, numero) || other.numero == numero) &&
            (identical(other.beneficiaireId, beneficiaireId) ||
                other.beneficiaireId == beneficiaireId) &&
            (identical(other.dateLimite, dateLimite) ||
                other.dateLimite == dateLimite) &&
            const DeepCollectionEquality().equals(
              other._paiements,
              _paiements,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    numero,
    beneficiaireId,
    dateLimite,
    const DeepCollectionEquality().hash(_paiements),
  );

  /// Create a copy of EtatTour
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EtatTourImplCopyWith<_$EtatTourImpl> get copyWith =>
      __$$EtatTourImplCopyWithImpl<_$EtatTourImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EtatTourImplToJson(this);
  }
}

abstract class _EtatTour extends EtatTour {
  const factory _EtatTour({
    required final int numero,
    required final String beneficiaireId,
    final String? dateLimite,
    required final List<EtatMembre> paiements,
  }) = _$EtatTourImpl;
  const _EtatTour._() : super._();

  factory _EtatTour.fromJson(Map<String, dynamic> json) =
      _$EtatTourImpl.fromJson;

  @override
  int get numero;
  @override
  String get beneficiaireId;
  @override
  String? get dateLimite;
  @override
  List<EtatMembre> get paiements;

  /// Create a copy of EtatTour
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EtatTourImplCopyWith<_$EtatTourImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EtatMembre _$EtatMembreFromJson(Map<String, dynamic> json) {
  return _EtatMembre.fromJson(json);
}

/// @nodoc
mixin _$EtatMembre {
  String get payeurId => throw _privateConstructorUsedError;
  int get montant => throw _privateConstructorUsedError;
  String get statut => throw _privateConstructorUsedError;
  bool get enRetard => throw _privateConstructorUsedError;
  bool get enLitige => throw _privateConstructorUsedError;
  int get penaliteDue => throw _privateConstructorUsedError;

  /// Serializes this EtatMembre to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EtatMembre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EtatMembreCopyWith<EtatMembre> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EtatMembreCopyWith<$Res> {
  factory $EtatMembreCopyWith(
    EtatMembre value,
    $Res Function(EtatMembre) then,
  ) = _$EtatMembreCopyWithImpl<$Res, EtatMembre>;
  @useResult
  $Res call({
    String payeurId,
    int montant,
    String statut,
    bool enRetard,
    bool enLitige,
    int penaliteDue,
  });
}

/// @nodoc
class _$EtatMembreCopyWithImpl<$Res, $Val extends EtatMembre>
    implements $EtatMembreCopyWith<$Res> {
  _$EtatMembreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EtatMembre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payeurId = null,
    Object? montant = null,
    Object? statut = null,
    Object? enRetard = null,
    Object? enLitige = null,
    Object? penaliteDue = null,
  }) {
    return _then(
      _value.copyWith(
            payeurId: null == payeurId
                ? _value.payeurId
                : payeurId // ignore: cast_nullable_to_non_nullable
                      as String,
            montant: null == montant
                ? _value.montant
                : montant // ignore: cast_nullable_to_non_nullable
                      as int,
            statut: null == statut
                ? _value.statut
                : statut // ignore: cast_nullable_to_non_nullable
                      as String,
            enRetard: null == enRetard
                ? _value.enRetard
                : enRetard // ignore: cast_nullable_to_non_nullable
                      as bool,
            enLitige: null == enLitige
                ? _value.enLitige
                : enLitige // ignore: cast_nullable_to_non_nullable
                      as bool,
            penaliteDue: null == penaliteDue
                ? _value.penaliteDue
                : penaliteDue // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EtatMembreImplCopyWith<$Res>
    implements $EtatMembreCopyWith<$Res> {
  factory _$$EtatMembreImplCopyWith(
    _$EtatMembreImpl value,
    $Res Function(_$EtatMembreImpl) then,
  ) = __$$EtatMembreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String payeurId,
    int montant,
    String statut,
    bool enRetard,
    bool enLitige,
    int penaliteDue,
  });
}

/// @nodoc
class __$$EtatMembreImplCopyWithImpl<$Res>
    extends _$EtatMembreCopyWithImpl<$Res, _$EtatMembreImpl>
    implements _$$EtatMembreImplCopyWith<$Res> {
  __$$EtatMembreImplCopyWithImpl(
    _$EtatMembreImpl _value,
    $Res Function(_$EtatMembreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EtatMembre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payeurId = null,
    Object? montant = null,
    Object? statut = null,
    Object? enRetard = null,
    Object? enLitige = null,
    Object? penaliteDue = null,
  }) {
    return _then(
      _$EtatMembreImpl(
        payeurId: null == payeurId
            ? _value.payeurId
            : payeurId // ignore: cast_nullable_to_non_nullable
                  as String,
        montant: null == montant
            ? _value.montant
            : montant // ignore: cast_nullable_to_non_nullable
                  as int,
        statut: null == statut
            ? _value.statut
            : statut // ignore: cast_nullable_to_non_nullable
                  as String,
        enRetard: null == enRetard
            ? _value.enRetard
            : enRetard // ignore: cast_nullable_to_non_nullable
                  as bool,
        enLitige: null == enLitige
            ? _value.enLitige
            : enLitige // ignore: cast_nullable_to_non_nullable
                  as bool,
        penaliteDue: null == penaliteDue
            ? _value.penaliteDue
            : penaliteDue // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EtatMembreImpl extends _EtatMembre {
  const _$EtatMembreImpl({
    required this.payeurId,
    required this.montant,
    required this.statut,
    this.enRetard = false,
    this.enLitige = false,
    this.penaliteDue = 0,
  }) : super._();

  factory _$EtatMembreImpl.fromJson(Map<String, dynamic> json) =>
      _$$EtatMembreImplFromJson(json);

  @override
  final String payeurId;
  @override
  final int montant;
  @override
  final String statut;
  @override
  @JsonKey()
  final bool enRetard;
  @override
  @JsonKey()
  final bool enLitige;
  @override
  @JsonKey()
  final int penaliteDue;

  @override
  String toString() {
    return 'EtatMembre(payeurId: $payeurId, montant: $montant, statut: $statut, enRetard: $enRetard, enLitige: $enLitige, penaliteDue: $penaliteDue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EtatMembreImpl &&
            (identical(other.payeurId, payeurId) ||
                other.payeurId == payeurId) &&
            (identical(other.montant, montant) || other.montant == montant) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.enRetard, enRetard) ||
                other.enRetard == enRetard) &&
            (identical(other.enLitige, enLitige) ||
                other.enLitige == enLitige) &&
            (identical(other.penaliteDue, penaliteDue) ||
                other.penaliteDue == penaliteDue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    payeurId,
    montant,
    statut,
    enRetard,
    enLitige,
    penaliteDue,
  );

  /// Create a copy of EtatMembre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EtatMembreImplCopyWith<_$EtatMembreImpl> get copyWith =>
      __$$EtatMembreImplCopyWithImpl<_$EtatMembreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EtatMembreImplToJson(this);
  }
}

abstract class _EtatMembre extends EtatMembre {
  const factory _EtatMembre({
    required final String payeurId,
    required final int montant,
    required final String statut,
    final bool enRetard,
    final bool enLitige,
    final int penaliteDue,
  }) = _$EtatMembreImpl;
  const _EtatMembre._() : super._();

  factory _EtatMembre.fromJson(Map<String, dynamic> json) =
      _$EtatMembreImpl.fromJson;

  @override
  String get payeurId;
  @override
  int get montant;
  @override
  String get statut;
  @override
  bool get enRetard;
  @override
  bool get enLitige;
  @override
  int get penaliteDue;

  /// Create a copy of EtatMembre
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EtatMembreImplCopyWith<_$EtatMembreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScoreMembre _$ScoreMembreFromJson(Map<String, dynamic> json) {
  return _ScoreMembre.fromJson(json);
}

/// @nodoc
mixin _$ScoreMembre {
  String get membreId => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  int get cyclesTermines => throw _privateConstructorUsedError;
  int get defauts => throw _privateConstructorUsedError;
  bool get premieresPlacesFermees => throw _privateConstructorUsedError;
  List<String> get explication => throw _privateConstructorUsedError;
  List<EvenementScore> get historique => throw _privateConstructorUsedError;

  /// Serializes this ScoreMembre to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScoreMembre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScoreMembreCopyWith<ScoreMembre> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScoreMembreCopyWith<$Res> {
  factory $ScoreMembreCopyWith(
    ScoreMembre value,
    $Res Function(ScoreMembre) then,
  ) = _$ScoreMembreCopyWithImpl<$Res, ScoreMembre>;
  @useResult
  $Res call({
    String membreId,
    int score,
    int cyclesTermines,
    int defauts,
    bool premieresPlacesFermees,
    List<String> explication,
    List<EvenementScore> historique,
  });
}

/// @nodoc
class _$ScoreMembreCopyWithImpl<$Res, $Val extends ScoreMembre>
    implements $ScoreMembreCopyWith<$Res> {
  _$ScoreMembreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScoreMembre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? membreId = null,
    Object? score = null,
    Object? cyclesTermines = null,
    Object? defauts = null,
    Object? premieresPlacesFermees = null,
    Object? explication = null,
    Object? historique = null,
  }) {
    return _then(
      _value.copyWith(
            membreId: null == membreId
                ? _value.membreId
                : membreId // ignore: cast_nullable_to_non_nullable
                      as String,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
            cyclesTermines: null == cyclesTermines
                ? _value.cyclesTermines
                : cyclesTermines // ignore: cast_nullable_to_non_nullable
                      as int,
            defauts: null == defauts
                ? _value.defauts
                : defauts // ignore: cast_nullable_to_non_nullable
                      as int,
            premieresPlacesFermees: null == premieresPlacesFermees
                ? _value.premieresPlacesFermees
                : premieresPlacesFermees // ignore: cast_nullable_to_non_nullable
                      as bool,
            explication: null == explication
                ? _value.explication
                : explication // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            historique: null == historique
                ? _value.historique
                : historique // ignore: cast_nullable_to_non_nullable
                      as List<EvenementScore>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScoreMembreImplCopyWith<$Res>
    implements $ScoreMembreCopyWith<$Res> {
  factory _$$ScoreMembreImplCopyWith(
    _$ScoreMembreImpl value,
    $Res Function(_$ScoreMembreImpl) then,
  ) = __$$ScoreMembreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String membreId,
    int score,
    int cyclesTermines,
    int defauts,
    bool premieresPlacesFermees,
    List<String> explication,
    List<EvenementScore> historique,
  });
}

/// @nodoc
class __$$ScoreMembreImplCopyWithImpl<$Res>
    extends _$ScoreMembreCopyWithImpl<$Res, _$ScoreMembreImpl>
    implements _$$ScoreMembreImplCopyWith<$Res> {
  __$$ScoreMembreImplCopyWithImpl(
    _$ScoreMembreImpl _value,
    $Res Function(_$ScoreMembreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScoreMembre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? membreId = null,
    Object? score = null,
    Object? cyclesTermines = null,
    Object? defauts = null,
    Object? premieresPlacesFermees = null,
    Object? explication = null,
    Object? historique = null,
  }) {
    return _then(
      _$ScoreMembreImpl(
        membreId: null == membreId
            ? _value.membreId
            : membreId // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
        cyclesTermines: null == cyclesTermines
            ? _value.cyclesTermines
            : cyclesTermines // ignore: cast_nullable_to_non_nullable
                  as int,
        defauts: null == defauts
            ? _value.defauts
            : defauts // ignore: cast_nullable_to_non_nullable
                  as int,
        premieresPlacesFermees: null == premieresPlacesFermees
            ? _value.premieresPlacesFermees
            : premieresPlacesFermees // ignore: cast_nullable_to_non_nullable
                  as bool,
        explication: null == explication
            ? _value._explication
            : explication // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        historique: null == historique
            ? _value._historique
            : historique // ignore: cast_nullable_to_non_nullable
                  as List<EvenementScore>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ScoreMembreImpl implements _ScoreMembre {
  const _$ScoreMembreImpl({
    required this.membreId,
    required this.score,
    this.cyclesTermines = 0,
    this.defauts = 0,
    this.premieresPlacesFermees = false,
    final List<String> explication = const <String>[],
    final List<EvenementScore> historique = const <EvenementScore>[],
  }) : _explication = explication,
       _historique = historique;

  factory _$ScoreMembreImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScoreMembreImplFromJson(json);

  @override
  final String membreId;
  @override
  final int score;
  @override
  @JsonKey()
  final int cyclesTermines;
  @override
  @JsonKey()
  final int defauts;
  @override
  @JsonKey()
  final bool premieresPlacesFermees;
  final List<String> _explication;
  @override
  @JsonKey()
  List<String> get explication {
    if (_explication is EqualUnmodifiableListView) return _explication;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_explication);
  }

  final List<EvenementScore> _historique;
  @override
  @JsonKey()
  List<EvenementScore> get historique {
    if (_historique is EqualUnmodifiableListView) return _historique;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_historique);
  }

  @override
  String toString() {
    return 'ScoreMembre(membreId: $membreId, score: $score, cyclesTermines: $cyclesTermines, defauts: $defauts, premieresPlacesFermees: $premieresPlacesFermees, explication: $explication, historique: $historique)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScoreMembreImpl &&
            (identical(other.membreId, membreId) ||
                other.membreId == membreId) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.cyclesTermines, cyclesTermines) ||
                other.cyclesTermines == cyclesTermines) &&
            (identical(other.defauts, defauts) || other.defauts == defauts) &&
            (identical(other.premieresPlacesFermees, premieresPlacesFermees) ||
                other.premieresPlacesFermees == premieresPlacesFermees) &&
            const DeepCollectionEquality().equals(
              other._explication,
              _explication,
            ) &&
            const DeepCollectionEquality().equals(
              other._historique,
              _historique,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    membreId,
    score,
    cyclesTermines,
    defauts,
    premieresPlacesFermees,
    const DeepCollectionEquality().hash(_explication),
    const DeepCollectionEquality().hash(_historique),
  );

  /// Create a copy of ScoreMembre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScoreMembreImplCopyWith<_$ScoreMembreImpl> get copyWith =>
      __$$ScoreMembreImplCopyWithImpl<_$ScoreMembreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScoreMembreImplToJson(this);
  }
}

abstract class _ScoreMembre implements ScoreMembre {
  const factory _ScoreMembre({
    required final String membreId,
    required final int score,
    final int cyclesTermines,
    final int defauts,
    final bool premieresPlacesFermees,
    final List<String> explication,
    final List<EvenementScore> historique,
  }) = _$ScoreMembreImpl;

  factory _ScoreMembre.fromJson(Map<String, dynamic> json) =
      _$ScoreMembreImpl.fromJson;

  @override
  String get membreId;
  @override
  int get score;
  @override
  int get cyclesTermines;
  @override
  int get defauts;
  @override
  bool get premieresPlacesFermees;
  @override
  List<String> get explication;
  @override
  List<EvenementScore> get historique;

  /// Create a copy of ScoreMembre
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScoreMembreImplCopyWith<_$ScoreMembreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EvenementScore _$EvenementScoreFromJson(Map<String, dynamic> json) {
  return _EvenementScore.fromJson(json);
}

/// @nodoc
mixin _$EvenementScore {
  String get date => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get cercleId => throw _privateConstructorUsedError;
  bool get cerclePrive => throw _privateConstructorUsedError;
  num get points => throw _privateConstructorUsedError;
  num get scoreApres => throw _privateConstructorUsedError;

  /// Serializes this EvenementScore to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EvenementScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvenementScoreCopyWith<EvenementScore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvenementScoreCopyWith<$Res> {
  factory $EvenementScoreCopyWith(
    EvenementScore value,
    $Res Function(EvenementScore) then,
  ) = _$EvenementScoreCopyWithImpl<$Res, EvenementScore>;
  @useResult
  $Res call({
    String date,
    String type,
    String? cercleId,
    bool cerclePrive,
    num points,
    num scoreApres,
  });
}

/// @nodoc
class _$EvenementScoreCopyWithImpl<$Res, $Val extends EvenementScore>
    implements $EvenementScoreCopyWith<$Res> {
  _$EvenementScoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EvenementScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? type = null,
    Object? cercleId = freezed,
    Object? cerclePrive = null,
    Object? points = null,
    Object? scoreApres = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            cercleId: freezed == cercleId
                ? _value.cercleId
                : cercleId // ignore: cast_nullable_to_non_nullable
                      as String?,
            cerclePrive: null == cerclePrive
                ? _value.cerclePrive
                : cerclePrive // ignore: cast_nullable_to_non_nullable
                      as bool,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as num,
            scoreApres: null == scoreApres
                ? _value.scoreApres
                : scoreApres // ignore: cast_nullable_to_non_nullable
                      as num,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EvenementScoreImplCopyWith<$Res>
    implements $EvenementScoreCopyWith<$Res> {
  factory _$$EvenementScoreImplCopyWith(
    _$EvenementScoreImpl value,
    $Res Function(_$EvenementScoreImpl) then,
  ) = __$$EvenementScoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String date,
    String type,
    String? cercleId,
    bool cerclePrive,
    num points,
    num scoreApres,
  });
}

/// @nodoc
class __$$EvenementScoreImplCopyWithImpl<$Res>
    extends _$EvenementScoreCopyWithImpl<$Res, _$EvenementScoreImpl>
    implements _$$EvenementScoreImplCopyWith<$Res> {
  __$$EvenementScoreImplCopyWithImpl(
    _$EvenementScoreImpl _value,
    $Res Function(_$EvenementScoreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EvenementScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? type = null,
    Object? cercleId = freezed,
    Object? cerclePrive = null,
    Object? points = null,
    Object? scoreApres = null,
  }) {
    return _then(
      _$EvenementScoreImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        cercleId: freezed == cercleId
            ? _value.cercleId
            : cercleId // ignore: cast_nullable_to_non_nullable
                  as String?,
        cerclePrive: null == cerclePrive
            ? _value.cerclePrive
            : cerclePrive // ignore: cast_nullable_to_non_nullable
                  as bool,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as num,
        scoreApres: null == scoreApres
            ? _value.scoreApres
            : scoreApres // ignore: cast_nullable_to_non_nullable
                  as num,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EvenementScoreImpl implements _EvenementScore {
  const _$EvenementScoreImpl({
    required this.date,
    required this.type,
    this.cercleId,
    this.cerclePrive = false,
    required this.points,
    required this.scoreApres,
  });

  factory _$EvenementScoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvenementScoreImplFromJson(json);

  @override
  final String date;
  @override
  final String type;
  @override
  final String? cercleId;
  @override
  @JsonKey()
  final bool cerclePrive;
  @override
  final num points;
  @override
  final num scoreApres;

  @override
  String toString() {
    return 'EvenementScore(date: $date, type: $type, cercleId: $cercleId, cerclePrive: $cerclePrive, points: $points, scoreApres: $scoreApres)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvenementScoreImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.cercleId, cercleId) ||
                other.cercleId == cercleId) &&
            (identical(other.cerclePrive, cerclePrive) ||
                other.cerclePrive == cerclePrive) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.scoreApres, scoreApres) ||
                other.scoreApres == scoreApres));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    date,
    type,
    cercleId,
    cerclePrive,
    points,
    scoreApres,
  );

  /// Create a copy of EvenementScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvenementScoreImplCopyWith<_$EvenementScoreImpl> get copyWith =>
      __$$EvenementScoreImplCopyWithImpl<_$EvenementScoreImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EvenementScoreImplToJson(this);
  }
}

abstract class _EvenementScore implements EvenementScore {
  const factory _EvenementScore({
    required final String date,
    required final String type,
    final String? cercleId,
    final bool cerclePrive,
    required final num points,
    required final num scoreApres,
  }) = _$EvenementScoreImpl;

  factory _EvenementScore.fromJson(Map<String, dynamic> json) =
      _$EvenementScoreImpl.fromJson;

  @override
  String get date;
  @override
  String get type;
  @override
  String? get cercleId;
  @override
  bool get cerclePrive;
  @override
  num get points;
  @override
  num get scoreApres;

  /// Create a copy of EvenementScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvenementScoreImplCopyWith<_$EvenementScoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Litige _$LitigeFromJson(Map<String, dynamic> json) {
  return _Litige.fromJson(json);
}

/// @nodoc
mixin _$Litige {
  String get id => throw _privateConstructorUsedError;
  String get cotisationId => throw _privateConstructorUsedError;
  String get cercleId => throw _privateConstructorUsedError;
  String get payeurId => throw _privateConstructorUsedError;
  String get beneficiaireId => throw _privateConstructorUsedError;
  String get ouvertPar =>
      throw _privateConstructorUsedError; // payeur, beneficiaire, automatique
  String get motif => throw _privateConstructorUsedError;
  String get ouvertLe => throw _privateConstructorUsedError;
  String get statut =>
      throw _privateConstructorUsedError; // ouvert, tranche, clos
  String? get decision =>
      throw _privateConstructorUsedError; // paiement_valide, paiement_refuse, confirme_par_beneficiaire
  String? get motifDecision => throw _privateConstructorUsedError;
  String? get tranchePar => throw _privateConstructorUsedError;
  String? get trancheLe => throw _privateConstructorUsedError;

  /// Serializes this Litige to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Litige
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LitigeCopyWith<Litige> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LitigeCopyWith<$Res> {
  factory $LitigeCopyWith(Litige value, $Res Function(Litige) then) =
      _$LitigeCopyWithImpl<$Res, Litige>;
  @useResult
  $Res call({
    String id,
    String cotisationId,
    String cercleId,
    String payeurId,
    String beneficiaireId,
    String ouvertPar,
    String motif,
    String ouvertLe,
    String statut,
    String? decision,
    String? motifDecision,
    String? tranchePar,
    String? trancheLe,
  });
}

/// @nodoc
class _$LitigeCopyWithImpl<$Res, $Val extends Litige>
    implements $LitigeCopyWith<$Res> {
  _$LitigeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Litige
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cotisationId = null,
    Object? cercleId = null,
    Object? payeurId = null,
    Object? beneficiaireId = null,
    Object? ouvertPar = null,
    Object? motif = null,
    Object? ouvertLe = null,
    Object? statut = null,
    Object? decision = freezed,
    Object? motifDecision = freezed,
    Object? tranchePar = freezed,
    Object? trancheLe = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            cotisationId: null == cotisationId
                ? _value.cotisationId
                : cotisationId // ignore: cast_nullable_to_non_nullable
                      as String,
            cercleId: null == cercleId
                ? _value.cercleId
                : cercleId // ignore: cast_nullable_to_non_nullable
                      as String,
            payeurId: null == payeurId
                ? _value.payeurId
                : payeurId // ignore: cast_nullable_to_non_nullable
                      as String,
            beneficiaireId: null == beneficiaireId
                ? _value.beneficiaireId
                : beneficiaireId // ignore: cast_nullable_to_non_nullable
                      as String,
            ouvertPar: null == ouvertPar
                ? _value.ouvertPar
                : ouvertPar // ignore: cast_nullable_to_non_nullable
                      as String,
            motif: null == motif
                ? _value.motif
                : motif // ignore: cast_nullable_to_non_nullable
                      as String,
            ouvertLe: null == ouvertLe
                ? _value.ouvertLe
                : ouvertLe // ignore: cast_nullable_to_non_nullable
                      as String,
            statut: null == statut
                ? _value.statut
                : statut // ignore: cast_nullable_to_non_nullable
                      as String,
            decision: freezed == decision
                ? _value.decision
                : decision // ignore: cast_nullable_to_non_nullable
                      as String?,
            motifDecision: freezed == motifDecision
                ? _value.motifDecision
                : motifDecision // ignore: cast_nullable_to_non_nullable
                      as String?,
            tranchePar: freezed == tranchePar
                ? _value.tranchePar
                : tranchePar // ignore: cast_nullable_to_non_nullable
                      as String?,
            trancheLe: freezed == trancheLe
                ? _value.trancheLe
                : trancheLe // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LitigeImplCopyWith<$Res> implements $LitigeCopyWith<$Res> {
  factory _$$LitigeImplCopyWith(
    _$LitigeImpl value,
    $Res Function(_$LitigeImpl) then,
  ) = __$$LitigeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String cotisationId,
    String cercleId,
    String payeurId,
    String beneficiaireId,
    String ouvertPar,
    String motif,
    String ouvertLe,
    String statut,
    String? decision,
    String? motifDecision,
    String? tranchePar,
    String? trancheLe,
  });
}

/// @nodoc
class __$$LitigeImplCopyWithImpl<$Res>
    extends _$LitigeCopyWithImpl<$Res, _$LitigeImpl>
    implements _$$LitigeImplCopyWith<$Res> {
  __$$LitigeImplCopyWithImpl(
    _$LitigeImpl _value,
    $Res Function(_$LitigeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Litige
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cotisationId = null,
    Object? cercleId = null,
    Object? payeurId = null,
    Object? beneficiaireId = null,
    Object? ouvertPar = null,
    Object? motif = null,
    Object? ouvertLe = null,
    Object? statut = null,
    Object? decision = freezed,
    Object? motifDecision = freezed,
    Object? tranchePar = freezed,
    Object? trancheLe = freezed,
  }) {
    return _then(
      _$LitigeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        cotisationId: null == cotisationId
            ? _value.cotisationId
            : cotisationId // ignore: cast_nullable_to_non_nullable
                  as String,
        cercleId: null == cercleId
            ? _value.cercleId
            : cercleId // ignore: cast_nullable_to_non_nullable
                  as String,
        payeurId: null == payeurId
            ? _value.payeurId
            : payeurId // ignore: cast_nullable_to_non_nullable
                  as String,
        beneficiaireId: null == beneficiaireId
            ? _value.beneficiaireId
            : beneficiaireId // ignore: cast_nullable_to_non_nullable
                  as String,
        ouvertPar: null == ouvertPar
            ? _value.ouvertPar
            : ouvertPar // ignore: cast_nullable_to_non_nullable
                  as String,
        motif: null == motif
            ? _value.motif
            : motif // ignore: cast_nullable_to_non_nullable
                  as String,
        ouvertLe: null == ouvertLe
            ? _value.ouvertLe
            : ouvertLe // ignore: cast_nullable_to_non_nullable
                  as String,
        statut: null == statut
            ? _value.statut
            : statut // ignore: cast_nullable_to_non_nullable
                  as String,
        decision: freezed == decision
            ? _value.decision
            : decision // ignore: cast_nullable_to_non_nullable
                  as String?,
        motifDecision: freezed == motifDecision
            ? _value.motifDecision
            : motifDecision // ignore: cast_nullable_to_non_nullable
                  as String?,
        tranchePar: freezed == tranchePar
            ? _value.tranchePar
            : tranchePar // ignore: cast_nullable_to_non_nullable
                  as String?,
        trancheLe: freezed == trancheLe
            ? _value.trancheLe
            : trancheLe // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LitigeImpl implements _Litige {
  const _$LitigeImpl({
    required this.id,
    required this.cotisationId,
    required this.cercleId,
    required this.payeurId,
    required this.beneficiaireId,
    required this.ouvertPar,
    required this.motif,
    required this.ouvertLe,
    required this.statut,
    this.decision,
    this.motifDecision,
    this.tranchePar,
    this.trancheLe,
  });

  factory _$LitigeImpl.fromJson(Map<String, dynamic> json) =>
      _$$LitigeImplFromJson(json);

  @override
  final String id;
  @override
  final String cotisationId;
  @override
  final String cercleId;
  @override
  final String payeurId;
  @override
  final String beneficiaireId;
  @override
  final String ouvertPar;
  // payeur, beneficiaire, automatique
  @override
  final String motif;
  @override
  final String ouvertLe;
  @override
  final String statut;
  // ouvert, tranche, clos
  @override
  final String? decision;
  // paiement_valide, paiement_refuse, confirme_par_beneficiaire
  @override
  final String? motifDecision;
  @override
  final String? tranchePar;
  @override
  final String? trancheLe;

  @override
  String toString() {
    return 'Litige(id: $id, cotisationId: $cotisationId, cercleId: $cercleId, payeurId: $payeurId, beneficiaireId: $beneficiaireId, ouvertPar: $ouvertPar, motif: $motif, ouvertLe: $ouvertLe, statut: $statut, decision: $decision, motifDecision: $motifDecision, tranchePar: $tranchePar, trancheLe: $trancheLe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LitigeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cotisationId, cotisationId) ||
                other.cotisationId == cotisationId) &&
            (identical(other.cercleId, cercleId) ||
                other.cercleId == cercleId) &&
            (identical(other.payeurId, payeurId) ||
                other.payeurId == payeurId) &&
            (identical(other.beneficiaireId, beneficiaireId) ||
                other.beneficiaireId == beneficiaireId) &&
            (identical(other.ouvertPar, ouvertPar) ||
                other.ouvertPar == ouvertPar) &&
            (identical(other.motif, motif) || other.motif == motif) &&
            (identical(other.ouvertLe, ouvertLe) ||
                other.ouvertLe == ouvertLe) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.decision, decision) ||
                other.decision == decision) &&
            (identical(other.motifDecision, motifDecision) ||
                other.motifDecision == motifDecision) &&
            (identical(other.tranchePar, tranchePar) ||
                other.tranchePar == tranchePar) &&
            (identical(other.trancheLe, trancheLe) ||
                other.trancheLe == trancheLe));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    cotisationId,
    cercleId,
    payeurId,
    beneficiaireId,
    ouvertPar,
    motif,
    ouvertLe,
    statut,
    decision,
    motifDecision,
    tranchePar,
    trancheLe,
  );

  /// Create a copy of Litige
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LitigeImplCopyWith<_$LitigeImpl> get copyWith =>
      __$$LitigeImplCopyWithImpl<_$LitigeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LitigeImplToJson(this);
  }
}

abstract class _Litige implements Litige {
  const factory _Litige({
    required final String id,
    required final String cotisationId,
    required final String cercleId,
    required final String payeurId,
    required final String beneficiaireId,
    required final String ouvertPar,
    required final String motif,
    required final String ouvertLe,
    required final String statut,
    final String? decision,
    final String? motifDecision,
    final String? tranchePar,
    final String? trancheLe,
  }) = _$LitigeImpl;

  factory _Litige.fromJson(Map<String, dynamic> json) = _$LitigeImpl.fromJson;

  @override
  String get id;
  @override
  String get cotisationId;
  @override
  String get cercleId;
  @override
  String get payeurId;
  @override
  String get beneficiaireId;
  @override
  String get ouvertPar; // payeur, beneficiaire, automatique
  @override
  String get motif;
  @override
  String get ouvertLe;
  @override
  String get statut; // ouvert, tranche, clos
  @override
  String? get decision; // paiement_valide, paiement_refuse, confirme_par_beneficiaire
  @override
  String? get motifDecision;
  @override
  String? get tranchePar;
  @override
  String? get trancheLe;

  /// Create a copy of Litige
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LitigeImplCopyWith<_$LitigeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Notification _$NotificationFromJson(Map<String, dynamic> json) {
  return _Notification.fromJson(json);
}

/// @nodoc
mixin _$Notification {
  String get id => throw _privateConstructorUsedError;
  String get texte => throw _privateConstructorUsedError;
  String get creeeLe => throw _privateConstructorUsedError;
  String? get lueLe => throw _privateConstructorUsedError;

  /// Serializes this Notification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationCopyWith<Notification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCopyWith<$Res> {
  factory $NotificationCopyWith(
    Notification value,
    $Res Function(Notification) then,
  ) = _$NotificationCopyWithImpl<$Res, Notification>;
  @useResult
  $Res call({String id, String texte, String creeeLe, String? lueLe});
}

/// @nodoc
class _$NotificationCopyWithImpl<$Res, $Val extends Notification>
    implements $NotificationCopyWith<$Res> {
  _$NotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? texte = null,
    Object? creeeLe = null,
    Object? lueLe = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            texte: null == texte
                ? _value.texte
                : texte // ignore: cast_nullable_to_non_nullable
                      as String,
            creeeLe: null == creeeLe
                ? _value.creeeLe
                : creeeLe // ignore: cast_nullable_to_non_nullable
                      as String,
            lueLe: freezed == lueLe
                ? _value.lueLe
                : lueLe // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationImplCopyWith<$Res>
    implements $NotificationCopyWith<$Res> {
  factory _$$NotificationImplCopyWith(
    _$NotificationImpl value,
    $Res Function(_$NotificationImpl) then,
  ) = __$$NotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String texte, String creeeLe, String? lueLe});
}

/// @nodoc
class __$$NotificationImplCopyWithImpl<$Res>
    extends _$NotificationCopyWithImpl<$Res, _$NotificationImpl>
    implements _$$NotificationImplCopyWith<$Res> {
  __$$NotificationImplCopyWithImpl(
    _$NotificationImpl _value,
    $Res Function(_$NotificationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? texte = null,
    Object? creeeLe = null,
    Object? lueLe = freezed,
  }) {
    return _then(
      _$NotificationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        texte: null == texte
            ? _value.texte
            : texte // ignore: cast_nullable_to_non_nullable
                  as String,
        creeeLe: null == creeeLe
            ? _value.creeeLe
            : creeeLe // ignore: cast_nullable_to_non_nullable
                  as String,
        lueLe: freezed == lueLe
            ? _value.lueLe
            : lueLe // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationImpl extends _Notification {
  const _$NotificationImpl({
    required this.id,
    required this.texte,
    required this.creeeLe,
    this.lueLe,
  }) : super._();

  factory _$NotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationImplFromJson(json);

  @override
  final String id;
  @override
  final String texte;
  @override
  final String creeeLe;
  @override
  final String? lueLe;

  @override
  String toString() {
    return 'Notification(id: $id, texte: $texte, creeeLe: $creeeLe, lueLe: $lueLe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.texte, texte) || other.texte == texte) &&
            (identical(other.creeeLe, creeeLe) || other.creeeLe == creeeLe) &&
            (identical(other.lueLe, lueLe) || other.lueLe == lueLe));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, texte, creeeLe, lueLe);

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      __$$NotificationImplCopyWithImpl<_$NotificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationImplToJson(this);
  }
}

abstract class _Notification extends Notification {
  const factory _Notification({
    required final String id,
    required final String texte,
    required final String creeeLe,
    final String? lueLe,
  }) = _$NotificationImpl;
  const _Notification._() : super._();

  factory _Notification.fromJson(Map<String, dynamic> json) =
      _$NotificationImpl.fromJson;

  @override
  String get id;
  @override
  String get texte;
  @override
  String get creeeLe;
  @override
  String? get lueLe;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationsResponse _$NotificationsResponseFromJson(
  Map<String, dynamic> json,
) {
  return _NotificationsResponse.fromJson(json);
}

/// @nodoc
mixin _$NotificationsResponse {
  List<Notification> get notifications => throw _privateConstructorUsedError;
  int get nonLues => throw _privateConstructorUsedError;

  /// Serializes this NotificationsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationsResponseCopyWith<NotificationsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationsResponseCopyWith<$Res> {
  factory $NotificationsResponseCopyWith(
    NotificationsResponse value,
    $Res Function(NotificationsResponse) then,
  ) = _$NotificationsResponseCopyWithImpl<$Res, NotificationsResponse>;
  @useResult
  $Res call({List<Notification> notifications, int nonLues});
}

/// @nodoc
class _$NotificationsResponseCopyWithImpl<
  $Res,
  $Val extends NotificationsResponse
>
    implements $NotificationsResponseCopyWith<$Res> {
  _$NotificationsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notifications = null, Object? nonLues = null}) {
    return _then(
      _value.copyWith(
            notifications: null == notifications
                ? _value.notifications
                : notifications // ignore: cast_nullable_to_non_nullable
                      as List<Notification>,
            nonLues: null == nonLues
                ? _value.nonLues
                : nonLues // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationsResponseImplCopyWith<$Res>
    implements $NotificationsResponseCopyWith<$Res> {
  factory _$$NotificationsResponseImplCopyWith(
    _$NotificationsResponseImpl value,
    $Res Function(_$NotificationsResponseImpl) then,
  ) = __$$NotificationsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Notification> notifications, int nonLues});
}

/// @nodoc
class __$$NotificationsResponseImplCopyWithImpl<$Res>
    extends
        _$NotificationsResponseCopyWithImpl<$Res, _$NotificationsResponseImpl>
    implements _$$NotificationsResponseImplCopyWith<$Res> {
  __$$NotificationsResponseImplCopyWithImpl(
    _$NotificationsResponseImpl _value,
    $Res Function(_$NotificationsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notifications = null, Object? nonLues = null}) {
    return _then(
      _$NotificationsResponseImpl(
        notifications: null == notifications
            ? _value._notifications
            : notifications // ignore: cast_nullable_to_non_nullable
                  as List<Notification>,
        nonLues: null == nonLues
            ? _value.nonLues
            : nonLues // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationsResponseImpl implements _NotificationsResponse {
  const _$NotificationsResponseImpl({
    required final List<Notification> notifications,
    this.nonLues = 0,
  }) : _notifications = notifications;

  factory _$NotificationsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationsResponseImplFromJson(json);

  final List<Notification> _notifications;
  @override
  List<Notification> get notifications {
    if (_notifications is EqualUnmodifiableListView) return _notifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notifications);
  }

  @override
  @JsonKey()
  final int nonLues;

  @override
  String toString() {
    return 'NotificationsResponse(notifications: $notifications, nonLues: $nonLues)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationsResponseImpl &&
            const DeepCollectionEquality().equals(
              other._notifications,
              _notifications,
            ) &&
            (identical(other.nonLues, nonLues) || other.nonLues == nonLues));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_notifications),
    nonLues,
  );

  /// Create a copy of NotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationsResponseImplCopyWith<_$NotificationsResponseImpl>
  get copyWith =>
      __$$NotificationsResponseImplCopyWithImpl<_$NotificationsResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationsResponseImplToJson(this);
  }
}

abstract class _NotificationsResponse implements NotificationsResponse {
  const factory _NotificationsResponse({
    required final List<Notification> notifications,
    final int nonLues,
  }) = _$NotificationsResponseImpl;

  factory _NotificationsResponse.fromJson(Map<String, dynamic> json) =
      _$NotificationsResponseImpl.fromJson;

  @override
  List<Notification> get notifications;
  @override
  int get nonLues;

  /// Create a copy of NotificationsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationsResponseImplCopyWith<_$NotificationsResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SommeDue _$SommeDueFromJson(Map<String, dynamic> json) {
  return _SommeDue.fromJson(json);
}

/// @nodoc
mixin _$SommeDue {
  String get id => throw _privateConstructorUsedError;
  String get cercleId => throw _privateConstructorUsedError;
  String get nature => throw _privateConstructorUsedError;
  String? get debiteurId => throw _privateConstructorUsedError;
  String? get creancierId => throw _privateConstructorUsedError;
  int get montant => throw _privateConstructorUsedError;
  int? get tour => throw _privateConstructorUsedError;
  String? get exigibleLe => throw _privateConstructorUsedError;
  String? get dateLimite => throw _privateConstructorUsedError;
  String get statut => throw _privateConstructorUsedError;

  /// Serializes this SommeDue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SommeDue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SommeDueCopyWith<SommeDue> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SommeDueCopyWith<$Res> {
  factory $SommeDueCopyWith(SommeDue value, $Res Function(SommeDue) then) =
      _$SommeDueCopyWithImpl<$Res, SommeDue>;
  @useResult
  $Res call({
    String id,
    String cercleId,
    String nature,
    String? debiteurId,
    String? creancierId,
    int montant,
    int? tour,
    String? exigibleLe,
    String? dateLimite,
    String statut,
  });
}

/// @nodoc
class _$SommeDueCopyWithImpl<$Res, $Val extends SommeDue>
    implements $SommeDueCopyWith<$Res> {
  _$SommeDueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SommeDue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cercleId = null,
    Object? nature = null,
    Object? debiteurId = freezed,
    Object? creancierId = freezed,
    Object? montant = null,
    Object? tour = freezed,
    Object? exigibleLe = freezed,
    Object? dateLimite = freezed,
    Object? statut = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            cercleId: null == cercleId
                ? _value.cercleId
                : cercleId // ignore: cast_nullable_to_non_nullable
                      as String,
            nature: null == nature
                ? _value.nature
                : nature // ignore: cast_nullable_to_non_nullable
                      as String,
            debiteurId: freezed == debiteurId
                ? _value.debiteurId
                : debiteurId // ignore: cast_nullable_to_non_nullable
                      as String?,
            creancierId: freezed == creancierId
                ? _value.creancierId
                : creancierId // ignore: cast_nullable_to_non_nullable
                      as String?,
            montant: null == montant
                ? _value.montant
                : montant // ignore: cast_nullable_to_non_nullable
                      as int,
            tour: freezed == tour
                ? _value.tour
                : tour // ignore: cast_nullable_to_non_nullable
                      as int?,
            exigibleLe: freezed == exigibleLe
                ? _value.exigibleLe
                : exigibleLe // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateLimite: freezed == dateLimite
                ? _value.dateLimite
                : dateLimite // ignore: cast_nullable_to_non_nullable
                      as String?,
            statut: null == statut
                ? _value.statut
                : statut // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SommeDueImplCopyWith<$Res>
    implements $SommeDueCopyWith<$Res> {
  factory _$$SommeDueImplCopyWith(
    _$SommeDueImpl value,
    $Res Function(_$SommeDueImpl) then,
  ) = __$$SommeDueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String cercleId,
    String nature,
    String? debiteurId,
    String? creancierId,
    int montant,
    int? tour,
    String? exigibleLe,
    String? dateLimite,
    String statut,
  });
}

/// @nodoc
class __$$SommeDueImplCopyWithImpl<$Res>
    extends _$SommeDueCopyWithImpl<$Res, _$SommeDueImpl>
    implements _$$SommeDueImplCopyWith<$Res> {
  __$$SommeDueImplCopyWithImpl(
    _$SommeDueImpl _value,
    $Res Function(_$SommeDueImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SommeDue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cercleId = null,
    Object? nature = null,
    Object? debiteurId = freezed,
    Object? creancierId = freezed,
    Object? montant = null,
    Object? tour = freezed,
    Object? exigibleLe = freezed,
    Object? dateLimite = freezed,
    Object? statut = null,
  }) {
    return _then(
      _$SommeDueImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        cercleId: null == cercleId
            ? _value.cercleId
            : cercleId // ignore: cast_nullable_to_non_nullable
                  as String,
        nature: null == nature
            ? _value.nature
            : nature // ignore: cast_nullable_to_non_nullable
                  as String,
        debiteurId: freezed == debiteurId
            ? _value.debiteurId
            : debiteurId // ignore: cast_nullable_to_non_nullable
                  as String?,
        creancierId: freezed == creancierId
            ? _value.creancierId
            : creancierId // ignore: cast_nullable_to_non_nullable
                  as String?,
        montant: null == montant
            ? _value.montant
            : montant // ignore: cast_nullable_to_non_nullable
                  as int,
        tour: freezed == tour
            ? _value.tour
            : tour // ignore: cast_nullable_to_non_nullable
                  as int?,
        exigibleLe: freezed == exigibleLe
            ? _value.exigibleLe
            : exigibleLe // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateLimite: freezed == dateLimite
            ? _value.dateLimite
            : dateLimite // ignore: cast_nullable_to_non_nullable
                  as String?,
        statut: null == statut
            ? _value.statut
            : statut // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SommeDueImpl implements _SommeDue {
  const _$SommeDueImpl({
    required this.id,
    required this.cercleId,
    required this.nature,
    this.debiteurId,
    this.creancierId,
    required this.montant,
    this.tour,
    this.exigibleLe,
    this.dateLimite,
    required this.statut,
  });

  factory _$SommeDueImpl.fromJson(Map<String, dynamic> json) =>
      _$$SommeDueImplFromJson(json);

  @override
  final String id;
  @override
  final String cercleId;
  @override
  final String nature;
  @override
  final String? debiteurId;
  @override
  final String? creancierId;
  @override
  final int montant;
  @override
  final int? tour;
  @override
  final String? exigibleLe;
  @override
  final String? dateLimite;
  @override
  final String statut;

  @override
  String toString() {
    return 'SommeDue(id: $id, cercleId: $cercleId, nature: $nature, debiteurId: $debiteurId, creancierId: $creancierId, montant: $montant, tour: $tour, exigibleLe: $exigibleLe, dateLimite: $dateLimite, statut: $statut)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SommeDueImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cercleId, cercleId) ||
                other.cercleId == cercleId) &&
            (identical(other.nature, nature) || other.nature == nature) &&
            (identical(other.debiteurId, debiteurId) ||
                other.debiteurId == debiteurId) &&
            (identical(other.creancierId, creancierId) ||
                other.creancierId == creancierId) &&
            (identical(other.montant, montant) || other.montant == montant) &&
            (identical(other.tour, tour) || other.tour == tour) &&
            (identical(other.exigibleLe, exigibleLe) ||
                other.exigibleLe == exigibleLe) &&
            (identical(other.dateLimite, dateLimite) ||
                other.dateLimite == dateLimite) &&
            (identical(other.statut, statut) || other.statut == statut));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    cercleId,
    nature,
    debiteurId,
    creancierId,
    montant,
    tour,
    exigibleLe,
    dateLimite,
    statut,
  );

  /// Create a copy of SommeDue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SommeDueImplCopyWith<_$SommeDueImpl> get copyWith =>
      __$$SommeDueImplCopyWithImpl<_$SommeDueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SommeDueImplToJson(this);
  }
}

abstract class _SommeDue implements SommeDue {
  const factory _SommeDue({
    required final String id,
    required final String cercleId,
    required final String nature,
    final String? debiteurId,
    final String? creancierId,
    required final int montant,
    final int? tour,
    final String? exigibleLe,
    final String? dateLimite,
    required final String statut,
  }) = _$SommeDueImpl;

  factory _SommeDue.fromJson(Map<String, dynamic> json) =
      _$SommeDueImpl.fromJson;

  @override
  String get id;
  @override
  String get cercleId;
  @override
  String get nature;
  @override
  String? get debiteurId;
  @override
  String? get creancierId;
  @override
  int get montant;
  @override
  int? get tour;
  @override
  String? get exigibleLe;
  @override
  String? get dateLimite;
  @override
  String get statut;

  /// Create a copy of SommeDue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SommeDueImplCopyWith<_$SommeDueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
