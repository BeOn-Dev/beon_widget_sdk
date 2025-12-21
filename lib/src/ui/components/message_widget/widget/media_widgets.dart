import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Re-export the proper AudioPlayer from audio_helper
export '../../../../helper/audio_helper/audio_player/audio_player.dart';

/// Image widget for chat messages
class MyChatImageWidget extends StatelessWidget {
  final String image;
  final double height;
  final double width;
  final bool isLocal;

  const MyChatImageWidget({
    super.key,
    required this.image,
    this.height = 150,
    this.width = 200,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) {
      return _buildPlaceholder();
    }

    if (isLocal) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        image,
        height: height,
        width: width,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}

/// Video widget for chat messages
class ChatVideoWidget extends StatelessWidget {
  final VideoModel data;

  const ChatVideoWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (data.url.isNotEmpty) {
          final uri = Uri.parse(data.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        height: 150,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              'Video',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoModel {
  final String url;
  final bool isLocal;

  VideoModel({required this.url, this.isLocal = false});
}

/// Document widget for chat messages
class DocumentMessageWidget extends StatelessWidget {
  final String doc;

  const DocumentMessageWidget({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final fileName = doc.split('/').last;

    return GestureDetector(
      onTap: () async {
        if (doc.isNotEmpty) {
          final uri = Uri.parse(doc);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName.isNotEmpty ? fileName : 'Document',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location widget for chat messages
class LocationMessageWidget extends StatelessWidget {
  final double latitude;
  final double longitude;

  const LocationMessageWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = 'https://maps.google.com/?q=$latitude,$longitude';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 120,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 36, color: Colors.red.shade400),
            const SizedBox(height: 8),
            Text(
              'View Location',
              style: TextStyle(
                color: Colors.blue.shade600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
