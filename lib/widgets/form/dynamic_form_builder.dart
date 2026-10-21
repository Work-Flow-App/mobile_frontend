import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_frontend/models/form/form_model.dart';

class DynamicFormBuilder extends StatefulWidget {
  final FormSubmissionResponse form;
  final Function(List<FormFieldValueDto>) onSave;
  final Future<void> Function(int fieldId, File file) onFileUpload;

  // NEW: Added Submit parameters to handle side-by-side buttons
  final VoidCallback? onSubmit;
  final bool isSubmitting;

  const DynamicFormBuilder({
    super.key,
    required this.form,
    required this.onSave,
    required this.onFileUpload,
    this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  State<DynamicFormBuilder> createState() => DynamicFormBuilderState();
}

class DynamicFormBuilderState extends State<DynamicFormBuilder> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, FormFieldValueDto> _currentValues = {};
  bool _isSaving = false;

  bool get _isFullySubmitted =>
      widget.form.status == FormSubmissionStatus.SUBMITTED;

  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  List<FormFieldValueDto> get currentValues {
    _formKey.currentState?.save();
    return _currentValues.values.toList();
  }

  void _updateValue(int fieldId, FormFieldValueDto dto) {
    _currentValues[fieldId] = dto;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: widget.form.values.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: _buildField(field),
                  );
                }).toList(),
              ),
            ),
          ),
          if (!_isFullySubmitted)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // --- SAVE DRAFT BUTTON ---
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: (_isSaving || widget.isSubmitting)
                              ? null
                              : () async {
                                  _formKey.currentState!.save();
                                  setState(() => _isSaving = true);
                                  await widget.onSave(
                                    _currentValues.values.toList(),
                                  );
                                  if (mounted)
                                    setState(() => _isSaving = false);
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade800,
                            side: BorderSide(
                              color: Colors.blue.shade800,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.blue.shade800,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Save Draft",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // --- SUBMIT BUTTON ---
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (widget.isSubmitting || _isSaving)
                              ? null
                              : widget.onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: widget.isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Submit",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
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

  Widget _buildField(FormFieldValueResponse field) {
    if (field.fieldType == FormFieldType.SECTION) {
      return Container(
        margin: const EdgeInsets.only(top: 24, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.shade100),
        ),
        child: Row(
          children: [
            Icon(
              Icons.label_important_rounded,
              color: Colors.indigo.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.fieldLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  if (field.description != null &&
                      field.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        field.description!,
                        style: TextStyle(
                          color: Colors.indigo.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    bool isCompanyField = field.roleTarget == FormRoleTarget.COMPANY;
    bool readOnly = _isFullySubmitted || isCompanyField;
    bool shouldValidate = field.required && !readOnly;

    Color accentColor = _getAccentColor(field.fieldType);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!readOnly)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
        ],
        border: Border.all(
          color: readOnly ? Colors.grey.shade200 : Colors.grey.shade100,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              color: readOnly ? Colors.grey.shade400 : accentColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(
                  field.fieldLabel,
                  field.required,
                  readOnly,
                  isCompanyField,
                ),
                if (field.description != null && field.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      field.description!,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                _renderInputControl(
                  field,
                  readOnly,
                  shouldValidate,
                  accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccentColor(FormFieldType type) {
    switch (type) {
      case FormFieldType.TEXT:
      case FormFieldType.TEXT_AREA:
        return Colors.blue.shade500;
      case FormFieldType.DATE:
        return Colors.purple.shade400;
      case FormFieldType.BOOLEAN:
      case FormFieldType.CHECKBOX:
        return Colors.green.shade500;
      case FormFieldType.DROPDOWN:
      case FormFieldType.MULTI_SELECT:
        return Colors.orange.shade500;
      case FormFieldType.FILE:
        return Colors.red.shade400;
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _buildLabel(
    String label,
    bool isRequired,
    bool readOnly,
    bool isCompanyField,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: readOnly ? Colors.grey.shade600 : Colors.black87,
                ),
                children: [
                  if (isRequired && !readOnly)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (readOnly && !_isFullySubmitted && isCompanyField)
            Tooltip(
              message: "Filled by Company",
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Company",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
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

  Widget _renderInputControl(
    FormFieldValueResponse field,
    bool readOnly,
    bool shouldValidate,
    Color accentColor,
  ) {
    switch (field.fieldType) {
      case FormFieldType.TEXT:
      case FormFieldType.TEXT_AREA:
        return TextFormField(
          initialValue: field.value?.toString(),
          readOnly: readOnly,
          maxLines: field.fieldType == FormFieldType.TEXT_AREA ? 4 : 1,
          style: TextStyle(
            color: readOnly ? Colors.grey.shade700 : Colors.black,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.transparent : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.transparent : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: shouldValidate
              ? (val) => (val == null || val.trim().isEmpty)
                    ? 'This field is required'
                    : null
              : null,
          onSaved: (val) {
            if (!readOnly) {
              _updateValue(
                field.fieldId,
                FormFieldValueDto(fieldId: field.fieldId, stringValue: val),
              );
            }
          },
        );

      case FormFieldType.DROPDOWN:
        String? currentVal = field.value?.toString();
        if (currentVal != null && !field.options.contains(currentVal))
          currentVal = null;
        return DropdownButtonFormField<String>(
          value: currentVal,
          // Expanded standard list items slightly
          isExpanded: true,
          items: field.options
              .map(
                (opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          icon: Icon(
            Icons.expand_more_rounded,
            color: readOnly ? Colors.grey.shade400 : accentColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.transparent : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.transparent : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
          onChanged: readOnly
              ? null
              : (val) => _updateValue(
                  field.fieldId,
                  FormFieldValueDto(fieldId: field.fieldId, stringValue: val),
                ),
          validator: shouldValidate
              ? (val) => val == null ? 'Please select an option' : null
              : null,
        );

      case FormFieldType.BOOLEAN:
      case FormFieldType.CHECKBOX:
        bool isChecked = field.value == true || field.value == 'true';
        return FormField<bool>(
          initialValue: isChecked,
          validator: shouldValidate
              ? (val) => val != true ? 'This checkbox is required' : null
              : null,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: state.value!
                        ? accentColor.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.value!
                          ? accentColor.withOpacity(0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      state.value! ? "Yes" : "No",
                      style: TextStyle(
                        color: readOnly ? Colors.grey.shade600 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: state.value!,
                    activeColor: accentColor,
                    inactiveTrackColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onChanged: readOnly
                        ? null
                        : (val) {
                            state.didChange(val);
                            _updateValue(
                              field.fieldId,
                              FormFieldValueDto(
                                fieldId: field.fieldId,
                                booleanValue: val,
                              ),
                            );
                          },
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );

      case FormFieldType.DATE:
        return FormField<String>(
          initialValue: field.value?.toString(),
          validator: shouldValidate
              ? (val) =>
                    (val == null || val.isEmpty) ? 'Please select a date' : null
              : null,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DatePickerWidget(
                  field: field,
                  readOnly: readOnly,
                  accentColor: accentColor,
                  onDateSelected: (dateStr) {
                    state.didChange(dateStr);
                    _updateValue(
                      field.fieldId,
                      FormFieldValueDto(
                        fieldId: field.fieldId,
                        dateValue: dateStr,
                      ),
                    );
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );

      case FormFieldType.MULTI_SELECT:
        List<String> initialSelected = [];
        if (field.value != null) {
          try {
            initialSelected = List<String>.from(jsonDecode(field.value));
          } catch (e) {
            // fallback
          }
        }
        return FormField<List<String>>(
          initialValue: initialSelected,
          validator: shouldValidate
              ? (val) => (val == null || val.isEmpty)
                    ? 'Please select at least one option'
                    : null
              : null,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: field.options.map((opt) {
                    final isSelected = state.value!.contains(opt);
                    return FilterChip(
                      label: Text(opt),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (readOnly
                                  ? Colors.grey.shade600
                                  : Colors.black87),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      selected: isSelected,
                      backgroundColor: readOnly
                          ? Colors.transparent
                          : Colors.grey.shade100,
                      selectedColor: accentColor,
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: readOnly
                          ? null
                          : (val) {
                              final newList = List<String>.from(state.value!);
                              if (val)
                                newList.add(opt);
                              else
                                newList.remove(opt);
                              state.didChange(newList);
                              _updateValue(
                                field.fieldId,
                                FormFieldValueDto(
                                  fieldId: field.fieldId,
                                  jsonValue: jsonEncode(newList),
                                ),
                              );
                            },
                    );
                  }).toList(),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );

      case FormFieldType.FILE:
        bool isImage =
            field.fileName != null &&
            (field.fileName!.toLowerCase().endsWith('.jpg') ||
                field.fileName!.toLowerCase().endsWith('.png') ||
                field.fileName!.toLowerCase().endsWith('.jpeg'));

        return FormField<String>(
          initialValue: field.fileUrl,
          validator: shouldValidate
              ? (val) =>
                    (val == null || val.isEmpty) ? 'Please attach a file' : null
              : null,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (field.fileUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: InkWell(
                      onTap: () =>
                          _viewAttachment(context, field.fileUrl, isImage),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  field.fileUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.insert_drive_file_rounded,
                                        color: accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        field.fileName ?? "Attached File",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        // FIX: Allow wrapping for file names
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),

                if (!readOnly)
                  InkWell(
                    onTap: () => _showAttachmentOptions(context, field, state),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withOpacity(0.4),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            field.fileUrl == null
                                ? Icons.cloud_upload_rounded
                                : Icons.change_circle_rounded,
                            color: accentColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            field.fileUrl == null
                                ? "Tap to Upload or Draw"
                                : "Replace Attachment",
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _viewAttachment(BuildContext context, String? url, bool isImage) async {
    if (url == null) return;
    if (isImage) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showAttachmentOptions(
    BuildContext context,
    FormFieldValueResponse field,
    FormFieldState<String> state,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 16.0,
              bottom: 20.0 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSheetAction(
                  Icons.image_rounded,
                  Colors.blue,
                  'Pick File / Image',
                  () async {
                    Navigator.pop(ctx);
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(type: FileType.any);
                    if (result != null && result.files.single.path != null) {
                      await widget.onFileUpload(
                        field.fieldId,
                        File(result.files.single.path!),
                      );
                      state.didChange("uploaded");
                    }
                  },
                ),
                _buildSheetAction(
                  Icons.camera_alt_rounded,
                  Colors.green,
                  'Take a Photo',
                  () async {
                    Navigator.pop(ctx);
                    final ImagePicker picker = ImagePicker();
                    final XFile? photo = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (photo != null) {
                      await widget.onFileUpload(
                        field.fieldId,
                        File(photo.path),
                      );
                      state.didChange("uploaded");
                    }
                  },
                ),
                _buildSheetAction(
                  Icons.draw_rounded,
                  Colors.orange,
                  'Draw / Sketch',
                  () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SketchPadScreen(
                          onSave: (File file) async {
                            await widget.onFileUpload(field.fieldId, file);
                            state.didChange("uploaded");
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetAction(
    IconData icon,
    MaterialColor color,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle),
        child: Icon(icon, color: color.shade700),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}

class _DatePickerWidget extends StatefulWidget {
  final FormFieldValueResponse field;
  final bool readOnly;
  final Color accentColor;
  final Function(String) onDateSelected;

  const _DatePickerWidget({
    required this.field,
    required this.readOnly,
    required this.accentColor,
    required this.onDateSelected,
  });
  @override
  State<_DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<_DatePickerWidget> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.field.value != null) {
      try {
        selectedDate = DateTime.parse(widget.field.value.toString());
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.readOnly
          ? null
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: widget.accentColor,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => selectedDate = date);
                widget.onDateSelected(date.toIso8601String());
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: widget.readOnly ? Colors.transparent : Colors.grey.shade50,
          border: Border.all(
            color: widget.readOnly ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate != null
                  ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                  : "Select Date",
              style: TextStyle(
                color: selectedDate != null
                    ? Colors.black
                    : Colors.grey.shade500,
                fontSize: 15,
                fontWeight: selectedDate != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            Icon(
              Icons.calendar_month_rounded,
              color: widget.readOnly
                  ? Colors.grey.shade400
                  : widget.accentColor,
            ),
          ],
        ),
      ),
    );
  }
}

class SketchPadScreen extends StatefulWidget {
  final Function(File) onSave;
  const SketchPadScreen({super.key, required this.onSave});

  @override
  State<SketchPadScreen> createState() => _SketchPadScreenState();
}

class _SketchPadScreenState extends State<SketchPadScreen> {
  late SignatureController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Draw Attachment',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.cleaning_services_rounded,
              color: Colors.grey,
            ),
            tooltip: "Clear",
            onPressed: () => _controller.clear(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (_controller.isNotEmpty) {
                        setState(() => _isSaving = true);
                        final bytes = await _controller.toPngBytes();
                        if (bytes != null) {
                          final tempDir = await getTemporaryDirectory();
                          final file = File(
                            '${tempDir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png',
                          );
                          await file.writeAsBytes(bytes);
                          await widget.onSave(file);
                          if (mounted) Navigator.pop(context);
                        }
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text("Save"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
