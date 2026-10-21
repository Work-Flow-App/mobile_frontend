import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/form/form_model.dart';
import 'package:mobile_frontend/services/form/form_service.dart';
import 'package:mobile_frontend/services/network/dio_provider.dart';

final formServiceProvider = Provider((ref) {
  return FormService(ref.watch(dioProvider));
});

final assignedFormsProvider =
    FutureProvider.autoDispose<List<FormSubmissionResponse>>((ref) async {
      return ref.watch(formServiceProvider).getMyForms();
    });

// A provider to hold the currently selected form ID for tablet layouts
final selectedFormIdProvider = StateProvider<int?>((ref) => null);
