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
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
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
    if (!_formBuilderKey.currentState!.validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please fill out all required fields before submitting.",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    await _handleSaveValues(_formBuilderKey.currentState!.currentValues);

    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Submit Form?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Submit"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

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
      backgroundColor: const Color(0xFFF8FAFC),
      // Wrapping with NestedScrollView to achieve the Hide-on-scroll AppBar behavior
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentForm.title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentForm.templateName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            floating: true, // Enables hiding on scroll down
            snap: true, // Snaps instantly back when scrolling up
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: Colors.grey.shade200, height: 1.0),
            ),
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
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  tooltip: "Download PDF",
                  onPressed: _downloadPdf,
                ),
            ],
          ),
        ],
        body: DynamicFormBuilder(
          key: _formBuilderKey,
          form: currentForm,
          onSave: _handleSaveValues,
          onFileUpload: _handleFileUpload,
          onSubmit: _handleFinalSubmit, // Handled inside bottom bar now
          isSubmitting: _isSubmitting,
        ),
      ),
    );
  }
}
