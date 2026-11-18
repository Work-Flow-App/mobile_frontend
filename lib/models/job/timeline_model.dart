import 'package:flutter/material.dart';

enum TimelineItemType { COMMENT, ATTACHMENT, UNKNOWN }

// New Enum based on your requirements
enum StepDiscussionType {
  GENERAL,
  ADDITIONAL,
  COMPLAINT,
  INTERNAL_NOTE,
  APPROVAL,
  REJECTION,
  UNKNOWN,
}

extension StepDiscussionTypeExtension on StepDiscussionType {
  String get label => name.replaceAll('_', ' ');

  Color get color {
    switch (this) {
      case StepDiscussionType.APPROVAL:
        return Colors.green;
      case StepDiscussionType.REJECTION:
        return Colors.red;
      case StepDiscussionType.COMPLAINT:
        return Colors.orange;
      case StepDiscussionType.INTERNAL_NOTE:
        return Colors.amber;
      case StepDiscussionType.ADDITIONAL:
        return Colors.purple;
      case StepDiscussionType.GENERAL:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class TimelineEvent {
  final int id;
  final TimelineItemType itemType;
  final StepDiscussionType discussionType;
  final String content; // Filename for attachments, text for comments
  final String? description; //for attachments
  final String? fileUrl;
  final String? thumbnailUrl;
  final int actorId;
  final String? actorUsername;
  final DateTime createdAt;

  TimelineEvent({
    required this.id,
    required this.itemType,
    required this.discussionType,
    required this.content,
    this.description,
    this.fileUrl,
    this.thumbnailUrl,
    required this.actorId,
    this.actorUsername,
    required this.createdAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    // Parse Item Type
    TimelineItemType type;
    switch (json['itemType']) {
      case 'COMMENT':
        type = TimelineItemType.COMMENT;
        break;
      case 'ATTACHMENT':
        type = TimelineItemType.ATTACHMENT;
        break;
      default:
        type = TimelineItemType.UNKNOWN;
    }

    StepDiscussionType discType = StepDiscussionType.values.firstWhere(
      (e) => e.name == json['discussionType'],
      orElse: () => StepDiscussionType.GENERAL, // Default
    );

    return TimelineEvent(
      id: json['id'] ?? 0,
      itemType: type,
      discussionType: discType,
      content: json['content'] ?? "",
      description: json['description'],
      fileUrl: json['fileUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      actorId: json['actorId'] ?? 0,
      actorUsername: json['actorUsername'],
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? "")?.toLocal() ??
          DateTime.now(),
    );
  }

  bool get isAttachment => itemType == TimelineItemType.ATTACHMENT;
}
