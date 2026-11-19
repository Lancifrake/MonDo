import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_client_provider.dart';
import '../providers/auth_provider.dart';
import '../services/espace_service.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'fond_motif.dart';

export '../providers/auth_provider.dart' show messageErreur;

/// Service des écrans « espace » (compte, sécurité, vie d'une tontine).
final espaceServiceProvider = Provider<EspaceService>((ref) => EspaceService(ref.watch(apiClientProvider)));

/// Briques d'écran sobres, communes aux pages ajoutées : du texte, des filets,
/// pas d'emoji ni de pastille colorée.
class Ecran extends StatelessWidget {
  const Ecran({super.key, required this.titre, required this.enfants, this.actions, this.bas});

  final String titre;
  final List<Widget> enfants;
  final List<Widget>? actions;
  final Widget? bas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: actions,
      ),
      body: FondMotif(child: ListView(
        padding: const EdgeInsets.fromLTRB(Espace.ecran, Espace.sm, Espace.ecran, Espace.xl),
        children: enfants,
      )),
      bottomNavigationBar: bas == null
          ? null
          : SafeArea(minimum: const EdgeInsets.fromLTRB(Espace.ecran, Espace.sm, Espace.ecran, Espace.base), child: bas!),
    );
  }
}

class Titre extends StatelessWidget {
  const Titre(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Espace.lg, bottom: Espace.sm),
        child: Text(texte, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      );
}

class Note extends StatelessWidget {
  const Note(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(texte, style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
      );
}

/// Bloc blanc à filet fin.
class Bloc extends StatelessWidget {
  const Bloc({super.key, required this.enfants});

  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Rayon.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          for (var i = 0; i < enfants.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border),
            enfants[i],
          ],
        ]),
      );
}

/// Ligne « libellé : valeur », éventuellement cliquable.
class Ligne extends StatelessWidget {
  const Ligne(this.libelle, {super.key, this.valeur, this.onTap, this.accent = false});

  final String libelle;
  final String? valeur;
  final VoidCallback? onTap;
  final bool accent; // vert vif : demande une action

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espace.base, vertical: Espace.base),
          child: Row(children: [
            Expanded(flex: 3, child: Text(libelle, style: const TextStyle(fontSize: 15))),
            if (valeur != null)
              Flexible(
                flex: 2,
                child: Text(
                  valeur!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accent ? AppColors.action : AppColors.textDark,
                  ),
                ),
              ),
            if (onTap != null) Padding(
              padding: EdgeInsets.only(left: Espace.sm),
              child: Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
            ),
          ]),
        ),
      );
}

/// Affiche une erreur serveur lisible.
void afficherErreur(BuildContext context, Object e) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreur(e))));
}

void afficherMessage(BuildContext context, String texte) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
}

/// Date courte lisible : 18 nov. 2026.
String dateCourte(String? iso) {
  if (iso == null) return '—';
  const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '—';
  return '${d.day} ${mois[d.month - 1]} ${d.year}';
}

/// Champ de saisie simple. L'erreur s'affiche sous le champ, bordure rouge, au lieu d'une snackbar.
class Champ extends StatelessWidget {
  const Champ({
    super.key,
    required this.controleur,
    required this.libelle,
    this.clavier,
    this.indice,
    this.prefixe,
    this.aide,
    this.erreur,
    this.secret = false,
    this.chiffresMax,
    this.onChanged,
  });

  final TextEditingController controleur;
  final String libelle;
  final TextInputType? clavier;
  final String? indice;
  final String? prefixe;

  /// Phrase d'aide sous le champ (format attendu, par exemple).
  final String? aide;

  /// Message d'erreur : remplace l'aide et passe la bordure en rouge.
  final String? erreur;

  /// Masque la saisie (code secret, PIN).
  final bool secret;

  /// N'accepte que des chiffres, au plus ce nombre.
  final int? chiffresMax;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Espace.md),
        child: TextField(
          controller: controleur,
          keyboardType: chiffresMax != null ? TextInputType.number : clavier,
          obscureText: secret,
          enableSuggestions: !secret,
          autocorrect: !secret,
          onChanged: onChanged,
          inputFormatters: chiffresMax == null
              ? null
              : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(chiffresMax)],
          decoration: InputDecoration(
            labelText: libelle,
            hintText: indice,
            prefixText: prefixe,
            helperText: aide,
            helperMaxLines: 3,
            errorText: erreur,
            errorMaxLines: 3,
          ),
        ),
      );
}

