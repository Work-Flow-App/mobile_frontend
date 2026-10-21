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
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text(
              "My Forms",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: Colors.grey.shade200, height: 1.0),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: AppBranding(color: Colors.black, size: 24, fontSize: 18),
              ),
            ],
          ),
        ],
        body: formsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
          error: (err, _) => Center(
            child: Text(
              "Error loading forms: $err",
              style: const TextStyle(color: Colors.red),
            ),
          ),
          data: (forms) {
            if (forms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_turned_in_rounded,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "All caught up!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No forms are currently assigned to you.",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.refresh(assignedFormsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: forms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final form = forms[index];
                  final statusColor = form.status.color;

                  return InkWell(
                    onTap: () => context.push('/form-detail', extra: form),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 5, color: statusColor),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                            ),
                                            child: Icon(
                                              Icons.file_copy_rounded,
                                              size: 16,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              form.templateName.toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.0,
                                                height: 1.4,
                                              ),
                                              // FIX: Removed single-line constraint to prevent dotted ellipses
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: statusColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            form.status.label.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  form.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (form.jobRef != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.work_outline_rounded,
                                          size: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Job Ref: #${form.jobRef}",
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
