import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_frontend/models/form/form_model.dart';

class FormService {
  final Dio _dio;
  FormService(this._dio);

  Future<List<FormSubmissionResponse>> getMyForms() async {
    final response = await _dio.get('/worker/forms');
    return (response.data as List)
        .map((x) => FormSubmissionResponse.fromJson(x))
        .toList();
  }

  Future<FormSubmissionResponse> updateValues(
    int submissionId,
    List<FormFieldValueDto> values,
  ) async {
    final response = await _dio.put(
      '/worker/forms/$submissionId/values',
      data: values.map((v) => v.toJson()).toList(),
    );
    return FormSubmissionResponse.fromJson(response.data);
  }

  Future<FormSubmissionResponse> submitForm(int submissionId) async {
    final response = await _dio.post('/worker/forms/$submissionId/submit');
    return FormSubmissionResponse.fromJson(response.data);
  }

  Future<FormSubmissionResponse> uploadFile(
    int submissionId,
    int fieldId,
    File file,
  ) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _dio.post(
      '/worker/forms/$submissionId/fields/$fieldId/file',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return FormSubmissionResponse.fromJson(response.data);
  }

  Future<String> downloadPdf(int submissionId, String formTitle) async {
    try {
      // 1. Generate a unique timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 2. Append timestamp to URL to bypass Dio/Network HTTP caching
      final response = await _dio.get(
        '/worker/forms/$submissionId/pdf?t=$timestamp',
        options: Options(
          responseType: ResponseType.bytes,
          // Optional: Explicitly tell Dio not to use cached headers
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ),
      );

      final directory = await getApplicationDocumentsDirectory();

      // Sanitize the title to prevent path errors with special characters
      final safeTitle = formTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      // 3. Append timestamp to filename so the OS & PDF viewer treats it as a brand new file
      final filePath =
          '${directory.path}/form_${submissionId}_${safeTitle}_$timestamp.pdf';
      final file = File(filePath);

      // flush: true ensures bytes are fully written to physical storage before opening
      await file.writeAsBytes(response.data, flush: true);

      return filePath;
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }
}
