import 'dart:io';

import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/local_storage/chat_file_storage.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart' show AppColors;
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/core/utils/web_download_utils.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/bloc/chat_detail_bloc.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_file/open_file.dart';

typedef MessageRetryCallback = void Function(MessageEntity message);

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSenderName,
    required this.senderKey,
    required this.iv,
    super.key,
    this.showSender = true,
    this.isSameSender = false,
    this.showTimeOnWeb = true, // New parameter for web time grouping
    this.onRetry,
  });
  final MessageEntity message;
  final bool isMine;
  final bool showSender;
  final bool showSenderName;
  final bool? isSameSender;
  final bool showTimeOnWeb; // Controls timestamp display on web only
  final MessageRetryCallback? onRetry;
  final String iv;
  final encrypt.Key senderKey;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _fileExistsLocally = false;
  String? _localFilePath;
  double _downloadProgress = 0;
  bool _isDownloading = false;
  bool _downloadFailed = false;
  bool _isCheckingFile = true;

  @override
  void initState() {
    super.initState();
    _checkLocalFile();
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _checkLocalFile();
    }
  }

  Future<void> _checkLocalFile() async {
    if (widget.message.type != 'FILE') return;
    setState(() => _isCheckingFile = true);

    final files = await ChatFileStorage().searchFiles(
      groupId: widget.message.groupId,
      conversationId: widget.message.id,
    );

    if (mounted) {
      setState(() {
        _fileExistsLocally = files.isNotEmpty;
        _localFilePath = files.isNotEmpty ? files.first : null;
        _isCheckingFile = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    debugPrint('🔽 Starting file download process');
    debugPrint('📁 File URL: ${widget.message.fileUrl}');
    debugPrint('📄 File name: ${widget.message.fileName}');
    debugPrint('💻 Platform: ${kIsWeb ? "Web" : "Mobile"}');
    
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadFailed = false;
    });
    
    try {
      final url = widget.message.fileUrl;
      if (url == null || url.isEmpty) {
        debugPrint('❌ Error: No file URL found');
        throw Exception('No file URL found');
      }

      if (kIsWeb) {
        // For web: Use direct browser download instead of Dio fetch
        debugPrint('🌐 Web: Using direct browser download for: $url');
        
        try {
          // Get the original filename (remove .enc if backend adds it)
          String downloadFileName = widget.message.fileName ?? 'download';
          if (downloadFileName.endsWith('.enc')) {
            downloadFileName = downloadFileName.substring(0, downloadFileName.length - 4);
          }
          
          debugPrint('📥 Triggering direct browser download for: $downloadFileName');
          
          // Use WebDownloadUtils.downloadFromUrl for direct download
          WebDownloadUtils.downloadFromUrl(
            url: url,
            fileName: downloadFileName,
          );
          
          debugPrint('✅ Web direct download triggered successfully');
          
          // Show success message for web download
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download started: $downloadFileName'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          setState(() {
            _isDownloading = false;
            _fileExistsLocally = false; // On web, we don't store files locally
          });
        } catch (webError) {
          debugPrint('❌ Web direct download error: $webError');
          debugPrint('📝 Web error type: ${webError.runtimeType}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download failed: ${webError.toString()}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          throw webError;
        }
      } else {
        // For mobile: Use the existing approach with Dio
        debugPrint('📱 Making mobile HTTP request to: $url');
        final dio = Dio();
        
        final options = Options(
          responseType: ResponseType.bytes,
          headers: {
            'User-Agent': 'Chrysalis-Mobile-App',
          },
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 2),
        );
        
        debugPrint('🔗 Request headers: ${options.headers}');
        debugPrint('⏱️ Timeouts - Receive: ${options.receiveTimeout}, Send: ${options.sendTimeout}');
        
        final response = await dio.get<List<int>>(
          url,
          options: options,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              debugPrint('📊 Download progress: ${(progress * 100).toStringAsFixed(1)}% ($received/$total bytes)');
              setState(() {
                _downloadProgress = progress;
              });
            }
          },
        );

        debugPrint('📡 HTTP Response - Status: ${response.statusCode}');
        if (response.statusCode != 200) {
          debugPrint('❌ HTTP Error: Status code ${response.statusCode}');
          throw Exception('Failed to download file - HTTP ${response.statusCode}');
        }
        
        final bytes = response.data!;
        debugPrint('💾 Downloaded ${bytes.length} bytes');

        debugPrint('📱 Processing mobile file save');
        // Save file locally for mobile
        final tempFilePath = '${Directory.systemTemp.path}/${widget.message.fileName}';
        debugPrint('💾 Temp file path: $tempFilePath');
        
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(bytes);
        debugPrint('✅ Temp file written successfully');

        final savedPath = await ChatFileStorage().saveFile(
          groupId: widget.message.groupId,
          conversationId: widget.message.id,
          file: tempFile,
          isSent: widget.isMine,
        );
        debugPrint('💾 File saved to: $savedPath');

        setState(() {
          _fileExistsLocally = true;
          _localFilePath = savedPath;
          _isDownloading = false;
        });

        // Update BLoC with the new local file path for this message
        if (mounted) {
          context.read<ChatDetailBloc>().add(
            UpdateMessageFilePathEvent(
              messageId: widget.message.id,
              filePath: savedPath,
            ),
          );
          debugPrint('📢 BLoC event sent for file path update');
        }
      }
      debugPrint('✅ File download process completed successfully');
    } catch (e) {
      debugPrint('❌ Overall download error: $e');
      debugPrint('📝 Error type: ${e.runtimeType}');
      
      // Enhanced error analysis for DioException
      if (e is DioException) {
        debugPrint('🚨 DioException Details:');
        debugPrint('  - Type: ${e.type}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Response: ${e.response?.statusCode} ${e.response?.statusMessage}');
        debugPrint('  - Response Headers: ${e.response?.headers}');
        debugPrint('  - Request Options: ${e.requestOptions.uri}');
        debugPrint('  - Request Headers: ${e.requestOptions.headers}');
        
        if (e.type == DioExceptionType.connectionError) {
          debugPrint('🌐 CORS/Network Issue Detected:');
          debugPrint('  - This is likely a CORS (Cross-Origin Resource Sharing) issue');
          debugPrint('  - The S3 bucket may not be configured to allow web requests');
          debugPrint('  - Check if S3 bucket has proper CORS policy');
          debugPrint('  - Browser network tab may show more details');
        }
      }
      
      debugPrint('📊 Error stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadFailed = true;
        });
        
        String userFriendlyError = 'Failed to download file';
        if (e is DioException && e.type == DioExceptionType.connectionError) {
          userFriendlyError = 'Network error - please check your connection or try again';
        }
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFriendlyError)));
      }
    }
  }

  void _onFileTap() {
    if (_fileExistsLocally && _localFilePath != null) {
      _openFile();
    } else if (!_isDownloading) {
      _downloadFile();
    }
  }

  Future<void> _openFile() async {
    if (_localFilePath != null) {
      await OpenFile.open(_localFilePath);
    }
  }


  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    final alignment = widget.isMine
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final isFailed =
        widget.isMine && (widget.message.status == 'FAILED' || _downloadFailed);

    // Colors matching Figma
    final bgColor = isFailed
        ? AppColors.failedMessageColor.withValues(alpha: 0.2)
        : widget.isMine
        ? const Color(0xFF25253D) // Dark blue for sent messages
        : const Color(0xFFE5E5E5).withValues(alpha: 0.4); // Light grey with 40% opacity for received
    final textColor = isFailed
        ? Colors.black
        : widget.isMine
        ? Colors.white
        : Colors.black;
    final timeColor = isFailed
        ? Colors.black
        : widget.isMine
        ? kIsWeb ? const Color(0xFF666666) : Colors.white
        : Colors.black;

    // Border radius matching Figma:
    // - Only the LAST message in a consecutive group has pointy edge
    // - Sent messages: pointy bottom-right on last message only
    // - Received messages: pointy bottom-left on last message only
    // showSender (showAvatarImage) = true means it's the FIRST in a group (at bottom of display)
    // So !showSender means it's NOT the first, i.e., consecutive messages above
    final isLastInGroup = widget.showSender; // First in array = last in display (bottom)

    final borderRadius = widget.isMine
        ? BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomRight: Radius.circular(isLastInGroup ? 0 : 10), // Pointy only on last
            bottomLeft: const Radius.circular(10),
          )
        : BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomRight: const Radius.circular(10),
            bottomLeft: Radius.circular(isLastInGroup ? 0 : 10), // Pointy only on last
          );

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisAlignment: widget.isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isMine && kIsWeb)...[
            Padding(
              padding:  EdgeInsets.only(bottom: 12* scaleHeight),
              child: Container(
                padding: EdgeInsets.zero,
                child: CircleAvatar(
                  backgroundImage:
                  widget.message.avatar.isNotEmpty && widget.showSender
                      ? NetworkImage(widget.message.avatar)
                      : null,
                  radius: 12 * scaleWidth,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            12.horizontalSpace,
          ],

          Column(
            crossAxisAlignment: widget.isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [

              if (!widget.isMine && widget.showSenderName) ...[
                Padding(
                  padding: EdgeInsets.only(left: kIsWeb ? 0 : 30),
                  child: Text(
                    '${widget.message.senderName} - ${_formatTime(widget.message.createdAt)}',
                    style: const TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // Timestamp above sent messages - only show on first (oldest) message in consecutive group
              // Use showSenderName since list is reversed (oldest messages have showSenderName=true)
              if (widget.isMine && !kIsWeb && widget.showSenderName) ...[
                Text(
                  _formatTime(widget.message.createdAt),
                  style: const TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (widget.isMine && kIsWeb && widget.showTimeOnWeb) ...[
                _buildTimeStatusRow(
                  timeColor,
                  scaleHeight,
                  scaleWidth,
                ),
                4.5.verticalSpace,
              ],
              Row(
                    mainAxisAlignment: widget.isMine
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!widget.isMine && !kIsWeb) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: widget.message.avatar.isNotEmpty && widget.showSender
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(widget.message.avatar),
                                  radius: 12, // 24x24 avatar
                                  backgroundColor: Colors.transparent,
                                )
                              : const SizedBox(width: 24), // Placeholder for alignment
                        ),
                        const SizedBox(width: 6),
                      ],

                      GestureDetector(
                        onTap: widget.message.type == 'FILE' ? _onFileTap : null,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: getResponsiveValue(
                              mobile: MediaQuery.of(context).size.width * 0.75,
                              tablet: MediaQuery.of(context).size.width * 0.6,
                              desktop: MediaQuery.of(context).size.width * 0.4,
                            ),
                          ),
                          margin: EdgeInsets.only(
                            bottom: widget.isSameSender ?? false ? 6 : 12,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: borderRadius,
                          ),
                          child: widget.message.type == 'FILE'
                              ? _buildFileBubble(
                                  context,
                                  scaleWidth,
                                  scaleHeight,
                                  textColor,
                                  timeColor,
                                  showDownload:
                                      !_isCheckingFile &&
                                      !_fileExistsLocally &&
                                      !_isDownloading,
                                  showProgress: _isDownloading,
                                  progress: _downloadProgress,
                                  isFailed: isFailed,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      widget.message.encryptedText.isNotEmpty
                                          ? CryptoService.decryptGroupMessage(
                                              widget.senderKey,
                                              widget.message.encryptedText,
                                              widget.iv,
                                            )
                                          : '',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Text',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: textColor,
                                        letterSpacing: -0.3,
                                        height: 1.4,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                    // Read receipt icon inside bubble for sent messages (mobile)
                                    if (widget.isMine && !kIsWeb) ...[
                                      const SizedBox(height: 6),
                                      _buildReadReceiptIcon(),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                      if (isFailed) const SizedBox(width: 6),
                      if (isFailed)
                        GestureDetector(
                          onTap: () {
                            if (widget.onRetry != null) {
                              widget.onRetry!(widget.message);
                            } else if (_downloadFailed) {
                              _downloadFile();
                            }
                          },
                          child: SvgPicture.asset(
                            AppAssets.retryIcon,
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFEE4025),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                    ],
                  ),


              // For text messages, show "Failed" text below the bubble
              // For file messages, it's already shown inside the bubble
              if (isFailed && widget.message.type != 'FILE') ...[
                Container(
                  margin: EdgeInsets.only(
                    right: 20 * scaleWidth,
                    bottom: widget.isSameSender!
                        ? 10 * scaleHeight
                        : 12 * scaleHeight,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        textAlign: TextAlign.right,
                        'Failed',
                        style: AppTextStyles.captionRegular(context).copyWith(
                          color: AppColors.failedMessageColor,
                          fontSize: 10 * scaleHeight,
                        ),
                      ),
                      SizedBox(width: 4 * scaleWidth),
                      SvgPicture.asset(
                        AppAssets.infoIcon,
                        width: 18 * scaleWidth,
                        height: 18 * scaleWidth,
                        colorFilter: const ColorFilter.mode(
                          AppColors.failedMessageColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileBubble(
    BuildContext context,
    double scaleWidth,
    double scaleHeight,
    Color textColor,
    Color timeColor, {
    bool showDownload = false,
    bool showProgress = false,
    double progress = 0.0,
    bool isFailed = false,
  }) {
    final fileName = widget.message.fileName ?? '';
    final ext = widget.message.fileType ?? '';
    final fileTypeLabel = ext.toUpperCase();
    final fileSizeKB = widget.message.fileSize != null && widget.message.fileSize!.isNotEmpty
        ? (int.tryParse(widget.message.fileSize!) ?? 0) ~/ 1024
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // White inner container with file info
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF9F9D9F),
              width: 0.2,
            ),
          ),
          padding: const EdgeInsets.only(
            left: 8,
            right: 12,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // File type box
              Container(
                width: 30,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF9F9D9F),
                    width: 0.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  fileTypeLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.3,
                    height: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // File name and details
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: -0.3,
                        height: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '1 page • $fileSizeKB KB • $ext',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF666666),
                        letterSpacing: -0.3,
                        height: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showDownload) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF25253D),
                  size: 20,
                ),
              ],
              if (showProgress) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF25253D),
                        ),
                        backgroundColor: const Color(0xFF666666).withValues(
                          alpha: 0.2,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 6,
                          color: Color(0xFF25253D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Failed state: show "Failed" text and info icon inside bubble
        if (isFailed) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFEE4025),
                  letterSpacing: -0.3,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                AppAssets.infoIcon,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFEE4025),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ],
        // Read receipt icon for sent messages (mobile only) - only show when not failed
        if (widget.isMine && !kIsWeb && !isFailed) ...[
          const SizedBox(height: 6),
          _buildReadReceiptIcon(),
        ],
      ],
    );
  }

  /// Build read receipt icon (18x18) for inside message bubble
  Widget _buildReadReceiptIcon() {
    if (widget.message.status == 'SENDING') {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (widget.message.status == 'SENT') {
      return SvgPicture.asset(
        AppAssets.sentChatIcon,
        width: 18,
        height: 18,
      );
    } else if (widget.message.status == 'DELIVERED') {
      return SvgPicture.asset(
        AppAssets.deliveredChatIcon,
        width: 18,
        height: 18,
      );
    } else if (widget.message.status == 'READ') {
      return SvgPicture.asset(
        AppAssets.readChatIcon,
        width: 18,
        height: 18,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTimeStatusRow(
    Color timeColor,
    double scaleHeight,
    double scaleWidth,
  ) {
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: widget.isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(widget.message.createdAt),
            style: AppTextStyles.captionRegular(
              context,
            ).copyWith(
              fontSize: getResponsiveValue(
                mobile: 8.sp,
                tablet: 11.sp,
                desktop: 14.sp,
              ),
              color: timeColor,
            ),
          ),
          SizedBox(width: 4 * scaleWidth),
          if (widget.isMine && widget.message.status == 'SENDING') ...[
            SizedBox(
              width: 12 * scaleWidth,
              height: 12 * scaleWidth,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isMine ? Colors.white : AppColors.neural502,
                ),
              ),
            ),
          ] else if (widget.isMine && widget.message.status == 'SENT') ...[
            SvgPicture.asset(
              AppAssets.sentChatIcon,
              width: (kIsWeb ? 16 : 14) * scaleWidth,
              height: (kIsWeb ? 16 : 14) * scaleWidth,
            ),
          ] else if (widget.isMine && widget.message.status == 'DELIVERED') ...[
            SvgPicture.asset(
              AppAssets.deliveredChatIcon,
              width: (kIsWeb ? 16 : 14) * scaleWidth,
              height: (kIsWeb ? 16 : 14) * scaleWidth,
            ),
          ] else if (widget.isMine && widget.message.status == 'READ') ...[
            SvgPicture.asset(
              AppAssets.readChatIcon,
              width: (kIsWeb ? 16 : 14) * scaleWidth,
              height: (kIsWeb ? 16 : 14) * scaleWidth,
            ),
          ],
        ],
      ),
    );
  }
}

String _formatTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  } catch (_) {
    return '';
  }
}
