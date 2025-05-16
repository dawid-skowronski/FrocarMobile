import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'rent_car_page.dart';
import 'offer_car_page.dart';
import 'login.dart';
import 'register.dart';
import 'widgets/loading_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'profile_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notifications_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Klucz do nawigacji globalnej
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Powiadomienie w tle: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'frocar_channel',
    'Frocar Notifications',
    description: 'Kanał dla powiadomień Frocar',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('Uprawnienia: ${settings.authorizationStatus}');

  String? token = await messaging.getToken();
  print('Token FCM: $token');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        Provider<ApiService>(create: (context) => ApiService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _storage = const FlutterSecureStorage();
  Timer? _notificationPollingTimer;
  Set<int> _seenNotificationIds = {};
  bool _isCheckingNotifications = false;

  @override
  void initState() {
    super.initState();

    // Inicjalizacja cyklicznego sprawdzania powiadomień
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkForNewNotifications();
    });

    // Globalna obsługa powiadomień na pierwszym planie
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Powiadomienie na pierwszym planie: ${message.messageId}');
      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'frocar_channel',
              'Frocar Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
        Provider.of<NotificationProvider>(context, listen: false).incrementNotificationCount();
      }
    });

    // Globalna obsługa kliknięcia powiadomienia
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Powiadomienie kliknięte: ${message.messageId}');
      navigatorKey.currentState?.pushNamed('/notifications');
      Provider.of<NotificationProvider>(context, listen: false).resetNotificationCount();
    });
  }

  @override
  void dispose() {
    _notificationPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForNewNotifications() async {
    if (_isCheckingNotifications) {
      print('Poprzednie sprawdzanie powiadomień wciąż trwa - pomijam.');
      return;
    }

    _isCheckingNotifications = true;
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final notifications = await apiService.fetchAccountNotifications();

      final newCount = notifications.length;
      print('Liczba nowych powiadomień: $newCount');

      bool hasNewNotifications = false;
      for (var notification in notifications) {
        final notificationId = notification['notificationId'] as int;
        if (!_seenNotificationIds.contains(notificationId)) {
          hasNewNotifications = true;
          String title = 'Nowe powiadomienie';
          final message = notification['message']?.toString() ?? 'Masz nowe powiadomienie w aplikacji.';

          if (message.contains('wypożyczenie') && message.contains('zakończone')) {
            title = 'Wypożyczenie zakończone';
          } else if (message.contains('zaakceptowane')) {
            title = 'Ogłoszenie zaakceptowane';
          }

          print('Wyświetlam powiadomienie push: Tytuł: $title, Treść: $message');
          await flutterLocalNotificationsPlugin.show(
            notificationId,
            title,
            message,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'frocar_channel',
                'Frocar Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
          print('Powiadomienie push wyświetlone.');

          _seenNotificationIds.add(notificationId);
        }
      }

      if (!hasNewNotifications) {
        print('Brak nowych powiadomień do wyświetlenia jako push.');
      }

      Provider.of<NotificationProvider>(context, listen: false).setNotificationCount(newCount);
    } catch (e) {
      print('Błąd podczas sprawdzania powiadomień: $e');
    } finally {
      _isCheckingNotifications = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Ustawiamy globalny klucz nawigacji
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
        '/': (context) => const HomePage(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/rentCar': (context) => const RentCarPage(),
        '/offerCar': (context) => OfferCarPage(),
        '/loading': (context) => const LoadingScreen(),
        '/profile': (context) => const ProfilePage(),
        '/notifications': (context) => const NotificationsPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

  Future<void> _getUsername() async {
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
          appBar: CustomAppBar(
            title: "FroCar",
            onNotificationPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
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
                      colors: const [Color(0xFF6B9071), Color(0xFF60A16B)],
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/profile');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF375534),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          ),
                          child: const Text(
                            'Profil',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
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
                          colors: const [Color(0xFF6B9071), Color(0xFF60A16B)],
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