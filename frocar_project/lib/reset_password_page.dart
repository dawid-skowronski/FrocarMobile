import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

const String _appBarTitle = "Resetowanie hasła";
const String _emailLabel = 'Adres e-mail';
const String _emailEmptyMessage = 'Proszę wpisać adres e-mail.';
const String _emailInvalidMessage = 'Proszę wpisać poprawny adres e-mail.';
const String _resetButtonText = 'Wyślij link resetujący';
const String _resetSuccessMessage = 'Link do resetowania hasła został wysłany na podany adres e-mail.';
const String _userNotFoundMessage = 'Nie znaleziono użytkownika z podanym adresem e-mail.';
const String _connectionErrorMessage = 'Połączenie z serwerem nie powiodło się. Sprawdź swoje połączenie internetowe i spróbuj ponownie.';
const String _invalidEmailFormatMessage = 'Wprowadzony adres e-mail ma nieprawidłowy format.';
const String _genericErrorMessage = 'Wystąpił błąd podczas wysyłania żądania. Spróbuj ponownie później. Szczegóły:';

const Color _themeColor = Color(0xFF375534);
const Color _whiteColor = Colors.white;
const Color _greenColor = Colors.green;
const Color _redColor = Colors.red;

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

    if (!_validateEmail(email)) {
      return;
    }

    _setLoadingState(true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.requestPasswordReset(email);
      _handleSuccess();
    } catch (e) {
      _handleError(e.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      _setMessage(_emailEmptyMessage);
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _setMessage(_emailInvalidMessage);
      return false;
    }
    return true;
  }

  void _setLoadingState(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _message = '';
    });
  }

  void _setMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  void _handleSuccess() {
    _setMessage(_resetSuccessMessage);
    _emailController.clear();
  }

  void _handleError(String rawError) {
    final errorMsg = rawError.replaceFirst('Exception: ', '');
    _setMessage(_mapErrorMessage(errorMsg));
  }

  String _mapErrorMessage(String rawMessage) {
    if (rawMessage.contains('404') || rawMessage.toLowerCase().contains('nie znaleziono użytkownika') || rawMessage.toLowerCase().contains('user not found')) {
      return _userNotFoundMessage;
    }
    if (rawMessage.contains('timeout') || rawMessage.contains('SocketException') || rawMessage.contains('Failed host lookup')) {
      return _connectionErrorMessage;
    }
    if (rawMessage.toLowerCase().contains('nieprawidłowy format adresu e-mail') || rawMessage.toLowerCase().contains('invalid email format')) {
      return _invalidEmailFormatMessage;
    }
    return '$_genericErrorMessage $rawMessage';
  }

  Widget _buildEmailTextField() {
    return TextField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: _emailLabel,
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _requestPasswordReset,
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeColor,
          foregroundColor: _whiteColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: _whiteColor)
            : const Text(_resetButtonText, style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildMessageDisplay() {
    if (_message.isEmpty) return const SizedBox.shrink();
    return Text(
      _message,
      style: TextStyle(
        color: _message.contains('wysłany') ? _greenColor : _redColor,
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _appBarTitle,
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildEmailTextField(),
            const SizedBox(height: 24),
            _buildResetButton(),
            const SizedBox(height: 20),
            _buildMessageDisplay(),
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
