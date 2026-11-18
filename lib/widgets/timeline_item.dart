import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart'; // Ensure this imports your updated model
import 'package:mobile_frontend/widgets/attachment_preview.dart';
import 'package:intl/intl.dart';

class TimelineItemWidget extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;
  final int currentWorkerId; // Needed to check if "You" posted it

  const TimelineItemWidget({
    super.key,
    required this.event,
    required this.isLast,
    this.currentWorkerId = 1, // Default or passed from parent
  });

  @override
  Widget build(BuildContext context) {
    // FIX 1: Use 'createdAt' instead of 'timestamp'
    final timeAgo = DateFormat.jm().format(event.createdAt);

    // FIX 2: Derive username from 'actorId'
    // In a real app, you would look up the user's name from a provider/cache.
    final displayName = event.actorId == currentWorkerId
        ? "You"
        : "User #${event.actorId}";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- AVATAR & LINE ---
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.white24)),
            ],
          ),
          const SizedBox(width: 16),

          // --- CONTENT ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Name + Time)
                  Row(
                    children: [
                      Text(
                        displayName, // Fixed Name
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Body (Attachment vs Text)
                  if (event.isAttachment ||
                      event.fileUrl != null ||
                      event.thumbnailUrl != null)
                    _buildAttachmentView()
                  else
                    Text(
                      event.content,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentView() {
    final preview = AttachmentPreview(
      fileUrl: event.fileUrl,
      thumbnailUrl: event.thumbnailUrl,
      fileName: event.content,
      placeholderColor: Colors.grey.shade800,
      iconColor: Colors.white54,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Uploaded an attachment:",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(height: preview.hasSource ? 150 : 72, child: preview),
        ),
        if (!preview.isImage || !preview.hasSource) ...[
          const SizedBox(height: 4),
          Text(
            event.content,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ],
    );
  }
}
