import 'package:flutter/material.dart';
import '../../data/offers_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/status_badge.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Les offres MonDo'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          for (final offer in offers) ...[
            _OfferCard(offer: offer),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: offer.isCurrent ? AppColors.green : AppColors.border,
          width: offer.isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (offer.isCurrent)
                const StatusBadge(
                  label: 'Ton offre',
                  background: AppColors.mint,
                  foreground: AppColors.green,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            offer.price,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 12),
          for (final feature in offer.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 18, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          if (offer.actionLabel != null) ...[
            const SizedBox(height: 6),
            AppButton(
              label: offer.actionLabel!,
              background: Colors.white,
              foreground: AppColors.textDark,
              borderColor: AppColors.border,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Aperçu : le changement d'offre arrive bientôt"),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}