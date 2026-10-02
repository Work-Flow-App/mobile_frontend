import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';
import 'package:mobile_frontend/screens/step_detail/step_detail_controller.dart';
import 'package:mobile_frontend/screens/step_detail/step_info_section.dart';
import 'package:mobile_frontend/screens/step_detail/timeline_item_widget.dart';
import 'package:mobile_frontend/screens/step_detail/work_logs_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_frontend/widgets/persistent_text_field.dart';
import 'package:mobile_frontend/screens/step_detail/multi_attachment_upload_sheet.dart';

class StepDetailScreen extends ConsumerStatefulWidget {
  // CHANGED: Accept the full JobData wrapper instead of just JobStep
  final JobData jobData;
  final bool isEmbedded;

  const StepDetailScreen({
    super.key,
    required this.jobData,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends ConsumerState<StepDetailScreen> {
  // Helper method to show a confirmation dialog
  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        onConfirm();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // CHANGED: Use jobData for the provider
    final screenState = ref.watch(stepDetailControllerProvider(widget.jobData));
    final controller = ref.read(
      stepDetailControllerProvider(widget.jobData).notifier,
    );

    // Extract both wrapper and the inner step
    final currentJobData = screenState.jobData;
    final currentStep = currentJobData.step;
    final canEdit = true; // Based on your auth logic

    Widget bodyContent = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildSplitLayout(
            currentJobData,
            currentStep,
            canEdit,
            screenState.isLoading,
            controller,
          );
        } else {
          return _buildMobileLayout(
            currentJobData,
            canEdit,
            screenState.isLoading,
            controller,
          );
        }
      },
    );

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _buildFloatingActionButtons(
          context,
          currentStep,
          canEdit,
          screenState.isLoading,
          controller,
        ),
        body: bodyContent, // Renders straight into the LayoutBuilder
      );
    }

    return Scaffold(
      // Stacked Floating Action Buttons
      floatingActionButton: _buildFloatingActionButtons(
        context,
        currentStep,
        canEdit,
        screenState.isLoading,
        controller,
      ),

      // Wrapped body in NestedScrollView for the dynamic AppBar effect
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text(
                "Step: ${currentStep.name}",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(
                  context,
                  currentJobData,
                ), // Return wrapper on pop
              ),
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Colors.black,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.3),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: AppBranding(
                    color: Colors.black,
                    size: 24,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ];
        },
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return _buildSplitLayout(
                currentJobData,
                currentStep,
                canEdit,
                screenState.isLoading,
                controller,
              );
            } else {
              return _buildMobileLayout(
                currentJobData,
                canEdit,
                screenState.isLoading,
                controller,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(
    BuildContext context,
    JobStep step,
    bool canEdit,
    bool isLoading,
    StepDetailController controller,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (canEdit) ...[
          if (isLoading)
            const FloatingActionButton.extended(
              heroTag: "loading_btn",
              onPressed: null,
              label: CircularProgressIndicator(),
            )
          // CASE 1: NOT STARTED
          else if (step.status == StepStatus.NOT_STARTED)
            FloatingActionButton.extended(
              heroTag: "start_step_btn",
              onPressed: () {
                _showConfirmationDialog(
                  context: context,
                  title: "Start Step",
                  content: "Are you sure you want to start this step?",
                  onConfirm: () async {
                    try {
                      await controller.startStep();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Step"),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            )
          // CASE 2: STARTED (Original complete flow)
          else if (step.status == StepStatus.STARTED)
            FloatingActionButton.extended(
              heroTag: "complete_step_btn",
              onPressed: () {
                _showConfirmationDialog(
                  context: context,
                  title: "Complete Step",
                  content:
                      "Are you sure you want to mark this step as completed?",
                  onConfirm: () async {
                    try {
                      await controller.completeStep();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                );
              },
              icon: const Icon(Icons.check),
              label: const Text("Mark as Completed"),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            )
          // CASE 3: INITIATED (New mark ongoing flow)
          else if (step.status == StepStatus.INITIATED)
            FloatingActionButton.extended(
              heroTag: "mark_ongoing_btn",
              onPressed: () {
                _showConfirmationDialog(
                  context: context,
                  title: "Mark as Ongoing",
                  content:
                      "Are you sure you want to mark this step as ongoing?",
                  onConfirm: () async {
                    try {
                      await controller.markOngoing();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                );
              },
              icon: const Icon(Icons.sync),
              label: const Text("Mark as Ongoing"),
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            )
          // CASE 4: ONGOING (New complete ongoing flow)
          else if (step.status == StepStatus.ONGOING)
            FloatingActionButton.extended(
              heroTag: "complete_ongoing_btn",
              onPressed: () {
                _showConfirmationDialog(
                  context: context,
                  title: "Complete Ongoing Step",
                  content:
                      "Are you sure you want to complete this ongoing step?",
                  onConfirm: () async {
                    try {
                      await controller.completeOngoing();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text("Complete Ongoing Step"),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),

          const SizedBox(height: 16),
        ],

        FloatingActionButton.extended(
          heroTag: "work_logs_btn",
          onPressed: () {
            _showWorkLogsBottomSheet(context, step, canEdit);
          },
          icon: const Icon(Icons.timer),
          label: const Text("Work Logs"),
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
        ),
        const SizedBox(height: 16),

        FloatingActionButton.extended(
          heroTag: "comments_btn",
          onPressed: () {
            _showCommentsBottomSheet(context, step, canEdit);
          },
          icon: const Icon(Icons.comment),
          label: const Text("Activity, Comments & Attachments"),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    JobData jobData, // CHANGED: Pass full wrapper
    bool canEdit,
    bool isLoading,
    StepDetailController controller,
  ) {
    return RefreshIndicator(
      onRefresh: controller.refreshStepData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 200),
        child: StepInfoSection(
          jobData: jobData, // CHANGED
          canEdit: canEdit,
          isLoading: isLoading,
        ),
      ),
    );
  }

  Widget _buildSplitLayout(
    JobData jobData, // CHANGED
    JobStep step, // Kept for bottom sheet
    bool canEdit,
    bool isLoading,
    StepDetailController controller,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: RefreshIndicator(
            onRefresh: controller.refreshStepData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: StepInfoSection(
                jobData: jobData, // CHANGED
                canEdit: canEdit,
                isLoading: isLoading,
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: TimelineBottomSheet(step: step, canEdit: canEdit),
          ),
        ),
      ],
    );
  }

  void _showCommentsBottomSheet(
    BuildContext context,
    JobStep step,
    bool canEdit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TimelineBottomSheet(
                        step: step,
                        canEdit: canEdit,
                        scrollController: scrollController,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showWorkLogsBottomSheet(
    BuildContext context,
    JobStep step,
    bool canEdit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Expanded(
                      child: WorkLogsSheet(
                        step: step,
                        canEdit: canEdit,
                        scrollController: scrollController,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =========================================================================
// WIDGET: The Bottom Sheet Content
// =========================================================================
class TimelineBottomSheet extends ConsumerStatefulWidget {
  final JobStep step;
  final bool canEdit;
  final ScrollController? scrollController;

  const TimelineBottomSheet({
    super.key,
    required this.step,
    required this.canEdit,
    this.scrollController,
  });

  @override
  ConsumerState<TimelineBottomSheet> createState() =>
      _TimelineBottomSheetState();
}

class _TimelineBottomSheetState extends ConsumerState<TimelineBottomSheet> {
  final commentController = TextEditingController();

  // UI State for Filters
  bool _isAttachmentOnlyMode = false;
  Set<StepDiscussionType> _selectedFilterTypes = {};

  // UI State for Input
  StepDiscussionType _inputType = StepDiscussionType.GENERAL;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(stepTimelineProvider(widget.step.id));

    final currentWorkerId = ref.read(jobServiceProvider).currentWorkerId;

    Widget buildListContent() {
      return Container(
        color: Colors.grey[50],
        child: timelineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Error: $err")),
          data: (events) {
            final filteredEvents = _applyFilters(events);

            if (filteredEvents.isEmpty) {
              return RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(stepTimelineProvider(widget.step.id).future),
                child: ListView(
                  controller: widget.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Text(
                        "No items match your filter. Pull to refresh.",
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_isAttachmentOnlyMode) {
              return RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(stepTimelineProvider(widget.step.id).future),
                child: _buildGalleryView(
                  filteredEvents,
                  widget.scrollController,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(stepTimelineProvider(widget.step.id).future),
              child: ListView.builder(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) => TimelineItemWidget(
                  event: filteredEvents[index] as TimelineEvent,
                  isLast: index == filteredEvents.length - 1,
                  currentWorkerId: currentWorkerId,
                ),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTightSpace = constraints.maxHeight < 250;

        if (isTightSpace) {
          return SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAdvancedFilterBar(),
                SizedBox(height: 300, child: buildListContent()),
                if (widget.canEdit && !_isAttachmentOnlyMode) _buildInputArea(),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildAdvancedFilterBar(),
            Expanded(child: buildListContent()),
            if (widget.canEdit && !_isAttachmentOnlyMode) _buildInputArea(),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _showMultiSelectFilterDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFilterTypes.isEmpty
                            ? "All Types"
                            : "${_selectedFilterTypes.length} Selected",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            "Attachments",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Switch(
            value: _isAttachmentOnlyMode,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) => setState(() => _isAttachmentOnlyMode = val),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            tooltip: "Refresh Activity",
            onPressed: () =>
                ref.refresh(stepTimelineProvider(widget.step.id).future),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Filter by Type"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: StepDiscussionType.values
                      .where((e) => e != StepDiscussionType.UNKNOWN)
                      .map((type) {
                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: type.color),
                              const SizedBox(width: 8),
                              Text(type.label),
                            ],
                          ),
                          value: _selectedFilterTypes.contains(type),
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                _selectedFilterTypes.add(type);
                              } else {
                                _selectedFilterTypes.remove(type);
                              }
                            });
                          },
                        );
                      })
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedFilterTypes.clear();
                    });
                  },
                  child: const Text("Clear All"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGalleryView(
    List<dynamic> events,
    ScrollController? scrollController,
  ) {
    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index] as TimelineEvent;
        final isImage =
            event.fileUrl?.toLowerCase().contains('.jpg') == true ||
            event.fileUrl?.toLowerCase().contains('.jpeg') == true ||
            event.fileUrl?.toLowerCase().contains('.png') == true;

        return InkWell(
          onTap: () async {
            if (event.fileUrl != null) {
              await launchUrl(
                Uri.parse(event.fileUrl!),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: isImage && event.fileUrl != null
                        ? Image.network(event.fileUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.insert_drive_file,
                              size: 48,
                              color: event.discussionType.color,
                            ),
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: event.discussionType.color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.discussionType.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: event.discussionType.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.description ?? event.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  "Type: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<StepDiscussionType>(
                    value: _inputType,
                    isDense: true,
                    items: StepDiscussionType.values
                        .where((e) => e != StepDiscussionType.UNKNOWN)
                        .map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.label,
                              style: TextStyle(
                                color: type.color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _inputType = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () => _showAttachmentOptions(),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: PersistentTextField(
                      controller: commentController,
                      maxLines: 5,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () async {
                      try {
                        await ref
                            .read(jobServiceProvider)
                            .addComment(
                              widget.step.id,
                              commentController.text.trim(),
                              _inputType,
                            );
                        commentController.clear();
                        ref.refresh(
                          stepTimelineProvider(widget.step.id).future,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _applyFilters(List<dynamic> events) {
    return events.where((e) {
      if (e is! TimelineEvent) return false;
      if (_isAttachmentOnlyMode && !e.isAttachment) return false;
      if (_selectedFilterTypes.isNotEmpty &&
          !_selectedFilterTypes.contains(e.discussionType)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MultiAttachmentUploadSheet(
          onUploadItem: (path, type, desc) async {
            await ref
                .read(jobServiceProvider)
                .addAttachment(widget.step.id, path, type, desc);
          },
          onUploadComplete: () {
            ref.refresh(stepTimelineProvider(widget.step.id).future);
            if (mounted) Navigator.pop(context);
          },
        );
      },
    );
  }
}
