import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_client_provider.dart';
import '../providers/auth_provider.dart';
import '../services/espace_service.dart';
import '../theme/app_colors.dart';

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
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: enfants),
      bottomNavigationBar: bas == null
          ? null
          : SafeArea(minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: bas!),
    );
  }
}

class Titre extends StatelessWidget {
  const Titre(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(texte, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      );
}

class Note extends StatelessWidget {
  const Note(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(texte, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
      );
}

/// Bloc blanc à filet fin.
class Bloc extends StatelessWidget {
  const Bloc({super.key, required this.enfants});

  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          for (var i = 0; i < enfants.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
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
  final bool accent; // orange : demande une action

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    color: accent ? const Color(0xFFB45309) : AppColors.textDark,
                  ),
                ),
              ),
            if (onTap != null) const Padding(
              padding: EdgeInsets.only(left: 6),
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

/// Champ de saisie simple.
class Champ extends StatelessWidget {
  const Champ({super.key, required this.controleur, required this.libelle, this.clavier, this.indice, this.prefixe});

  final TextEditingController controleur;
  final String libelle;
  final TextInputType? clavier;
  final String? indice;
  final String? prefixe;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controleur,
          keyboardType: clavier,
          decoration: InputDecoration(labelText: libelle, hintText: indice, prefixText: prefixe),
        ),
      );
}

/// Statut en texte seul : encre, gris si inactif, orange si une action est attendue.
enum Ton { encre, gris, action }

TextStyle styleStatut(Ton ton) => TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: switch (ton) { Ton.encre => AppColors.textDark, Ton.gris => AppColors.textMuted, Ton.action => AppColors.orange },
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
              child: ChoiceChip(
                label: Text(e.value, style: TextStyle(color: e.key == actif ? Colors.white : AppColors.textDark)),
                selected: e.key == actif,
                onSelected: (_) => onChange(e.key),
              ),
            ),
        ]),
      );
}

/// Contenu d'une donnée chargée : chargement, erreur lisible avec « Réessayer », puis les données.
List<Widget> selon<T>(AsyncValue<T> v, List<Widget> Function(T) donnees, {VoidCallback? reessayer}) => v.when(
      loading: () => const [Padding(padding: EdgeInsets.only(top: 24), child: LinearProgressIndicator())],
      error: (e, _) => [
        Note(messageErreur(e)),
        if (reessayer != null) Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: reessayer, child: const Text('Réessayer'))),
      ],
      data: donnees,
    );

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
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  if (statut != null) ...[const SizedBox(width: 12), Text(statut!, style: styleStatut(ton))],
                ]),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(detail!, style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.35)),
                ],
                if (bas != null) ...[const SizedBox(height: 12), bas!],
              ]),
            ),
          ),
        ),
      );
}

/// Ligne à la manière du profil : icône à gauche, intitulé (et valeur à droite), détail en dessous, sans cadre.
/// `marge` : 20 sur un écran sans marge latérale, 0 dans une liste déjà décalée de 20.
class RangeeIcone extends StatelessWidget {
  const RangeeIcone({
    super.key,
    required this.icone,
    required this.titre,
    this.detail,
    this.valeur,
    this.onTap,
    this.couleurIcone,
    this.accent = false,
    this.marge = 20,
  });

  final IconData icone;
  final String titre;
  final String? detail;
  final String? valeur;
  final VoidCallback? onTap;
  final Color? couleurIcone;
  final bool accent; // orange : demande une action
  final double marge;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(marge, 13, marge, 13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icone, size: 24, color: couleurIcone ?? (accent ? AppColors.orange : AppColors.textMuted)),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(titre, style: const TextStyle(fontSize: 16))),
                  if (valeur != null)
                    Text(valeur!,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: accent ? AppColors.orange : AppColors.textDark)),
                ]),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!, style: TextStyle(fontSize: 13.5, color: accent ? AppColors.orange : AppColors.textMuted)),
                ],
              ]),
            ),
          ]),
        ),
      );
}

/// Trait fin entre deux `RangeeIcone`, aligné sur le texte.
class TraitRangee extends StatelessWidget {
  const TraitRangee({super.key, this.marge = 20});

  final double marge;

  @override
  Widget build(BuildContext context) => Divider(height: 1, thickness: 1, indent: marge + 46, color: AppColors.border);
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
