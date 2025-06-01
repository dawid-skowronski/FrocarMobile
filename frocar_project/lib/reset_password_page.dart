import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _message = 'Proszę wpisać adres e-mail.';
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _message = 'Proszę wpisać poprawny adres e-mail.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.requestPasswordReset(email);

      setState(() {
        _message = 'Link do resetowania hasła został wysłany na podany adres e-mail.';
      });
      _emailController.clear();
    } catch (e) {
      print('DEBUG: Wyjątek w ResetPasswordPage: $e');
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
    if (rawMessage.contains('404') || rawMessage.toLowerCase().contains('nie znaleziono użytkownika') || rawMessage.toLowerCase().contains('user not found')) {
      return 'Nie znaleziono użytkownika z podanym adresem e-mail.';
    }
    else if (rawMessage.contains('timeout') || rawMessage.contains('SocketException') || rawMessage.contains('Failed host lookup')) {
      return 'Połączenie z serwerem nie powiodło się. Sprawdź swoje połączenie internetowe i spróbuj ponownie.';
    }
    else if (rawMessage.toLowerCase().contains('nieprawidłowy format adresu e-mail') || rawMessage.toLowerCase().contains('invalid email format')) {
      return 'Wprowadzony adres e-mail ma nieprawidłowy format.';
    }
    else {
      return 'Wystąpił błąd podczas wysyłania żądania. Spróbuj ponownie później. Szczegóły: $rawMessage';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Resetowanie hasła",
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
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Adres e-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestPasswordReset,
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
                    : const Text('Wyślij link resetujący', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('wysłany') ? Colors.green : Colors.red,
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
    _emailController.dispose();
    super.dispose();
  }
}