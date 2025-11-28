import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FileSendDialog extends StatelessWidget {
  const FileSendDialog({
    required this.file,
    required this.args,
    required this.currentUserId,
    required this.onSend,
    super.key,
    this.isLoading = false,
  });

  final PlatformFile file;
  final ChatDetailArgs args;
  final String currentUserId;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scaleWidth = context.scaleWidth;
    final scaleHeight = context.scaleHeight;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 18 * scaleWidth),
      ),
      backgroundColor: Colors.white,
      child: Container(
        constraints: kIsWeb
            ? const BoxConstraints(maxWidth: 400, maxHeight: 300)
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 20 : 20 * scaleWidth,
            vertical: kIsWeb ? 20 : 24 * scaleHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.neural50,
                  borderRadius: BorderRadius.circular(
                    kIsWeb ? 12 : 16 * scaleWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: kIsWeb ? 4 : 8 * scaleWidth,
                      offset: Offset(0, kIsWeb ? 1 : 2 * scaleHeight),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  vertical: kIsWeb ? 16 : 24 * scaleHeight,
                  horizontal: kIsWeb ? 12 : 16 * scaleWidth,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _getIconBgColor(file.extension),
                        borderRadius: BorderRadius.circular(
                          kIsWeb ? 8 : 12 * scaleWidth,
                        ),
                      ),
                      padding: EdgeInsets.all(kIsWeb ? 8 : 12 * scaleWidth),
                      child: Icon(
                        _getIconForFile(file.extension),
                        size: kIsWeb ? 24 : 40 * scaleWidth,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: kIsWeb ? 12 : 16 * scaleWidth),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: AppTextStyles.p2SemiBold(
                              context,
                            ).copyWith(fontSize: kIsWeb ? 14 : 16 * scaleWidth),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: kIsWeb ? 4 : 6),
                          Text(
                            _getFileTypeLabel(file.extension),
                            style: AppTextStyles.captionRegular(context)
                                .copyWith(
                                  color: AppColors.neural502,
                                  fontSize: kIsWeb ? 12 : null,
                                ),
                          ),
                          SizedBox(height: kIsWeb ? 2 : 4 * scaleHeight),
                          Text(
                            '${(file.size / 1024).toStringAsFixed(1)} KB',
                            style: AppTextStyles.captionRegular(context)
                                .copyWith(
                                  color: AppColors.neural502,
                                  fontSize: kIsWeb ? 12 : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: kIsWeb ? 16 : 24 * scaleHeight),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            kIsWeb ? 8 : 10 * scaleWidth,
                          ),
                        ),
                        side: BorderSide(
                          color: AppColors.neural502,
                          width: kIsWeb ? 1 : 1 * scaleWidth,
                        ),
                        foregroundColor: AppColors.neural502,
                        padding: EdgeInsets.symmetric(
                          vertical: kIsWeb ? 10 : 12 * scaleHeight,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: kIsWeb ? 14 : null),
                      ),
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 12 : 16 * scaleWidth),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            kIsWeb ? 8 : 10 * scaleWidth,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: kIsWeb ? 10 : 14 * scaleHeight,
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: kIsWeb ? 16 : 18 * scaleWidth,
                              height: kIsWeb ? 16 : 18 * scaleHeight,
                              child: CircularProgressIndicator(
                                strokeWidth: kIsWeb ? 2 : 2 * scaleWidth,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Send',
                              style: AppTextStyles.p2SemiBold(context).copyWith(
                                color: Colors.white,
                                fontSize: kIsWeb ? 14 : null,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForFile(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'dcm':
        return Icons.medical_services;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getIconBgColor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return Colors.redAccent;
      case 'docx':
        return Colors.blueAccent;
      case 'dcm':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getFileTypeLabel(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return 'PDF Document';
      case 'docx':
        return 'Word Document';
      case 'dcm':
        return 'DICOM File';
      default:
        return 'File';
    }
  }
}
