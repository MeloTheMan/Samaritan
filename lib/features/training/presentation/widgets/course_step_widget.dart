import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/course_step.dart';
import '../../domain/entities/media_asset.dart';

class CourseStepWidget extends StatelessWidget {
  final CourseStep step;

  const CourseStepWidget({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Media assets
          if (step.media.isNotEmpty) ...[
            ...step.media.map((media) => _buildMediaWidget(context, media)),
            const SizedBox(height: 16),
          ],

          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontSize: 16,
                ),
          ),

          const SizedBox(height: 24),

          // Key points
          if (step.keyPoints.isNotEmpty) ...[
            Text(
              'Points clés :',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...step.keyPoints.map((point) => _buildKeyPoint(context, point)),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaWidget(BuildContext context, MediaAsset media) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildMediaContent(context, media),
          ),
          if (media.caption != null) ...[
            const SizedBox(height: 8),
            Text(
              media.caption!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, MediaAsset media) {
    switch (media.type) {
      case MediaType.image:
        if (media.url.startsWith('assets/')) {
          return Image.asset(
            media.url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildMediaPlaceholder(context, Icons.image);
            },
          );
        } else {
          return CachedNetworkImage(
            imageUrl: media.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) {
              return _buildMediaPlaceholder(context, Icons.image);
            },
          );
        }

      case MediaType.video:
        return _buildMediaPlaceholder(context, Icons.play_circle_outline);

      case MediaType.animation:
        return _buildMediaPlaceholder(context, Icons.animation);
    }
  }

  Widget _buildMediaPlaceholder(BuildContext context, IconData icon) {
    return Container(
      height: 200,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildKeyPoint(BuildContext context, String point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
