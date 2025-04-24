import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'rent_car_page.dart';
import 'offer_car_page.dart';
import 'login.dart';
import 'register.dart';
import '/widgets/loading_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'profile_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv

Future<void> main() async {
  // Załaduj plik .env przed uruchomieniem aplikacji
  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE0E0E0),
        primaryColor: Colors.green,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.green,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => LoadingScreen(nextRoute: '/'),
        '/': (context) => HomePage(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/rentCar': (context) => const RentCarPage(),
        '/offerCar': (context) => OfferCarPage(),
        '/loading': (context) => const LoadingScreen(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

// Reszta kodu (HomePage, _HomePageState) pozostaje bez zmian
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _username = '';
  double _dragOffset = 0.0;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  _getUsername() async {
    final username = await _storage.read(key: 'username');
    setState(() {
      _username = username ?? '';
    });
  }

  double _getOverlayOpacity() {
    return (_dragOffset.abs() / 100).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final torHeight = 280.0;
    final torTop = (screenHeight - torHeight) / 2;

    return Stack(
      children: [
        Scaffold(
          appBar: const CustomAppBar(title: "FroCar"),
          body: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (_username!.isNotEmpty) {
                setState(() {
                  _dragOffset = (_dragOffset + details.primaryDelta!).clamp(-100, 100);
                });
              }
            },
            onVerticalDragEnd: (details) {
              if (_username!.isNotEmpty) {
                if (_dragOffset < -50) {
                  Navigator.pushNamed(context, '/loading', arguments: '/rentCar');
                } else if (_dragOffset > 50) {
                  Navigator.pushNamed(context, '/loading', arguments: '/offerCar');
                }
                setState(() {
                  _dragOffset = 0.0;
                });
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_username!.isNotEmpty) ...[
                  Positioned(
                    top: torTop,
                    left: (MediaQuery.of(context).size.width - 80) / 2,
                    child: Container(
                      width: 80,
                      height: torHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16.0,
                    left: 0,
                    right: 0,
                    child: GradientText(
                      "Cześć $_username!",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      colors: [const Color(0xFF6B9071), const Color(0xFF60A16B)],
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Positioned(
                    top: torTop - 40,
                    left: 0,
                    right: 0,
                    child: Text(
                      "Chcę wynająć samochód",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFAEC3B0),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight - torTop - torHeight - 120,
                    left: 0,
                    right: 0,
                    child: Text(
                      "Chcę oddać samochód pod wynajem",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFAEC3B0),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight / 2 + _dragOffset - 40,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6B9071).withOpacity(0.8),
                      ),
                      child: const Icon(Icons.swap_vert, size: 40, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF375534),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Profil',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
                if (_username!.isEmpty) ...[
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GradientText(
                          "Witamy w FroCar",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          colors: [const Color(0xFF6B9071), const Color(0xFF60A16B)],
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF375534),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                            elevation: 5,
                          ),
                          child: Text(
                            "Zaloguj",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF375534),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                            elevation: 5,
                          ),
                          child: Text(
                            "Zarejestruj",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_username!.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                color: const Color(0xFF375534).withOpacity(_getOverlayOpacity()),
              ),
            ),
          ),
      ],
    );
  }
}