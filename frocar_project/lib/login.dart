import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _appBarTitle = "Logowanie";
const String _usernameLabel = 'Nazwa użytkownika';
const String _passwordLabel = 'Hasło';
const String _rememberMeLabel = 'Zapamiętaj mnie';
const String _forgotPasswordLabel = 'Zapomniałeś hasła?';
const String _loginButtonText = 'Zaloguj się';
const String _emptyFieldsMessage = 'Proszę uzupełnić nazwę użytkownika i hasło.';
const String _loginSuccessMessage = 'Zalogowano pomyślnie.';
const String _invalidCredentialsMessage = 'Nieprawidłowa nazwa użytkownika lub hasło.';
const String _connectionTimeoutMessage = 'Połączenie z serwerem nie powiodło się. Spróbuj ponownie.';
const String _genericErrorMessage = 'Wystąpił błąd podczas logowania. Spróbuj ponownie później.';

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
  bool _rememberMe = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _setMessage(String message, {bool isSuccess = false}) {
    if (mounted) {
      setState(() {
        _message = message;
      });
    }
  }

  Future<void> _handleLoginSuccess() async {
    _setMessage(_loginSuccessMessage, isSuccess: true);
    if (!widget.skipNavigationOnLogin) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  void _handleLoginError(dynamic e) {
    final errorMsg = e.toString().replaceFirst('Exception: ', '');
    _setMessage(_mapErrorMessage(errorMsg));
    debugPrint('Login error: $e');
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _setMessage(_emptyFieldsMessage);
      return;
    }

    _setLoadingState(true);
    _setMessage('');

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storage = Provider.of<FlutterSecureStorage>(context, listen: false);

      await apiService.login(username, password);

      if (_rememberMe) {
        await storage.write(key: 'password', value: password);
      } else {
        await storage.delete(key: 'password');
      }

      await _handleLoginSuccess();
    } catch (e) {
      _handleLoginError(e);
    } finally {
      _setLoadingState(false);
    }
  }

  String _mapErrorMessage(String rawMessage) {
    if (rawMessage.contains('401')) {
      return _invalidCredentialsMessage;
    } else if (rawMessage.contains('timeout')) {
      return _connectionTimeoutMessage;
    } else {
      return _genericErrorMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _appBarTitle,
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
            _buildUsernameField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildRememberMeCheckbox(),
            _buildForgotPasswordButton(),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 20),
            _buildMessageDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: _usernameLabel,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: _passwordLabel,
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
    );
  }

  Widget _buildRememberMeCheckbox() {
    return CheckboxListTile(
      title: const Text(_rememberMeLabel),
      value: _rememberMe,
      onChanged: (value) {
        setState(() {
          _rememberMe = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/reset-password');
        },
        child: const Text(
          _forgotPasswordLabel,
          style: TextStyle(color: Color(0xFF375534)),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
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
            : const Text(_loginButtonText, style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildMessageDisplay() {
    if (_message.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      _message,
      style: TextStyle(
        color: _message.contains('pomyślnie') ? Colors.green : Colors.red,
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
    );
  }
}
