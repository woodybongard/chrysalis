import 'package:chrysalis_mobile/features/web_chat/presentation/widgets/web_chat_layout.dart';
import 'package:flutter/material.dart';

class MainChat extends StatelessWidget {
  const MainChat({super.key});

  static const String routeName = '/web-main-chat';

  @override
  Widget build(BuildContext context) {
    return const WebChatLayout();
  }
}