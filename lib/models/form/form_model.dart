import 'dart:convert';
import 'package:flutter/material.dart';

enum FormFieldType {
  TEXT,
  TEXT_AREA,
  DATE,
  CHECKBOX,
  DROPDOWN,
  MULTI_SELECT,
  BOOLEAN,
  FILE,
  SECTION,
}

enum FormRoleTarget { COMPANY, WORKER, BOTH }

enum FormSubmissionStatus { DRAFT, SENT, IN_PROGRESS, SUBMITTED }

extension FormSubmissionStatusExt on FormSubmissionStatus {
  String get label => name.replaceAll('_', ' ');
  Color get color {
    switch (this) {
      case FormSubmissionStatus.SUBMITTED:
        return Colors.green.shade700;
      case FormSubmissionStatus.IN_PROGRESS:
        return Colors.blue.shade700;
      case FormSubmissionStatus.SENT:
        return Colors.orange.shade700;
      case FormSubmissionStatus.DRAFT:
        return Colors.grey.shade700;
    }
  }
}

class FormFieldValueDto {
  final int fieldId;
  final String? stringValue;
  final bool? booleanValue;
  final String? dateValue;
  final String? jsonValue;

  FormFieldValueDto({
    required this.fieldId,
    this.stringValue,
    this.booleanValue,
    this.dateValue,
    this.jsonValue,
  });

  Map<String, dynamic> toJson() => {
    'fieldId': fieldId,
    'stringValue': stringValue,
    'booleanValue': booleanValue,
    'dateValue': dateValue,
    'jsonValue': jsonValue,
  };
}

class FormFieldValueResponse {
  final int? id;
  final int fieldId;
  final String fieldName;
  final String fieldLabel;
  final String? description;
  final FormFieldType fieldType;
  final FormRoleTarget roleTarget;
  final bool required;
  final dynamic value;
  final String? fileUrl;
  final String? fileName;
  final List<String> options; // Parsed from JSON string

  FormFieldValueResponse({
    this.id,
    required this.fieldId,
    required this.fieldName,
    required this.fieldLabel,
    this.description,
    required this.fieldType,
    required this.roleTarget,
    required this.required,
    this.value,
    this.fileUrl,
    this.fileName,
    required this.options,
  });

  factory FormFieldValueResponse.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    if (json['options'] != null && json['options'].toString().isNotEmpty) {
      try {
        parsedOptions = List<String>.from(jsonDecode(json['options']));
      } catch (e) {
        parsedOptions = json['options']
            .toString()
            .split(',')
            .map((e) => e.trim())
            .toList();
      }
    }

    return FormFieldValueResponse(
      id: json['id'],
      fieldId: json['fieldId'],
      fieldName: json['fieldName'],
      fieldLabel: json['fieldLabel'],
      description: json['description'],
      fieldType: FormFieldType.values.byName(json['fieldType']),
      roleTarget: FormRoleTarget.values.byName(json['roleTarget']),
      required: json['required'] ?? false,
      value: json['value'],
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      options: parsedOptions,
    );
  }
}

class FormSubmissionResponse {
  final int id;
  final String title;
  final FormSubmissionStatus status;
  final int templateId;
  final String templateName;
  final int? jobRef;
  final List<FormFieldValueResponse> values;

  FormSubmissionResponse({
    required this.id,
    required this.title,
    required this.status,
    required this.templateId,
    required this.templateName,
    this.jobRef,
    required this.values,
  });

  factory FormSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return FormSubmissionResponse(
      id: json['id'],
      title: json['title'],
      status: FormSubmissionStatus.values.byName(json['status']),
      templateId: json['templateId'],
      templateName: json['templateName'],
      jobRef: json['jobRef'],
      values:
          (json['values'] as List?)
              ?.map((v) => FormFieldValueResponse.fromJson(v))
              .toList() ??
          [],
    );
  }
}
