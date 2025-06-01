import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  final bool skipNavigationOnLogin;
  final String? testUsername;

  const LoginScreen({
    super.key,
    this.skipNavigationOnLogin = false,
    this.testUsername,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true; // Domyślnie włączone "Zapamiętaj mnie"

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Proszę uzupełnić nazwę użytkownika i hasło.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
      final response = await apiService.login(username, password);

      // Zapisz hasło tylko, jeśli wybrano "Zapamiętaj mnie"
      if (_rememberMe) {
        await storage.write(key: 'password', value: password);
      } else {
        await storage.delete(key: 'password');
      }

      setState(() {
        _message = 'Zalogowano pomyślnie.';
      });

      if (!widget.skipNavigationOnLogin) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _message = _mapErrorMessage(errorMsg);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _mapErrorMessage(String rawMessage) {
    if (rawMessage.contains('401')) {
      return 'Nieprawidłowa nazwa użytkownika lub hasło.';
    } else if (rawMessage.contains('timeout')) {
      return 'Połączenie z serwerem nie powiodło się. Spróbuj ponownie.';
    } else {
      return 'Wystąpił błąd podczas logowania. Spróbuj ponownie później.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Logowanie",
        username: widget.testUsername,
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa użytkownika',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Hasło',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Zapamiętaj mnie'),
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/reset-password');
                },
                child: const Text(
                  'Zapomniałeś hasła?',
                  style: TextStyle(color: Color(0xFF375534)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF375534),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Zaloguj się', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('pomyślnie') ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}