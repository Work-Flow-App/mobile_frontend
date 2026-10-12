import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
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

// REMOVED UNDERSCORE so parent can access it via GlobalKey
class DynamicFormBuilderState extends State<DynamicFormBuilder> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, FormFieldValueDto> _currentValues = {};
  bool _isSaving = false;

  bool get _isFullySubmitted =>
      widget.form.status == FormSubmissionStatus.SUBMITTED;

  // --- NEW: Public methods for the Parent Screen ---
  bool validateForm() {
    // Triggers all validators, highlights required fields in red if empty
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
      key: _formKey, // Critical for validation
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.form.values.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final field = widget.form.values[index];
                return _buildField(field);
              },
            ),
          ),
          if (!_isFullySubmitted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          // Draft save DOES NOT call validate(), it just saves.
                          _formKey.currentState!.save();
                          setState(() => _isSaving = true);
                          await widget.onSave(_currentValues.values.toList());
                          if (mounted) setState(() => _isSaving = false);
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text(
                    "Save Progress",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            field.fieldLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          if (field.description != null) ...[
            const SizedBox(height: 4),
            Text(
              field.description!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const Divider(height: 24, thickness: 1.5),
        ],
      );
    }

    bool readOnly =
        _isFullySubmitted || field.roleTarget == FormRoleTarget.COMPANY;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(field.fieldLabel, field.required, readOnly),
          if (field.description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                field.description!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          _renderInputControl(field, readOnly),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, bool isRequired, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: readOnly ? Colors.grey.shade700 : Colors.black87,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (readOnly)
              const TextSpan(
                text: ' (Company Info)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _renderInputControl(FormFieldValueResponse field, bool readOnly) {
    switch (field.fieldType) {
      case FormFieldType.TEXT:
      case FormFieldType.TEXT_AREA:
        return TextFormField(
          initialValue: field.value?.toString(),
          readOnly: readOnly,
          maxLines: field.fieldType == FormFieldType.TEXT_AREA ? 4 : 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.transparent : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: field.required
              ? (val) => (val == null || val.trim().isEmpty)
                    ? 'This field is required'
                    : null
              : null,
          onSaved: (val) => _updateValue(
            field.fieldId,
            FormFieldValueDto(fieldId: field.fieldId, stringValue: val),
          ),
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
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: readOnly
              ? null
              : (val) => _updateValue(
                  field.fieldId,
                  FormFieldValueDto(fieldId: field.fieldId, stringValue: val),
                ),
          validator: field.required
              ? (val) => val == null ? 'Please select an option' : null
              : null,
        );

      case FormFieldType.BOOLEAN:
      case FormFieldType.CHECKBOX:
        bool isChecked = field.value == true || field.value == 'true';
        // Wrapped in FormField to allow validation (e.g. Terms & Conditions MUST be checked)
        return FormField<bool>(
          initialValue: isChecked,
          validator: field.required
              ? (val) => val != true ? 'This checkbox is required' : null
              : null,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(state.value! ? "Yes" : "No"),
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
                    padding: const EdgeInsets.only(left: 12),
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
        // Wrapped in FormField to enable Required validation
        return FormField<String>(
          initialValue: field.value?.toString(),
          validator: field.required
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
                    state.didChange(
                      dateStr,
                    ); // Updates UI to remove red error if fixed
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
                    padding: const EdgeInsets.only(top: 8, left: 12),
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
          } catch (e) {}
        }
        // Wrapped in FormField to enable Required validation
        return FormField<List<String>>(
          initialValue: initialSelected,
          validator: field.required
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
                  children: field.options.map((opt) {
                    final isSelected = state.value!.contains(opt);
                    return FilterChip(
                      label: Text(opt),
                      selected: isSelected,
                      selectedColor: Colors.black.withOpacity(0.1),
                      checkmarkColor: Colors.black,
                      onSelected: readOnly
                          ? null
                          : (val) {
                              final newList = List<String>.from(state.value!);
                              if (val)
                                newList.add(opt);
                              else
                                newList.remove(opt);
                              state.didChange(newList); // Update UI
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
                    padding: const EdgeInsets.only(top: 8, left: 12),
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
        // Wrapped in FormField to enable Required validation
        return FormField<String>(
          initialValue: field.fileUrl, // Null if no file
          validator: field.required
              ? (val) =>
                    (val == null || val.isEmpty) ? 'Please upload a file' : null
              : null,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (field.fileUrl != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              field.fileUrl!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Row(
                            children: [
                              const Icon(Icons.attach_file, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(field.fileName ?? "Attached File"),
                              ),
                            ],
                          ),
                  ),
                if (!readOnly)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      field.fileUrl == null ? "Upload File" : "Replace File",
                    ),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(type: FileType.any);
                      if (result != null && result.files.single.path != null) {
                        await widget.onFileUpload(
                          field.fieldId,
                          File(result.files.single.path!),
                        );
                        state.didChange(
                          "uploaded",
                        ); // Clear the validation error immediately
                      }
                    },
                  ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
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
}

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
              );
              if (date != null) {
                setState(() => selectedDate = date);
                widget.onDateSelected(date.toIso8601String());
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.readOnly ? Colors.transparent : Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
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
                    : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            Icon(Icons.calendar_month, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
