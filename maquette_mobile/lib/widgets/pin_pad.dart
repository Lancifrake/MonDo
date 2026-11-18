import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onCompleted, this.length = 4});

  final ValueChanged<String> onCompleted; // appelé quand le code est complet
  final int length;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];

  String _pin = '';
  bool _done = false; // évite d'appeler onCompleted deux fois

  void _onKey(String key) {
    if (_done) return;

    if (key == 'back') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }
    if (_pin.length >= widget.length) return;

    setState(() => _pin += key);

    if (_pin.length == widget.length) {
      _done = true;
      final pin = _pin;
      // Petit délai pour voir le dernier point se remplir
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) widget.onCompleted(pin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // pour que le clavier reste centré
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.green : Colors.white,
                  border: Border.all(
                    color: filled ? AppColors.green : AppColors.border,
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.25,
              children:
                  _keys.map((k) => _Key(value: k, onTap: _onKey)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.value, required this.onTap});

  final String value;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink(); // case vide

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => onTap(value),
        child: Center(
          child: value == 'back'
              ? const Icon(Icons.backspace_outlined, size: 24)
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}