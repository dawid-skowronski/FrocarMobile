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
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchNotifications();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.fetchAccountNotifications();
      setState(() {
        notifications = data;
        isLoading = false;
        errorMessage = '';
      });
      Provider.of<NotificationProvider>(context, listen: false).setNotificationCount(notifications.length);
    } catch (e) {
      setState(() {
        errorMessage = 'Błąd: ${e.toString().replaceFirst('Exception: ', '')}';
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
        notifications.removeWhere((notification) => notification['notificationId'] == notificationId);
        errorMessage = '';
      });
      Provider.of<NotificationProvider>(context, listen: false).setNotificationCount(notifications.length);
    } catch (e) {
      setState(() {
        errorMessage = 'Błąd: ${e.toString().replaceFirst('Exception: ', '')}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
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
            ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
            : notifications.isEmpty
            ? const Center(child: Text('Brak nowych powiadomień.', style: TextStyle(fontSize: 16)))
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