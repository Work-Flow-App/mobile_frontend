import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/providers/form/form_provider.dart';
import 'package:mobile_frontend/models/form/form_model.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';

class AssignedFormsScreen extends ConsumerWidget {
  const AssignedFormsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formsAsync = ref.watch(assignedFormsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Forms",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: AppBranding(color: Colors.black, size: 24, fontSize: 18),
          ),
        ],
      ),
      body: formsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.black)),
        error: (err, _) => Center(child: Text("Error loading forms: $err")),
        data: (forms) {
          if (forms.isEmpty)
            return const Center(
              child: Text(
                "No forms assigned to you.",
                style: TextStyle(color: Colors.grey),
              ),
            );

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(assignedFormsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: forms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final form = forms[index];
                return InkWell(
                  onTap: () => context.push('/form-detail', extra: form),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              form.templateName,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: form.status.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                form.status.label,
                                style: TextStyle(
                                  color: form.status.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          form.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (form.jobRef != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Job Ref: #${form.jobRef}",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
