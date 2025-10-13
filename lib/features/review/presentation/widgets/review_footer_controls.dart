import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:articlela/app/l10n/app_localizations.dart';
import 'package:articlela/core/widgets/custom_button.dart';

class ReviewFooterControls extends StatelessWidget {
  const ReviewFooterControls({
    super.key,
    required this.onBack,
    required this.onRemove,
    required this.onAdd,
    required this.enableBack,
    required this.enableNext,
  });

  final VoidCallback onBack;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final bool enableBack;
  final bool enableNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            key: const ValueKey('stageReview.backButton'),
            label: l10n.stageReviewBack,
            isPrimary: false,
            onPressed: enableBack ? onBack : null,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomButton(
            key: const ValueKey('stageReview.removeButton'),
            label: l10n.stageReviewNextRemove,
            isPrimary: false,
            onPressed: enableNext ? onRemove : null,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomButton(
            key: const ValueKey('stageReview.addButton'),
            label: l10n.stageReviewNextAdd,
            onPressed: enableNext ? onAdd : null,
          ),
        ),
      ],
    );
  }
}
