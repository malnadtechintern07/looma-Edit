import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../services/app_actions_service.dart';

/// In-app 1–5 star rating dialog for ProCut
class RateUsDialog extends StatefulWidget {
  final bool isFirstExport;

  const RateUsDialog({
    super.key,
    this.isFirstExport = false,
  });

  @override
  State<RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<RateUsDialog> {
  int _selectedRating = 5;
  bool _isSubmitting = false;

  String _getRatingFeedback(int rating) {
    switch (rating) {
      case 5:
        return 'Loved it! 🌟';
      case 4:
        return 'Great experience! 👍';
      case 3:
        return 'Good, but could be better 🙂';
      case 2:
        return 'Needs improvement 😕';
      case 1:
      default:
        return 'Not satisfied 😞';
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Save rating locally & mark first export prompt as shown
    await AppActionsService.saveUserRating(_selectedRating);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Open ProCut's Google Play Store listing
    await AppActionsService.openPlayStore();

    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Thank you for rating ProCut! Opening Google Play Store...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleCancel() async {
    if (widget.isFirstExport) {
      await AppActionsService.markFirstExportRatingShown();
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('rate_us_dialog'),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold Star Header Badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFB800),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              widget.isFirstExport ? 'Enjoying ProCut?' : 'Rate ProCut Video Editor',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              widget.isFirstExport
                  ? 'Congratulations on your first export! How would you rate your video editing experience?'
                  : 'Your feedback helps us make ProCut even better. How would you rate your editing experience?',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            // 1-5 Interactive Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= _selectedRating;
                return GestureDetector(
                  key: Key('rate_us_star_$starValue'),
                  onTap: () {
                    setState(() {
                      _selectedRating = starValue;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected ? const Color(0xFFFFB800) : const Color(0xFFD1D5DB),
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // Sentiment text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _getRatingFeedback(_selectedRating),
                key: ValueKey<int>(_selectedRating),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Primary Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('rate_us_submit_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel / Not Now Button
            TextButton(
              key: const Key('rate_us_cancel_button'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9CA3AF),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: _handleCancel,
              child: const Text(
                'Not Now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to open ProCut's Rate Us dialog
Future<void> showRateUsDialog(
  BuildContext context, {
  bool isFirstExport = false,
}) async {
  if (isFirstExport) {
    // Immediately mark shown so that subsequent exports never prompt again
    await AppActionsService.markFirstExportRatingShown();
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => RateUsDialog(isFirstExport: isFirstExport),
  );
}
