import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/providers/user_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/reset_password_page.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
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
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
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

  final themeProvider = ThemeProvider();
  try {
    await themeProvider.loadTheme();
  } catch (e) {
    print('Nie udało się wczytać ustawień motywu. Używam domyślnych ustawień.');
  }

  await _syncPendingListingsAtStart();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        Provider<ApiService>(create: (context) => ApiService()),
        Provider<FlutterSecureStorage>.value(value: const FlutterSecureStorage()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _syncPendingListingsAtStart() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> pendingListings = prefs.getStringList('pending_listings') ?? [];

  if (pendingListings.isEmpty) return;

  final apiService = ApiService();
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    print('Brak internetu – synchronizacja danych później.');
    return;
  }

  for (String listingJson in List.from(pendingListings)) {
    try {
      final carListing = CarListing.fromJson(jsonDecode(listingJson));
      await apiService.createCarListing(carListing);
      pendingListings.remove(listingJson);
      await prefs.setStringList('pending_listings', pendingListings);
      print('Zsynchronizowano ogłoszenie: ${carListing.brand}');
    } catch (e) {
      print('Nie udało się zsynchronizować danych. Spróbuję później.');
      continue;
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _notificationPollingTimer;
  Set<int> _seenNotificationIds = {};
  bool _isCheckingNotifications = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadSeenNotificationIds(); // Odczytujemy zapisane ID powiadomień
    _checkAndRefreshLogin();
    _notificationPollingTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
          _checkForNewNotifications();
        });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Powiadomienie na pierwszym planie: ${message.messageId}');
      if (message.notification != null) {
        final notificationId = message.hashCode;
        if (!_seenNotificationIds.contains(notificationId)) {
          flutterLocalNotificationsPlugin.show(
            notificationId,
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
          _seenNotificationIds.add(notificationId);
          _saveSeenNotificationIds(); // Zapisujemy ID po wyświetleniu
          Provider.of<NotificationProvider>(context, listen: false)
              .incrementNotificationCount();
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Powiadomienie kliknięte: ${message.messageId}');
      navigatorKey.currentState?.pushNamed('/notifications');
      Provider.of<NotificationProvider>(context, listen: false)
          .resetNotificationCount();
    });

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        print('Internet przywrócony – synchronizuję dane.');
        _syncPendingListingsAtStart();
      }
    });
  }

  // Funkcja do odczytywania zapisanych ID powiadomień
  Future<void> _loadSeenNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('seen_notification_ids') ?? [];
    setState(() {
      _seenNotificationIds = savedIds.map((id) => int.parse(id)).toSet();
    });
    print('Wczytano zapisane ID powiadomień: $_seenNotificationIds');
  }

  // Funkcja do zapisywania ID powiadomień
  Future<void> _saveSeenNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'seen_notification_ids', _seenNotificationIds.map((id) => id.toString()).toList());
    print('Zapisano ID powiadomień: $_seenNotificationIds');
  }

  Future<void> _checkAndRefreshLogin() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);

    final tokenValid = await apiService.isTokenValid();
    if (!tokenValid) {
      final username = await storage.read(key: 'username');
      final password = await storage.read(key: 'password');
      if (username != null && password != null) {
        try {
          await apiService.login(username, password);
          print('Automatyczne logowanie powiodło się dla użytkownika: $username');
        } catch (e) {
          print('Automatyczne logowanie nie powiodło się: $e');
          await storage.delete(key: 'token');
          await storage.delete(key: 'username');
          await storage.delete(key: 'password');
          Provider.of<UserProvider>(context, listen: false).logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesja wygasła. Zaloguj się ponownie.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _notificationPollingTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkForNewNotifications() async {
    if (_isCheckingNotifications) {
      print('Sprawdzanie powiadomień wciąż trwa – pomijam.');
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
          final message = notification['message']?.toString() ??
              'Masz nowe powiadomienie w aplikacji.';

          if (message.contains('wypożyczenie') && message.contains('zakończone')) {
            title = 'Wypożyczenie zakończone';
          } else if (message.contains('zaakceptowane')) {
            title = 'Ogłoszenie zaakceptowane';
          }

          print('Wyświetlam powiadomienie: Tytuł: $title, Treść: $message');
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
          print('Powiadomienie wyświetlone.');
          _seenNotificationIds.add(notificationId);
          _saveSeenNotificationIds(); // Zapisujemy ID po wyświetleniu
        }
      }

      if (!hasNewNotifications) {
        print('Brak nowych powiadomień.');
      }

      Provider.of<NotificationProvider>(context, listen: false)
          .setNotificationCount(newCount);
    } catch (e) {
      print('Nie udało się pobrać powiadomień. Spróbuję ponownie później.');
    } finally {
      _isCheckingNotifications = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
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
        '/reset-password': (context) => const ResetPasswordPage(),
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

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  Future<void> _getUsername() async {
    final _storage = Provider.of<FlutterSecureStorage>(context, listen: false);
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
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