/// Statut en texte seul : encre, gris si inactif, vert vif si une action est attendue.
enum Ton { encre, gris, action }

TextStyle styleStatut(Ton ton) => TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: switch (ton) { Ton.encre => AppColors.textDark, Ton.gris => AppColors.textMuted, Ton.action => AppColors.action },
    );

/// Rangée de filtres : le choix actif est en encre pleine, les autres en filet.
class Filtres extends StatelessWidget {
  const Filtres({super.key, required this.choix, required this.actif, required this.onChange});

  final Map<String, String> choix; // valeur -> libellé
  final String actif;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final e in choix.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              // Pastilles bien rondes. Seule la pastille choisie se détache (encre foncée le jour,
              // claire la nuit) ; les autres prennent la couleur du fond, avec un simple filet.
              child: ChoiceChip(
                label: Text(e.value, style: TextStyle(color: e.key == actif ? AppColors.surface : AppColors.textDark)),
                selected: e.key == actif,
                onSelected: (_) => onChange(e.key),
                shape: StadiumBorder(side: BorderSide(color: e.key == actif ? AppColors.textDark : AppColors.border)),
                backgroundColor: AppColors.background,
                selectedColor: AppColors.textDark,
              ),
            ),
        ]),
      );
}

/// Contenu d'une donnée chargée : chargement, erreur lisible avec « Réessayer », puis les données.
/// [marge] : retrait latéral du chargement et de l'erreur, pour une liste qui n'a pas de marge à elle.
List<Widget> selon<T>(AsyncValue<T> v, List<Widget> Function(T) donnees, {VoidCallback? reessayer, double marge = 0}) {
  Widget retrait(Widget w) => marge == 0 ? w : Padding(padding: EdgeInsets.symmetric(horizontal: marge), child: w);
  return v.when(
    loading: () => [retrait(const Squelette())],
    error: (e, _) => [
      retrait(Note(messageErreur(e))),
      if (reessayer != null)
        retrait(Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: reessayer, child: const Text('Réessayer')))),
    ],
    data: donnees,
  );
}

/// Carte cliquable à filet fin : un titre, une ligne de détail, un statut à droite.
class Carte extends StatelessWidget {
  const Carte({super.key, required this.titre, this.detail, this.statut, this.ton = Ton.encre, this.onTap, this.bas});

  final String titre;
  final String? detail;
  final String? statut;
  final Ton ton;
  final VoidCallback? onTap;
  final Widget? bas;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Espace.md),
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rayon.md),
            side: BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Espace.base),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  if (statut != null) ...[const SizedBox(width: Espace.md), Text(statut!, style: styleStatut(ton))],
                ]),
                if (detail != null) ...[
                  const SizedBox(height: Espace.xs),
                  Text(detail!, style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.35)),
                ],
                if (bas != null) ...[const SizedBox(height: Espace.md), bas!],
              ]),
            ),
          ),
        ),
      );
}

/// Ligne à la manière du profil : icône à gauche, intitulé (et valeur à droite), détail en dessous, sans cadre.
/// `marge` : 20 sur un écran sans marge latérale, 0 dans une liste déjà décalée de 20.
/// Une ligne qui ouvre une page porte un chevron ; passer `chevron: false` pour une action immédiate
/// (copier, verrouiller).
class RangeeIcone extends StatelessWidget {
  const RangeeIcone({
    super.key,
    required this.icone,
    required this.titre,
    this.detail,
    this.valeur,
    this.onTap,
    this.couleurIcone,
    this.couleur,
    this.accent = false,
    this.danger = false,
    this.chevron,
    this.marge = Espace.ecran,
  });

  final IconData icone;
  final String titre;
  final String? detail;
  final String? valeur;
  final VoidCallback? onTap;
  final Color? couleurIcone;

  /// Couleur de l'icône ET de l'intitulé (rouge pour une action qui efface).
  final Color? couleur;
  final bool accent; // vert vif : demande une action

  /// Avec [accent] : rouge au lieu du vert (quelque chose de dû ou de risqué à traiter).
  final bool danger;
  final bool? chevron;
  final double marge;

