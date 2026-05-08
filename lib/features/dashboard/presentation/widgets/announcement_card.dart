import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum AnnouncementType { important, event, info }

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String content;
  final String author;
  final String timeAgo;
  final AnnouncementType type;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.content,
    required this.author,
    required this.timeAgo,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _typeLabel,
                  style: TextStyle(
                    color: _typeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeAgo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                author,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _typeColor {
    switch (type) {
      case AnnouncementType.important:
        return AppColors.error;
      case AnnouncementType.event:
        return AppColors.secondary;
      case AnnouncementType.info:
        return AppColors.info;
    }
  }

  String get _typeLabel {
    switch (type) {
      case AnnouncementType.important:
        return 'Penting';
      case AnnouncementType.event:
        return 'Acara';
      case AnnouncementType.info:
        return 'Info';
    }
  }
}
