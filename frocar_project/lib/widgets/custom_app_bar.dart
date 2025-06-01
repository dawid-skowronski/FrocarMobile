import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? username;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onLogoutPressed;

  CustomAppBar({
    Key? key,
    required this.title,
    this.username,
    this.onNotificationPressed,
    this.onLogoutPressed,
  }) : super(key: key);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = widget.username ?? await _getUsername();
    if (_mounted) {
      setState(() {
        _username = username;
      });
    }
  }

  Future<String?> _getUsername() async {
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
    return await storage.read(key: 'username');
  }

  bool get _mounted => mounted;

  void _logout(BuildContext context) async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Potwierdzenie wylogowania"),
        content: const Text("Czy na pewno chcesz się wylogować?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Nie"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Tak"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
      await storage.delete(key: 'token');
      await storage.delete(key: 'username');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      backgroundColor: const Color(0xFF375534),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      automaticallyImplyLeading: false,
      actions: [
        if (_username != null && _username!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, _) => Stack(
                  children: [
                    IconButton(
                      key: const Key('notification_button'),
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                        widget.onNotificationPressed?.call();
                        notificationProvider.resetNotificationCount();
                      },
                    ),
                    if (notificationProvider.notificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notificationProvider.notificationCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('theme_toggle'),
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              ),
              IconButton(
                key: const Key('logout_button'),
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                onPressed: () {
                  if (widget.onLogoutPressed != null) {
                    widget.onLogoutPressed!();
                  } else {
                    _logout(context);
                  }
                },
              ),
            ],
          )
        else
          IconButton(
            key: const Key('theme_toggle'),
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }
}