import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/login.dart';

const String _appBarTitle = 'Profil';
const String _currentUsernameLabel = 'Aktualna nazwa użytkownika:';
const String _newUsernameLabel = 'Nowa nazwa użytkownika';
const String _saveChangesButtonText = 'Zapisz zmiany';
const String _usernameRequiredMessage = 'Nazwa użytkownika jest wymagana';
const String _usernameMinLengthMessage = 'Nazwa musi mieć co najmniej 3 znaki';
const String _usernameChangedSuccess = 'Nazwa użytkownika została zmieniona. Zaloguj się ponownie.';
const String _usernameExistsError = 'Taka nazwa użytkownika już istnieje. Wybierz inną.';
const String _sessionExpiredError = 'Sesja wygasła. Zaloguj się ponownie.';
const String _connectionError = 'Brak połączenia z serwerem. Sprawdź połączenie internetowe.';
const String _genericUpdateError = 'Wystąpił błąd podczas zmiany nazwy użytkownika.';
const String _unknownUser = 'Nieznany użytkownik';
const Color _themeColor = Color(0xFF375534);

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  late FlutterSecureStorage _storage;
  late ApiService _apiService;
  bool _isLoading = false;
  String? _currentUsername;
  bool _dependenciesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesInitialized) {
      _storage = Provider.of<FlutterSecureStorage>(context, listen: false);
      _apiService = Provider.of<ApiService>(context, listen: false);
      _loadCurrentUsername();
      _dependenciesInitialized = true;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _setCurrentUsername(String username) {
    if (mounted) {
      setState(() {
        _currentUsername = username;
        _usernameController.text = username;
      });
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  Future<void> _loadCurrentUsername() async {
    final username = await _storage.read(key: 'username');
    _setCurrentUsername(username ?? _unknownUser);
  }

  Future<void> _updateUsername() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _setLoadingState(true);

    try {
      await _apiService.changeUsername(_usernameController.text);
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'username');

      _showSnackBar(_usernameChangedSuccess, Colors.green);
      _navigateToLogin();
    } catch (e) {
      final errorMsg = _mapErrorMessage(e.toString());
      _showSnackBar(errorMsg, Colors.redAccent);
    } finally {
      _setLoadingState(false);
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (_) => false,
      );
    }
  }

  String _mapErrorMessage(String raw) {
    final message = raw.replaceFirst('Exception: ', '').toLowerCase();

    if (message.contains('username already exists')) {
      return _usernameExistsError;
    } else if (message.contains('unauthorized')) {
      return _sessionExpiredError;
    } else if (message.contains('timeout') || message.contains('network')) {
      return _connectionError;
    } else {
      return _genericUpdateError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: _appBarTitle,
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _buildProfileContent(isDarkMode),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildProfileContent(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentUsernameDisplay(isDarkMode),
            const SizedBox(height: 16),
            _buildNewUsernameField(isDarkMode),
            const SizedBox(height: 24),
            _buildSaveChangesButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUsernameDisplay(bool isDarkMode) {
    return Text(
      '$_currentUsernameLabel ${_currentUsername ?? _unknownUser}',
      style: TextStyle(
        fontSize: 16,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildNewUsernameField(bool isDarkMode) {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: _newUsernameLabel,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return _usernameRequiredMessage;
        }
        if (value.length < 3) {
          return _usernameMinLengthMessage;
        }
        return null;
      },
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  Widget _buildSaveChangesButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateUsername,
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text(
          _saveChangesButtonText,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
