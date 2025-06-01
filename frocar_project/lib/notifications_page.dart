import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String errorMessage = '';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchNotifications());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.fetchAccountNotifications();
      setState(() {
        notifications = data;
        isLoading = false;
      });
      Provider.of<NotificationProvider>(context, listen: false).setNotificationCount(notifications.length);
    } catch (e) {
      setState(() {
        errorMessage = _mapErrorMessage(e.toString());
        isLoading = false;
      });
      Provider.of<NotificationProvider>(context, listen: false).setNotificationCount(0);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markAccountNotificationAsRead(notificationId);
      setState(() {
        notifications.removeWhere((n) => n['notificationId'] == notificationId);
      });
      Provider.of<NotificationProvider>(context, listen: false).setNotificationCount(notifications.length);
    } catch (e) {
      final message = _mapErrorMessage(e.toString());
      setState(() {
        errorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _mapErrorMessage(String raw) {
    final message = raw.replaceFirst('Exception: ', '');
    if (message.contains('timeout')) {
      return 'Nie udało się połączyć z serwerem. Sprawdź swoje połączenie internetowe.';
    } else if (message.contains('401')) {
      return 'Dostęp zabroniony. Zaloguj się ponownie.';
    } else {
      return 'Wystąpił błąd podczas ładowania powiadomień.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Powiadomienia',
        onNotificationPressed: null,
      ),
      body: RefreshIndicator(
        onRefresh: fetchNotifications,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        )
            : notifications.isEmpty
            ? const Center(
          child: Text(
            'Brak nowych powiadomień.',
            style: TextStyle(fontSize: 16),
          ),
        )
            : ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFF375534)),
                title: Text(
                  notification['message'] ?? 'Brak wiadomości',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: notification['createdAt'] != null
                    ? Text('Data: ${notification['createdAt']}')
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.check, color: Color(0xFF375534)),
                  onPressed: () => markAsRead(notification['notificationId']),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
