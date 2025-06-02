import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/models/notification.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/services/notification_adapter.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

const String _appBarTitle = 'Powiadomienia';
const String _loadingMessage = 'Ładowanie powiadomień...';
const String _noNotificationsMessage = 'Brak nowych powiadomień.';
const String _connectionErrorMessage = 'Nie udało się połączyć z serwerem. Sprawdź swoje połączenie internetowe.';
const String _accessDeniedMessage = 'Dostęp zabroniony. Zaloguj się ponownie.';
const String _genericErrorMessage = 'Wystąpił błąd podczas ładowania powiadomień.';
const String _readNotificationErrorMessage = 'Wystąpił błąd podczas oznaczania powiadomienia jako przeczytane.';
const String _dateLabel = 'Data:';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _pollingTimer;
  final NotificationAdapter _adapter = MapToNotificationAdapter();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchNotifications());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _setErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  void _setNotifications(List<NotificationModel> newNotifications) {
    if (mounted) {
      setState(() {
        _notifications = newNotifications;
      });
      Provider.of<NotificationProvider>(context, listen: false)
          .setNotificationCount(newNotifications.length);
    }
  }

  Future<void> _fetchNotifications() async {
    _setLoadingState(true);
    _setErrorMessage('');

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final rawData = await apiService.fetchAccountNotifications();
      final convertedNotifications = _adapter.convertToNotifications(rawData);
      _setNotifications(convertedNotifications);
    } catch (e) {
      _setErrorMessage(_mapErrorMessage(e.toString()));
      Provider.of<NotificationProvider>(context, listen: false).setNotificationCount(0);
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markAccountNotificationAsRead(notificationId);
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.notificationId == notificationId);
        });
        Provider.of<NotificationProvider>(context, listen: false)
            .setNotificationCount(_notifications.length);
      }
    } catch (e) {
      final message = _mapErrorMessage(e.toString());
      _setErrorMessage(message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_readNotificationErrorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _mapErrorMessage(String raw) {
    final message = raw.replaceFirst('Exception: ', '');
    if (message.contains('timeout')) {
      return _connectionErrorMessage;
    } else if (message.contains('401')) {
      return _accessDeniedMessage;
    } else {
      return _genericErrorMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _appBarTitle,
        onNotificationPressed: null,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _buildBodyContent(),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    } else if (_errorMessage.isNotEmpty) {
      return _buildErrorMessage();
    } else if (_notifications.isEmpty) {
      return _buildNoNotificationsMessage();
    } else {
      return _buildNotificationsList();
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNoNotificationsMessage() {
    return const Center(
      child: Text(
        _noNotificationsMessage,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: Color(0xFF375534)),
        title: Text(
          notification.message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$_dateLabel ${DateFormat('yyyy-MM-dd').format(notification.createdAt)}'),
        trailing: IconButton(
          icon: const Icon(Icons.check, color: Color(0xFF375534)),
          onPressed: () => _markAsRead(notification.notificationId),
        ),
      ),
    );
  }
}
