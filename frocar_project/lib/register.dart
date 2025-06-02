import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

const String _appBarTitle = "Rejestracja";
const String _usernameLabel = 'Nazwa użytkownika';
const String _emailLabel = 'Email';
const String _passwordLabel = 'Hasło';
const String _confirmPasswordLabel = 'Potwierdź hasło';
const String _registerButtonText = 'Zarejestruj się';

const String _usernameRequired = 'Wprowadź nazwę użytkownika';
const String _usernameMinLength = 'Nazwa musi mieć co najmniej 3 znaki';
const String _emailRequired = 'Wprowadź adres email';
const String _invalidEmailFormat = 'Nieprawidłowy format email';
const String _passwordRequired = 'Wprowadź hasło';
const String _passwordMinLength = 'Hasło musi mieć co najmniej 6 znaków';
const String _passwordsMismatch = 'Hasła się nie zgadzają';

const String _registrationSuccess = 'Zarejestrowano pomyślnie';
const String _usernameTaken = 'Ta nazwa użytkownika jest już zajęta.';
const String _emailUsed = 'Ten adres email jest już używany.';
const String _invalidEmail = 'Nieprawidłowy adres email.';
const String _connectionError = 'Błąd połączenia z serwerem. Spróbuj ponownie.';
const String _userExists = 'Użytkownik już istnieje';
const String _genericRegistrationError = 'Wystąpił błąd rejestracji.';

const Color _themeColor = Color(0xFF375534);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _message = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _setMessage(String message) {
    if (mounted) {
      setState(() {
        _message = message;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _setLoadingState(true);
    _setMessage('');

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _confirmPasswordController.text,
      );

      _setMessage(_registrationSuccess);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _setMessage(_formatError(e.toString()));
      debugPrint('Registration error: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  String _formatError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '').toLowerCase();
    if (msg.contains('username already exists')) {
      return _usernameTaken;
    } else if (msg.contains('email already exists')) {
      return _emailUsed;
    } else if (msg.contains('invalid email')) {
      return _invalidEmail;
    } else if (msg.contains('network') || msg.contains('timeout')) {
      return _connectionError;
    } else if (msg.contains('użytkownik już istnieje')) {
      return _userExists;
    } else {
      return _genericRegistrationError;
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              _buildUsernameField(),
              const SizedBox(height: 10),
              _buildEmailField(),
              const SizedBox(height: 10),
              _buildPasswordField(),
              const SizedBox(height: 10),
              _buildConfirmPasswordField(),
              const SizedBox(height: 24),
              _buildRegisterButton(),
              const SizedBox(height: 20),
              _buildMessageDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(labelText: _usernameLabel),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return _usernameRequired;
        }
        if (value.length < 3) {
          return _usernameMinLength;
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: _emailLabel),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return _emailRequired;
        }
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(value.trim())) {
          return _invalidEmailFormat;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: _passwordLabel,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _passwordRequired;
        }
        if (value.length < 6) {
          return _passwordMinLength;
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: _confirmPasswordLabel,
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value != _passwordController.text) {
          return _passwordsMismatch;
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Text(_registerButtonText),
      ),
    );
  }

  Widget _buildMessageDisplay() {
    if (_message.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      _message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: _message.contains('pomyślnie') ? Colors.green : Colors.red,
      ),
    );
  }
}
