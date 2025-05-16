import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationPressed;
  final _storage = const FlutterSecureStorage();

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onNotificationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return AppBar(
      backgroundColor: const Color(0xFF375534),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      automaticallyImplyLeading: false,
      actions: [
        FutureBuilder<String?>(
          future: _getUsername(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return Row(
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {
                          if (onNotificationPressed != null) {
                            onNotificationPressed!();
                          }
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
                  IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Colors.white,
                    ),
                    onPressed: () => _logout(context),
                  ),
                ],
              );
            }
            return Row(
              children: [
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              ],
            );
          },
        ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  Future<String?> _getUsername() async {
    return await _storage.read(key: 'username');
  }

  void _logout(BuildContext context) async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Potwierdzenie wylogowania"),
        content: const Text("Czy na pewno chcesz się wylogować?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Nie"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Tak"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'username');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}