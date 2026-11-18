import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/widgets/attachment_preview.dart';
import 'package:url_launcher/url_launcher.dart';

class TimelineItemWidget extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;
  final int currentWorkerId;

  const TimelineItemWidget({
    super.key,
    required this.event,
    required this.isLast,
    required this.currentWorkerId,
  });

  // Helper method to open URLs
  Future<void> _openFileUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      // mode: LaunchMode.externalApplication is crucial.
      // It forces the OS to open the browser/PDF viewer, which allows downloading.
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
    }
  }

  // Helper to show full screen image
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _openFileUrl(context, imageUrl),
                tooltip: "Download/Open in Browser",
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true, // Set it to false to prevent panning.
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d, yyyy • h:mm a').format(event.createdAt);
    final displayName = event.actorId == currentWorkerId
        ? "You"
        : (event.actorUsername ?? "User #${event.actorId}");

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarLine(),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(displayName, time),
                  const SizedBox(height: 6),
                  // Display Description if it exists
                  if (event.description != null &&
                      event.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        event.description!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  if (event.isAttachment ||
                      event.fileUrl != null ||
                      event.thumbnailUrl != null)
                    _buildAttachmentContent(context)
                  else
                    _buildCommentContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarLine() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Colors.black54, size: 20),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.grey[300],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(String name, String time) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: event.discussionType.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            event.discussionType.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(
        event.content,
        style: const TextStyle(fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget _buildAttachmentContent(BuildContext context) {
    final fileUrl = event.fileUrl;
    final preview = AttachmentPreview(
      fileUrl: fileUrl,
      thumbnailUrl: event.thumbnailUrl,
      fileName: event.content,
    );
    final VoidCallback? openFile = fileUrl == null || fileUrl.isEmpty
        ? null
        : () {
            if (preview.isImage) {
              _showFullScreenImage(context, fileUrl);
            } else {
              _openFileUrl(context, fileUrl);
            }
          };

    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview.hasSource)
            InkWell(
              onTap: openFile,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(height: 150, child: preview),
              ),
            ),
          if (!preview.isImage || !preview.hasSource)
            _buildFileTile(context, openFile),
        ],
      ),
    );
  }

  Widget _buildFileTile(BuildContext context, VoidCallback? openFile) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.description, color: Theme.of(context).primaryColor),
      ),
      title: Text(
        event.content.isNotEmpty ? event.content : "Attachment",
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: openFile == null
          ? null
          : const Text(
              "Tap to open",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
      onTap: openFile,
    );
  }
}
