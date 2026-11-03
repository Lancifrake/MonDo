// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title Registre d'empreintes de MonDo
/// @notice Une racine d'arbre de hachage par lot d'événements (décision 02, règle 6).
/// Aucun fonds et aucune donnée personnelle : seulement des empreintes (décision 01).
/// Non audité : à faire auditer avant tout usage réel (SECURITY.md).
contract RegistreMonDo is AccessControl, Pausable {
    /// @notice Rôle du serveur MonDo, seul autorisé à inscrire des racines.
    bytes32 public constant INSCRIPTEUR = keccak256("INSCRIPTEUR");

    /// @notice Horodatage (secondes) de l'inscription d'une racine ; 0 si elle n'est pas inscrite.
    mapping(bytes32 racine => uint64 horodatage) public horodatageDe;

    uint256 public nombreDeLots;

    event RacineInscrite(bytes32 indexed racine, uint256 indexed numeroLot, uint64 horodatage);

    error RacineNulle();
    error RacineDejaInscrite(bytes32 racine);
    error PreuveMalFormee();

    constructor(address administrateur, address inscripteur) {
        _grantRole(DEFAULT_ADMIN_ROLE, administrateur);
        _grantRole(INSCRIPTEUR, inscripteur);
    }

    function inscrireRacine(bytes32 racine) external onlyRole(INSCRIPTEUR) whenNotPaused returns (uint256 numeroLot) {
        if (racine == bytes32(0)) revert RacineNulle();
        if (horodatageDe[racine] != 0) revert RacineDejaInscrite(racine);
        uint64 maintenant = uint64(block.timestamp);
        horodatageDe[racine] = maintenant;
        numeroLot = ++nombreDeLots;
        emit RacineInscrite(racine, numeroLot, maintenant);
    }

    /// @notice Vérifie qu'une empreinte appartient à un lot inscrit, sans faire confiance à MonDo.
    /// Même construction que le serveur (src/serveur/src/registre/merkle.ts) : SHA-256,
    /// préfixe 0x00 pour une feuille, 0x01 pour un nœud, nœud sans frère remonté tel quel.
    /// @param freresADroite pour chaque étape, vrai si le frère est à droite du nœud courant.
    function verifierInclusion(
        bytes32 empreinte,
        bytes32[] calldata freres,
        bool[] calldata freresADroite,
        bytes32 racine
    ) external view returns (bool) {
        if (freres.length != freresADroite.length) revert PreuveMalFormee();
        if (horodatageDe[racine] == 0) return false;
        bytes32 courant = sha256(abi.encodePacked(bytes1(0x00), empreinte));
        for (uint256 i = 0; i < freres.length; i++) {
            courant = freresADroite[i]
                ? sha256(abi.encodePacked(bytes1(0x01), courant, freres[i]))
                : sha256(abi.encodePacked(bytes1(0x01), freres[i], courant));
        }
        return courant == racine;
    }

    /// @notice Arrêt d'urgence des inscriptions (clé du serveur compromise, défaut découvert).
    function suspendre() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function reprendre() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
