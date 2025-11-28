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
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/emoji_reaction_overlay.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/message_reactions.dart';
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
    final bgColor = isFailed
        ? AppColors.failedMessageColor.withValues(alpha: 0.2)
        : widget.isMine
        ? AppColors.textBackground
        : AppColors.chatBackground;
    final textColor = isFailed
        ? Colors.black
        : widget.isMine
        ? Colors.white
        : Colors.black;
    final timeColor = isFailed
        ? Colors.black
        : widget.isMine
        ? kIsWeb?Colors.black: Colors.white
        : Colors.black;


    final borderRadius = widget.isMine
        ? BorderRadius.only(
            topLeft: Radius.circular(10 * scaleWidth),
            topRight: Radius.circular(kIsWeb? 0: 10 * scaleWidth),
            bottomRight: Radius.circular(kIsWeb? widget.isSameSender??false ? 0:10: widget.isSameSender??false ? 0:10 * scaleWidth),
            bottomLeft: Radius.circular(10 * scaleWidth),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(kIsWeb ?0:10 * scaleWidth),
            topRight: Radius.circular(10 * scaleWidth),
            bottomRight: Radius.circular(10 * scaleWidth),
      bottomLeft: Radius.circular(kIsWeb? widget.isSameSender??false ? 0:10: widget.isSameSender??false ? 0:10 * scaleWidth),


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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: (kIsWeb?0: 32) * scaleHeight),
                  child: Row(
                    children: [
                      Text(
                        widget.message.senderName,
                        style: AppTextStyles.captionRegular(context).copyWith(
                          color: AppColors.neural502,
                          fontWeight: FontWeight.w600,
                          fontSize: getResponsiveValue(
                            mobile: 10.sp,
                            tablet: 12.sp,
                            desktop: 14.sp,
                          ),
                        ),

                      ),
                      if(kIsWeb && widget.showTimeOnWeb)...[
                        6.horizontalSpace,
                        _buildTimeStatusRow(
                          timeColor,
                          scaleHeight,
                          scaleWidth,
                        ),
                      ],

                    ],
                  ),
                ),
                SizedBox(height: 4 * scaleHeight),
              ],
              if(widget.isMine && kIsWeb && widget.showTimeOnWeb)...[
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
                        SizedBox(width: 6 * scaleWidth),
                      ],

                      GestureDetector(
                        onTap: widget.message.type == 'FILE' ? _onFileTap : null,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: getResponsiveValue(
                              mobile: MediaQuery.of(context).size.width * 0.75, // 75% on mobile
                              tablet: MediaQuery.of(context).size.width * 0.6,  // 60% on tablet  
                              desktop: MediaQuery.of(context).size.width * 0.4, // 40% on desktop
                            ),
                          ),
                          margin: widget.isMine && widget.message.status == 'FAILED'
                              ? EdgeInsets.only(bottom: 5 * scaleHeight)
                              : EdgeInsets.only(
                                  bottom: widget.isSameSender!
                                      ? 5 * scaleHeight
                                      : 12 * scaleHeight,
                                ),
                          padding: EdgeInsets.symmetric(
                            vertical: 10 * scaleHeight,
                            horizontal: 12 * scaleWidth,
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
                                )
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.message.encryptedText.isNotEmpty
                                                ? CryptoService.decryptGroupMessage(
                                                    widget.senderKey,
                                                    widget.message.encryptedText,
                                                    widget.iv,
                                                  )
                                                : '',
                                            style: AppTextStyles.captionRegular(context)
                                                .copyWith(
                                                  color: textColor,
                                                  fontSize: getResponsiveValue(
                                                    mobile: 14.sp,
                                                    tablet: 15.sp,
                                                    desktop: 16.sp,
                                                  ),
                                                ),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),

                                      ],
                                    ),
                                  SizedBox(height: 6 * scaleHeight),
                                  if(!kIsWeb)
                                  _buildTimeStatusRow(
                                    timeColor,
                                    scaleHeight,
                                    scaleWidth,
                                  ),
                                ],
                              ),
                        ),
                      ),
                      if (isFailed) SizedBox(width: scaleWidth * 6),
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
                            width: 18 * scaleWidth,
                            height: 18 * scaleWidth,
                            colorFilter: const ColorFilter.mode(
                              AppColors.failedMessageColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                    ],
                  ),


              if (isFailed) ...[
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
  }) {
    final fileName = widget.message.fileName ?? '';
    final ext = widget.message.fileType ?? '';
    final fileTypeLabel = ext.toUpperCase();
    final details =
        '1 page  ·  ${int.parse(widget.message.fileSize!) > 0 ? '${(int.parse(widget.message.fileSize!) / 1024).toStringAsFixed(0)} KB' : ''}   ·  $ext';

    return Column(
      crossAxisAlignment:
           CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8 * scaleWidth),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 6 * scaleHeight,
                  horizontal: 8 * scaleWidth,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30 * scaleWidth,
                      height: 29 * scaleWidth,
                      decoration: BoxDecoration(
                        color: AppColors.neural51,
                        borderRadius: BorderRadius.circular(4 * scaleWidth),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        fileTypeLabel,
                        style: AppTextStyles.p2SemiBold(
                          context,
                        ).copyWith(color: Colors.black, fontSize: kIsWeb?12:10 * scaleWidth),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12 * scaleWidth),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            fileName,
                            style: AppTextStyles.captionRegular(context).copyWith(
                              color: Colors.black,
                              fontSize: 14 * scaleWidth,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4 * scaleHeight),
                          Text(
                            details,
                            style: AppTextStyles.captionRegular(context).copyWith(
                              color: AppColors.neural502,
                              fontSize: kIsWeb?12:8 * scaleWidth,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (showDownload) ...[
                      SizedBox(width: 8 * scaleWidth),
                      Icon(
                        Icons.download_rounded,
                        color: AppColors.textBackground,
                        size: 20 * scaleWidth,
                      ),
                    ],
                    if (showProgress) ...[
                      SizedBox(width: 8 * scaleWidth),
                      SizedBox(
                        width: 26 * scaleWidth,
                        height: 26 * scaleWidth,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.textBackground,
                              ),
                              backgroundColor: AppColors.neural502.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 6 * scaleWidth,
                                color: AppColors.textBackground,
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
            ),

          ],
        ),
        if(!kIsWeb)...[
          SizedBox(height: 12 * scaleWidth),

          _buildTimeStatusRow(timeColor, scaleHeight, scaleWidth),
        ],

      ],
    );
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
              width:  (kIsWeb? 16 :14) * scaleWidth,
              height: (kIsWeb? 16 :14) * scaleWidth,
            ),
          ] else if (widget.isMine && widget.message.status == 'DELIVERED') ...[
            SvgPicture.asset(
              AppAssets.deliveredChatIcon,
              width: (kIsWeb? 16 :14) * scaleWidth,
              height: (kIsWeb? 16 :14) * scaleWidth,
            ),
          ] else if (widget.isMine && widget.message.status == 'READ') ...[
            SvgPicture.asset(
              AppAssets.readChatIcon,
              width: (kIsWeb? 16 :14) * scaleWidth,
              height: (kIsWeb? 16 :14) * scaleWidth,
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
