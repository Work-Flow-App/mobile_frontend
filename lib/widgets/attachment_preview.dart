import 'package:flutter/material.dart';

/// Renders the server thumbnail without treating the underlying file as an image.
/// Older image attachments can still use their original URL as a fallback.
class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    super.key,
    required this.fileUrl,
    this.thumbnailUrl,
    this.fileName,
    this.placeholderColor,
    this.iconColor,
  });

  final String? fileUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final Color? placeholderColor;
  final Color? iconColor;

  static const _imageExtensions = {
    '.bmp',
    '.gif',
    '.jpeg',
    '.jpg',
    '.png',
    '.wbmp',
    '.webp',
  };

  bool get isImage {
    final filePath = Uri.tryParse(fileUrl?.trim() ?? '')?.path;
    return _hasImageExtension(fileName) || _hasImageExtension(filePath);
  }

  bool get hasSource => _thumbnail != null || _originalImage != null;

  String? get _thumbnail => _nonEmpty(thumbnailUrl);
  String? get _originalImage => isImage ? _nonEmpty(fileUrl) : null;

  static bool _hasImageExtension(String? name) {
    final normalized = name?.trim().toLowerCase();
    return normalized != null && _imageExtensions.any(normalized.endsWith);
  }

  static String? _nonEmpty(String? url) {
    final trimmed = url?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = _thumbnail;
    final originalImage = _originalImage;
    final fit = isImage ? BoxFit.cover : BoxFit.contain;
    final placeholder = Center(
      child: Icon(
        isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
        color: iconColor ?? Colors.grey.shade500,
        size: 36,
      ),
    );

    Widget loadImage(String url, Widget Function() onError) {
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        semanticLabel: 'Attachment preview',
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return const Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => onError(),
      );
    }

    Widget loadOriginal() => originalImage == null
        ? placeholder
        : loadImage(originalImage, () => placeholder);

    return ColoredBox(
      color: placeholderColor ?? Colors.grey.shade100,
      child: thumbnail != null && thumbnail != originalImage
          ? loadImage(thumbnail, loadOriginal)
          : loadOriginal(),
    );
  }
}
