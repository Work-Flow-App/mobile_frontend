import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';

// --- Models to track state of each selected file ---
enum UploadStatus { pending, uploading, success, error }

class DraftAttachment {
  final String path;
  final String fileName;
  final bool isImage;
  StepDiscussionType type;
  UploadStatus status;
  String? errorMessage;

  final TextEditingController descController;

  DraftAttachment({
    required this.path,
    required this.fileName,
    required this.isImage,
    this.type = StepDiscussionType.GENERAL,
    String initialDesc = '',
    this.status = UploadStatus.pending,
  }) : descController = TextEditingController(text: initialDesc);

  void dispose() {
    descController.dispose();
  }
}

// --- The Main Multi-Upload Sheet Widget ---
class MultiAttachmentUploadSheet extends StatefulWidget {
  final Future<void> Function(String path, StepDiscussionType type, String desc)
  onUploadItem;
  final VoidCallback onUploadComplete;

  const MultiAttachmentUploadSheet({
    super.key,
    required this.onUploadItem,
    required this.onUploadComplete,
  });

  @override
  State<MultiAttachmentUploadSheet> createState() =>
      _MultiAttachmentUploadSheetState();
}

class _MultiAttachmentUploadSheetState
    extends State<MultiAttachmentUploadSheet> {
  final List<DraftAttachment> _drafts = [];
  bool _isUploadingAll = false;
  bool _isProcessingFiles =
      false; // New state to track file processing from gallery
  final int _maxFiles = 20;

  // The 10 MB limit in bytes
  final int _maxFileSizeBytes = 10 * 1024 * 1024;

  // Helper method to check if the file on disk is under 10 MB
  bool _isValidFileSize(String path) {
    try {
      final file = File(path);
      return file.lengthSync() <= _maxFileSizeBytes;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    for (var draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  Future _pickFiles(int sourceIndex) async {
    int availableSlots = _maxFiles - _drafts.length;
    if (availableSlots <= 0) {
      _showLimitWarning();
      return;
    }

    // Activate the loading overlay before picking/processing
    setState(() {
      _isProcessingFiles = true;
    });

    List rawPaths = [];
    List newPaths = [];
    int oversizedCount = 0;

    try {
      if (sourceIndex == 0) {
        final img = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
          maxWidth: 1920,
        );
        if (img != null) rawPaths.add(img.path);
      } else if (sourceIndex == 1) {
        final images = await ImagePicker().pickMultiImage(
          imageQuality: 70,
          maxWidth: 1920,
        );
        rawPaths.addAll(images.map((e) => e.path));
      } else if (sourceIndex == 2) {
        final res = await FilePicker.platform.pickFiles(allowMultiple: true);
        if (res != null) {
          rawPaths.addAll(
            res.files.where((f) => f.path != null).map((f) => f.path!),
          );
        }
      }

      // Filter files by size before checking slot limits
      for (var path in rawPaths) {
        if (_isValidFileSize(path)) {
          newPaths.add(path);
        } else {
          oversizedCount++;
        }
      }

      if (oversizedCount > 0 && mounted) {
        String sizeWarningMsg = oversizedCount.toString();
        sizeWarningMsg += ' file(s) skipped (exceeds 10 MB limit)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sizeWarningMsg),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (newPaths.isNotEmpty) {
        if (newPaths.length > availableSlots) {
          final int removedCount = newPaths.length - availableSlots;
          newPaths = newPaths.sublist(0, availableSlots);

          if (mounted) {
            String warningMsg = 'Limit is ';
            warningMsg += _maxFiles.toString();
            warningMsg += '. Removed ';
            warningMsg += removedCount.toString();
            warningMsg += ' extra files.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(warningMsg),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }

        setState(() {
          for (var path in newPaths) {
            _drafts.add(
              DraftAttachment(
                path: path,
                fileName: path.split('/').last,
                isImage: _isImagePath(path),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String errMsg = 'Error picking file: ';
        errMsg += e.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Turn off the loading overlay once files are loaded
      if (mounted) {
        setState(() {
          _isProcessingFiles = false;
        });
      }
    }
  }

  void _showLimitWarning() {
    if (mounted) {
      String limitMsg = 'Maximum limit of ';
      limitMsg += _maxFiles.toString();
      limitMsg += ' attachments reached.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(limitMsg),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeDraft(int index) {
    setState(() {
      _drafts[index].dispose();
      _drafts.removeAt(index);
    });
  }

  Future<void> _uploadAll() async {
    FocusScope.of(context).unfocus();
    setState(() => _isUploadingAll = true);

    bool allSuccess = true;

    for (int i = 0; i < _drafts.length; i++) {
      if (_drafts[i].status == UploadStatus.success) continue;

      setState(() => _drafts[i].status = UploadStatus.uploading);

      try {
        await widget.onUploadItem(
          _drafts[i].path,
          _drafts[i].type,
          _drafts[i].descController.text.trim(),
        );
        setState(() => _drafts[i].status = UploadStatus.success);
      } catch (e) {
        setState(() {
          _drafts[i].status = UploadStatus.error;
          _drafts[i].errorMessage = e.toString();
        });
        allSuccess = false;
      }
    }

    setState(() => _isUploadingAll = false);

    if (allSuccess && mounted) {
      widget.onUploadComplete();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Some files failed to upload. Check errors and try again.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool canAddMore = _drafts.length < _maxFiles;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Container(
            height: size.height * 0.88,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(canAddMore),
                    const Divider(height: 1, color: Colors.black12),
                    Expanded(
                      child: _drafts.isEmpty
                          ? _buildEmptyState(canAddMore)
                          : _buildDraftsList(),
                    ),
                    if (_drafts.isNotEmpty) _buildFooter(),
                  ],
                ),

                // FULL SCREEN LOADING OVERLAY (Now only triggers for Processing Files)
                if (_isProcessingFiles)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(
                          color: Colors.white.withOpacity(0.6),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Processing Files',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please wait while we load your selection...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool canAddMore) {
    String countDisplay = _drafts.length.toString();
    countDisplay += ' / ';
    countDisplay += _maxFiles.toString();
    countDisplay += ' selected';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      countDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        color: _drafts.length >= _maxFiles
                            ? Colors.red.shade600
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionIcon(
                    Icons.camera_alt,
                    Colors.blue,
                    'Camera',
                    canAddMore ? () => _pickFiles(0) : null,
                  ),
                  const SizedBox(width: 8),
                  _buildActionIcon(
                    Icons.photo_library,
                    Colors.purple,
                    'Gallery',
                    canAddMore ? () => _pickFiles(1) : null,
                  ),
                  const SizedBox(width: 8),
                  _buildActionIcon(
                    Icons.attach_file,
                    Colors.orange,
                    'Files',
                    canAddMore ? () => _pickFiles(2) : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback? onTap,
  ) {
    final bool isEnabled = onTap != null;
    return Tooltip(
      message: isEnabled ? tooltip : 'Limit Reached',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled ? color.withOpacity(0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isEnabled ? color : Colors.grey.shade400,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool canAddMore) {
    String emptyLimitStr =
        'Select files or take photos to attach to this step.\nUp to ';
    emptyLimitStr += _maxFiles.toString();
    emptyLimitStr += ' files allowed.';

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No attachments yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyLimitStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildBigOption(
                  Icons.camera_alt,
                  Colors.blue,
                  'Camera',
                  canAddMore ? () => _pickFiles(0) : null,
                ),
                _buildBigOption(
                  Icons.photo_library,
                  Colors.purple,
                  'Gallery',
                  canAddMore ? () => _pickFiles(1) : null,
                ),
                _buildBigOption(
                  Icons.insert_drive_file,
                  Colors.orange,
                  'File',
                  canAddMore ? () => _pickFiles(2) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigOption(
    IconData icon,
    Color color,
    String label,
    VoidCallback? onTap,
  ) {
    final bool isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.15) : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isEnabled ? color.withOpacity(0.05) : Colors.transparent,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? color : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _drafts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return _buildAttachmentCard(draft, index);
      },
    );
  }

  Widget _buildAttachmentCard(DraftAttachment draft, int index) {
    final isLocked = draft.status == UploadStatus.success;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: draft.status == UploadStatus.error
              ? Colors.red.shade300
              : draft.status == UploadStatus.success
              ? Colors.green.shade300
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: draft.isImage
                    ? Image.file(
                        File(draft.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              draft.fileName.toUpperCase().split('.').last,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade500,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (!isLocked)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _removeDraft(index),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(top: 12, left: 12, child: _buildStatusBadge(draft)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StepDiscussionType>(
                  value: draft.type,
                  decoration: InputDecoration(
                    labelText: 'Attachment Type *',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  items: StepDiscussionType.values
                      .where((e) => e != StepDiscussionType.UNKNOWN)
                      .map(
                        (t) => DropdownMenuItem<StepDiscussionType>(
                          value: t,
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 10, color: t.color),
                              const SizedBox(width: 8),
                              Text(
                                t.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isLocked
                      ? null
                      : (val) {
                          if (val != null) setState(() => draft.type = val);
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: draft.descController,
                  enabled: !isLocked,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: 'Add context for this attachment...',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
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

  Widget _buildStatusBadge(DraftAttachment draft) {
    Color bgColor;
    Color textColor;
    String text;
    IconData? icon;

    switch (draft.status) {
      case UploadStatus.pending:
        bgColor = Colors.black.withOpacity(0.6);
        textColor = Colors.white;
        text = 'Pending';
        break;
      case UploadStatus.uploading:
        bgColor = Colors.blue.shade600;
        textColor = Colors.white;
        text = 'Uploading...';
        break;
      case UploadStatus.success:
        bgColor = Colors.green.shade600;
        textColor = Colors.white;
        text = 'Uploaded';
        icon = Icons.check_circle;
        break;
      case UploadStatus.error:
        bgColor = Colors.red.shade600;
        textColor = Colors.white;
        text = 'Failed';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    int successCount = _drafts
        .where((d) => d.status == UploadStatus.success)
        .length;
    bool allSuccess = successCount == _drafts.length && _drafts.isNotEmpty;

    String uploadAllStr = 'Upload All (';
    uploadAllStr += _drafts.length.toString();
    uploadAllStr += ')';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: allSuccess
                  ? Colors.green.shade600
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            // Disable button if files are processing or uploading
            onPressed: (_isUploadingAll || _isProcessingFiles)
                ? null
                : (allSuccess ? widget.onUploadComplete : _uploadAll),
            // Swap text with an elegant row containing a spinner if uploading
            child: _isUploadingAll
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    allSuccess
                        ? 'Done'
                        : successCount > 0
                        ? 'Retry Failed Uploads'
                        : uploadAllStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
