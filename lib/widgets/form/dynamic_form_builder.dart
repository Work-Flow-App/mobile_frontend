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

  const DynamicFormBuilder({
    super.key,
    required this.form,
    required this.onSave,
    required this.onFileUpload,
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

  // --- Public methods for the Parent Screen ---
  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  List<FormFieldValueDto> get currentValues {
    _formKey.currentState?.save(); // Ensures latest typed text is captured
    return _currentValues.values.toList();
  }
  // ------------------------------------------------

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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: widget.form.values.length,
              itemBuilder: (context, index) {
                final field = widget.form.values[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildField(field),
                );
              },
            ),
          ),
          if (!_isFullySubmitted)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            _formKey.currentState!.save();
                            setState(() => _isSaving = true);
                            await widget.onSave(_currentValues.values.toList());
                            if (mounted) setState(() => _isSaving = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
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
                              Icon(Icons.save_outlined),
                              SizedBox(width: 8),
                              Text(
                                "Save Draft",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(FormFieldValueResponse field) {
    if (field.fieldType == FormFieldType.SECTION) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.fieldLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.blueGrey.shade700,
              ),
            ),
            if (field.description != null && field.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                field.description!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
          ],
        ),
      );
    }

    bool isCompanyField = field.roleTarget == FormRoleTarget.COMPANY;
    bool readOnly = _isFullySubmitted || isCompanyField;
    bool shouldValidate = field.required && !readOnly;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!readOnly)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: readOnly ? Colors.grey.shade200 : Colors.grey.shade100,
        ),
      ),
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
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          _renderInputControl(field, readOnly, shouldValidate),
        ],
      ),
    );
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
                  fontWeight: FontWeight.w600,
                  color: readOnly ? Colors.grey.shade700 : Colors.black87,
                ),
                children: [
                  if (isRequired && !readOnly)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
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
              child: Icon(
                Icons.lock_outline,
                size: 16,
                color: Colors.grey.shade400,
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
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.transparent : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
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
          items: field.options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: readOnly ? Colors.grey.shade400 : Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.transparent : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.transparent : Colors.grey.shade300,
              ),
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
                SwitchListTile(
                  title: Text(
                    state.value! ? "Yes" : "No",
                    style: TextStyle(
                      color: readOnly ? Colors.grey.shade600 : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: state.value!,
                  activeColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
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
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
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
                  spacing: 10,
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
                      selectedColor: readOnly
                          ? Colors.grey.shade400
                          : Colors.black,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                              if (val) {
                                newList.add(opt);
                              } else {
                                newList.remove(opt);
                              }
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  field.fileUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.description,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        field.fileName ?? "Attached File",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.open_in_new,
                                      color: Colors.grey.shade500,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),

                if (!readOnly)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        field.fileUrl == null
                            ? Icons.add_circle_outline
                            : Icons.change_circle_outlined,
                      ),
                      label: Text(
                        field.fileUrl == null
                            ? "Add Attachment"
                            : "Replace Attachment",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () =>
                          _showAttachmentOptions(context, field, state),
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

  // --- Attachment Handlers ---

  void _viewAttachment(BuildContext context, String? url, bool isImage) async {
    if (url == null) return;
    if (isImage) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open file.')));
        }
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
      isScrollControlled: true, // Fix for landscape overflow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          // Fix for bottom overflow when space is constrained
          child: Padding(
            padding: EdgeInsets.only(
              top: 20.0,
              bottom: 20.0 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.image, color: Colors.blue.shade700),
                  ),
                  title: const Text(
                    'Pick Image / Document',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
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
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.green.shade700),
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
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
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.draw, color: Colors.orange.shade700),
                  ),
                  title: const Text(
                    'Draw / Sketch',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
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
}

// --- Specialized UI Widgets ---

class _DatePickerWidget extends StatefulWidget {
  final FormFieldValueResponse field;
  final bool readOnly;
  final Function(String) onDateSelected;

  const _DatePickerWidget({
    required this.field,
    required this.readOnly,
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
                      colorScheme: const ColorScheme.light(
                        primary: Colors.black,
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
            color: widget.readOnly ? Colors.transparent : Colors.grey.shade300,
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
              ),
            ),
            Icon(
              Icons.calendar_month,
              color: widget.readOnly ? Colors.grey.shade400 : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

// --- New Draw/Sketch Screen ---

class SketchPadScreen extends StatefulWidget {
  final Function(File) onSave;
  const SketchPadScreen({super.key, required this.onSave});

  @override
  State<SketchPadScreen> createState() => _SketchPadScreenState();
}

class _SketchPadScreenState extends State<SketchPadScreen> {
  late SignatureController _controller;

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
              onPressed: () async {
                if (_controller.isNotEmpty) {
                  final bytes = await _controller.toPngBytes();
                  if (bytes != null) {
                    final tempDir = await getTemporaryDirectory();
                    final file = File(
                      '${tempDir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png',
                    );
                    await file.writeAsBytes(bytes);
                    widget.onSave(file);
                    if (mounted) Navigator.pop(context);
                  }
                }
              },
              icon: const Icon(Icons.check, size: 18),
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
