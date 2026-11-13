import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isMandatory;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.isMandatory = false,
    required this.child,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      if (isMandatory) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REQUIRED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8C711C),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            const Divider(height: 24, color: AppColors.borders),
            child,
          ],
        ),
      ),
    );
  }
}

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final int maxLines;
  final bool isUncertain;

  const LabeledTextField({
    Key? key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.isUncertain = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
              ),
              if (isUncertain)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline, size: 12, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text(
                        'Verify AI extraction',
                        style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 15, color: AppColors.mainText),
            decoration: InputDecoration(
              hintText: hint,
              fillColor: isUncertain ? const Color(0xFFFFFBEB) : Colors.white,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isUncertain ? AppColors.warning : AppColors.primaryNavy,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
