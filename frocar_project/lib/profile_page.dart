import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  late FlutterSecureStorage _storage;
  late ApiService _apiService;
  bool isLoading = false;
  String? currentUsername;
  bool _dependenciesLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesLoaded) {
      _storage = Provider.of<FlutterSecureStorage>(context, listen: false);
      _apiService = Provider.of<ApiService>(context, listen: false);
      _loadCurrentUsername();
      _dependenciesLoaded = true;
    }
  }

  Future<void> _loadCurrentUsername() async {
    final username = await _storage.read(key: 'username');
    setState(() {
      currentUsername = username ?? 'Nieznany użytkownik';
      usernameController.text = currentUsername!;
    });
  }

  Future<void> _updateUsername() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _apiService.changeUsername(usernameController.text);

      await _storage.delete(key: 'token');
      await _storage.delete(key: 'username');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nazwa użytkownika została zmieniona. Zaloguj się ponownie.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (_) => false,
      );
    } catch (e) {
      final errorMsg = _mapErrorMessage(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _mapErrorMessage(String raw) {
    final message = raw.replaceFirst('Exception: ', '').toLowerCase();

    if (message.contains('username already exists')) {
      return 'Taka nazwa użytkownika już istnieje. Wybierz inną.';
    } else if (message.contains('unauthorized')) {
      return 'Sesja wygasła. Zaloguj się ponownie.';
    } else if (message.contains('timeout') || message.contains('network')) {
      return 'Brak połączenia z serwerem. Sprawdź połączenie internetowe.';
    } else {
      return 'Wystąpił błąd podczas zmiany nazwy użytkownika.';
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profil',
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktualna nazwa użytkownika: $currentUsername',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nowa nazwa użytkownika',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nazwa użytkownika jest wymagana';
                  }
                  if (value.length < 3) {
                    return 'Nazwa musi mieć co najmniej 3 znaki';
                  }
                  return null;
                },
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateUsername,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF375534),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Zapisz zmiany',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
