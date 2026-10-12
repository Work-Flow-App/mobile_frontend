import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mobile_frontend/models/form/form_model.dart';
import 'package:mobile_frontend/providers/form/form_provider.dart';
import 'package:mobile_frontend/widgets/form/dynamic_form_builder.dart';

class FormDetailScreen extends ConsumerStatefulWidget {
  final FormSubmissionResponse initialForm;
  const FormDetailScreen({super.key, required this.initialForm});

  @override
  ConsumerState<FormDetailScreen> createState() => _FormDetailScreenState();
}

class _FormDetailScreenState extends ConsumerState<FormDetailScreen> {
  // --- NEW: Global Key to access the DynamicFormBuilderState ---
  final GlobalKey<DynamicFormBuilderState> _formBuilderKey =
      GlobalKey<DynamicFormBuilderState>();

  late FormSubmissionResponse currentForm;
  bool _isDownloadingPdf = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    currentForm = widget.initialForm;
  }

  Future<void> _handleSaveValues(List<FormFieldValueDto> values) async {
    try {
      final updatedForm = await ref
          .read(formServiceProvider)
          .updateValues(currentForm.id, values);
      setState(() => currentForm = updatedForm);
      ref.invalidate(assignedFormsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Draft saved successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleFileUpload(int fieldId, File file) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final updatedForm = await ref
          .read(formServiceProvider)
          .uploadFile(currentForm.id, fieldId, file);
      Navigator.pop(context);
      setState(() => currentForm = updatedForm);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleFinalSubmit() async {
    // 1. Trigger Frontend Validation!
    if (!_formBuilderKey.currentState!.validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill out all required fields before submitting.",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; // Stop right here!
    }

    // 2. Automatically save any lingering edits to the backend first
    await _handleSaveValues(_formBuilderKey.currentState!.currentValues);

    // 3. Confirm Intent
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Submit Form?"),
            content: const Text(
              "Once submitted, you will not be able to edit this form. Proceed?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text("Submit"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    // 4. Hit Submit API
    setState(() => _isSubmitting = true);
    try {
      final updatedForm = await ref
          .read(formServiceProvider)
          .submitForm(currentForm.id);
      setState(() => currentForm = updatedForm);
      ref.invalidate(assignedFormsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Form Submitted Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception:", "").trim()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      final path = await ref
          .read(formServiceProvider)
          .downloadPdf(currentForm.id, currentForm.title);
      await OpenFilex.open(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to download PDF: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isDownloadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentForm.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currentForm.templateName,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_isDownloadingPdf)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: "Download PDF",
              onPressed: _downloadPdf,
            ),

          if (currentForm.status != FormSubmissionStatus.SUBMITTED)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _isSubmitting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  // --- CALL THE NEW SUBMIT METHOD ---
                  : TextButton(
                      onPressed: _handleFinalSubmit,
                      child: const Text(
                        "Submit",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
            ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: DynamicFormBuilder(
          key: _formBuilderKey, // --- ATTACH THE KEY HERE ---
          form: currentForm,
          onSave: _handleSaveValues,
          onFileUpload: _handleFileUpload,
        ),
      ),
    );
  }
}