  @override
  Widget build(BuildContext context) {
    final avecChevron = chevron ?? onTap != null;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Toucher.min + Espace.sm),
        child: Padding(
          // Le chevron se rapproche un peu du bord, sans jamais donner une marge négative (marge 0 dans une liste).
          padding: EdgeInsets.fromLTRB(marge, Espace.md, avecChevron ? math.max(0, marge - Espace.xs) : marge, Espace.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icone, size: 24, color: couleur ?? couleurIcone ?? (accent ? (danger ? AppColors.rouge : AppColors.action) : AppColors.textMuted)),
            ),
            const SizedBox(width: Espace.iconeTexte),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(titre, style: TextStyle(fontSize: 16, color: couleur ?? AppColors.textDark))),
                  if (valeur != null)
                    Text(valeur!,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: accent ? (danger ? AppColors.rouge : AppColors.action) : AppColors.textDark)),
                ]),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!, style: TextStyle(fontSize: 14, height: 1.35, color: accent ? (danger ? AppColors.rouge : AppColors.action) : AppColors.textMuted)),
                ],
              ]),
            ),
            if (avecChevron)
              Padding(
                padding: EdgeInsets.only(left: Espace.sm, top: 1),
                child: Icon(Icons.chevron_right, size: 22, color: AppColors.textMuted),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Trait fin entre deux lignes à icône, aligné sur le texte.
class TraitRangee extends StatelessWidget {
  const TraitRangee({super.key, this.marge = Espace.ecran});

  final double marge;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, indent: Espace.retraitTrait(marge), color: AppColors.border);
}

/// Chargement : la forme du contenu à venir, en gris pâle qui respire (fixe si les animations sont réduites).
class Squelette extends StatefulWidget {
  const Squelette({super.key, this.lignes = 3});

  final int lignes;

  @override
  State<Squelette> createState() => _SqueletteState();
}

class _SqueletteState extends State<Squelette> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Widget _barre(double largeur, double hauteur) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: largeur,
        child: Container(
          height: hauteur,
          decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(Espace.xs)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final contenu = Semantics(
      label: 'Chargement',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < widget.lignes; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Espace.md),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(Espace.xs)),
              ),
              const SizedBox(width: Espace.iconeTexte),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _barre(i.isEven ? 0.7 : 0.55, 14),
                  const SizedBox(height: Espace.sm),
                  _barre(i.isEven ? 0.45 : 0.6, 12),
                ]),
              ),
            ]),
          ),
      ]),
    );
    if (MediaQuery.of(context).disableAnimations) return contenu;
    return FadeTransition(opacity: Tween(begin: 0.45, end: 1.0).animate(_anim), child: contenu);
  }
}

/// État vide : une icône, un titre, une phrase d'aide et, si utile, l'action qui remplit la liste.
class EtatVide extends StatelessWidget {
  const EtatVide({super.key, required this.icone, required this.titre, this.texte, this.action, this.onAction});

  final IconData icone;
  final String titre;
  final String? texte;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Espace.xl),
        child: Column(children: [
          Icon(icone, size: 40, color: AppColors.textMuted),
          const SizedBox(height: Espace.md),
          Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (texte != null) ...[
            const SizedBox(height: Espace.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(texte!,
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted)),
            ),
          ],
          if (action != null && onAction != null) ...[
            const SizedBox(height: Espace.base),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, Toucher.min)),
              onPressed: onAction,
              child: Text(action!),
            ),
          ],
        ]),
      );
}

/// Liste longue (cotisations confirmées, historique du score, registre) : les `limite` premiers éléments, puis
/// « Tout voir (N) » pour déplier le reste. Les éléments arrivent déjà triés du plus récent au plus ancien.
class ListeLimitee extends StatefulWidget {
  const ListeLimitee({
    super.key,
    required this.nombre,
    required this.construire,
    this.separateur,
    this.limite = 10,
    this.marge = 20,
  });

  final int nombre;
  final Widget Function(int i) construire;
  final Widget? separateur;
  final int limite;
  final double marge;

  @override
  State<ListeLimitee> createState() => _ListeLimiteeState();
}

class _ListeLimiteeState extends State<ListeLimitee> {
  bool _tout = false;

  @override
  Widget build(BuildContext context) {
    final visibles = _tout ? widget.nombre : widget.nombre.clamp(0, widget.limite);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < visibles; i++) ...[
        if (i > 0 && widget.separateur != null) widget.separateur!,
        widget.construire(i),
      ],
      if (widget.nombre > widget.limite)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.marge),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => setState(() => _tout = !_tout),
              child: Text(
                _tout ? 'Voir moins' : 'Tout voir (${widget.nombre})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
    ]);
  }
}
