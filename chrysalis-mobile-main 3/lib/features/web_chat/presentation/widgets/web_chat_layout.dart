import 'package:chrysalis_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/pages/message_tab.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/widgets/web_sidebar.dart';
import 'package:flutter/material.dart';

class WebChatLayout extends StatefulWidget {
  const WebChatLayout({super.key});

  @override
  State<WebChatLayout> createState() => _WebChatLayoutState();
}

class _WebChatLayoutState extends State<WebChatLayout>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MessageTab(),
    const SettingsPage(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F7),
      body: Row(
        children: [
          AnimatedBuilder(
            animation: 
                ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation,
            builder: (context, child) {
              return WebSidebar(
                selectedIndex: _selectedIndex,
                onTabSelected: _onTabSelected,
              );
            },
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: IndexedStack(
                key: ValueKey(_selectedIndex),
                index: _selectedIndex,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
