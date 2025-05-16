import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      setState(() {
        _message = 'Zalogowano pomyślnie';
      });

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Logowanie",
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
              decoration: const InputDecoration(labelText: 'Nazwa użytkownika'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Hasło',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF375534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Zaloguj się'),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                color: _message.contains('pomyślnie') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}