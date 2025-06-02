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

const String _firebaseChannelId = 'frocar_channel';
const String _firebaseChannelName = 'Frocar Notifications';
const String _firebaseChannelDescription = 'Kanał dla powiadomień Frocar';
const String _dotEnvFileName = ".env";
const String _seenNotificationsKey = 'seen_notification_ids';
const String _pendingListingsKey = 'pending_listings';
const String _tokenKey = 'token';
const String _usernameKey = 'username';
const String _passwordKey = 'password';

const String _noInternetSyncMessage = 'Brak internetu – synchronizacja danych później.';
const String _syncSuccessMessage = 'Zsynchronizowano ogłoszenie:';
const String _syncErrorMessage = 'Nie udało się zsynchronizować danych. Spróbuję później.';
const String _themeLoadErrorMessage = 'Nie udało się wczytać ustawień motywu. Używam domyślnych ustawień.';
const String _autoLoginSuccessMessage = 'Automatyczne logowanie powiodło się dla użytkownika:';
const String _autoLoginErrorMessage = 'Automatyczne logowanie nie powiodło się:';
const String _sessionExpiredMessage = 'Sesja wygasła. Zaloguj się ponownie.';
const String _checkingNotificationsMessage = 'Sprawdzanie powiadomień wciąż trwa – pomijam.';
const String _newNotificationTitle = 'Nowe powiadomienie';
const String _genericNotificationMessage = 'Masz nowe powiadomienie w aplikacji.';
const String _rentalFinishedTitle = 'Wypożyczenie zakończone';
const String _listingAcceptedTitle = 'Ogłoszenie zaakceptowane';
const String _noNewNotificationsMessage = 'Brak nowych powiadomień.';
const String _fetchNotificationsErrorMessage = 'Nie udało się pobrać powiadomień. Spróbuję ponownie później.';

const String _homePageTitle = "FroCar";
const String _rentCarText = "Chcę wynająć samochód";
const String _offerCarText = "Chcę oddać samochód pod wynajem";
const String _profileButtonText = 'Profil';
const String _welcomeMessage = "Witamy w FroCar";
const String _loginButtonText = "Zaloguj";
const String _registerButtonText = "Zarejestruj";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Powiadomienie w tle: ${message.messageId}');
}

Future<void> _setupFirebaseAndNotifications() async {
  await dotenv.load(fileName: _dotEnvFileName);
  await Firebase.initializeApp();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    _firebaseChannelId,
    _firebaseChannelName,
    description: _firebaseChannelDescription,
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
  debugPrint('Uprawnienia: ${settings.authorizationStatus}');

  String? token = await messaging.getToken();
  debugPrint('Token FCM: $token');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _loadAndSyncTheme(ThemeProvider themeProvider) async {
  try {
    await themeProvider.loadTheme();
  } catch (e) {
    debugPrint('$_themeLoadErrorMessage: $e');
  }
}

Future<void> _syncPendingListingsAtStart() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> pendingListings = prefs.getStringList(_pendingListingsKey) ?? [];

  if (pendingListings.isEmpty) return;

  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    debugPrint(_noInternetSyncMessage);
    return;
  }

  final apiService = ApiService();
  for (String listingJson in List.from(pendingListings)) {
    try {
      final carListing = CarListing.fromJson(jsonDecode(listingJson));
      await apiService.createCarListing(carListing);
      pendingListings.remove(listingJson);
      await prefs.setStringList(_pendingListingsKey, pendingListings);
      debugPrint('$_syncSuccessMessage ${carListing.brand}');
    } catch (e) {
      debugPrint('$_syncErrorMessage $e');
      continue;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupFirebaseAndNotifications();

  final themeProvider = ThemeProvider();
  await _loadAndSyncTheme(themeProvider);

  await _syncPendingListingsAtStart();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        Provider<ApiService>(create: (context) => ApiService()),
        Provider<FlutterSecureStorage>.value(value: const FlutterSecureStorage()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
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
  Timer? _notificationPollingTimer;
  Set<int> _seenNotificationIds = {};
  bool _isCheckingNotifications = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadSeenNotificationIds();
    _checkAndRefreshLogin();
    _setupNotificationPolling();
    _setupFirebaseMessageListeners();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _notificationPollingTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationPolling() {
    _notificationPollingTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
          _checkForNewNotifications();
        });
  }

  void _setupFirebaseMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Powiadomienie na pierwszym planie: ${message.messageId}');
      if (message.notification != null) {
        _handleForegroundNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Powiadomienie kliknięte: ${message.messageId}');
      navigatorKey.currentState?.pushNamed('/notifications');
      Provider.of<NotificationProvider>(context, listen: false).resetNotificationCount();
    });
  }

  void _handleForegroundNotification(RemoteMessage message) {
    final notificationId = message.hashCode;
    if (!_seenNotificationIds.contains(notificationId)) {
      flutterLocalNotificationsPlugin.show(
        notificationId,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _firebaseChannelId,
            _firebaseChannelName,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      _seenNotificationIds.add(notificationId);
      _saveSeenNotificationIds();
      Provider.of<NotificationProvider>(context, listen: false).incrementNotificationCount();
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        debugPrint('Internet przywrócony – synchronizuję dane.');
        _syncPendingListingsAtStart();
      }
    });
  }

  Future<void> _loadSeenNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_seenNotificationsKey) ?? [];
    setState(() {
      _seenNotificationIds = savedIds.map((id) => int.parse(id)).toSet();
    });
    debugPrint('Wczytano zapisane ID powiadomień: $_seenNotificationIds');
  }

  Future<void> _saveSeenNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _seenNotificationsKey, _seenNotificationIds.map((id) => id.toString()).toList());
    debugPrint('Zapisano ID powiadomień: $_seenNotificationIds');
  }

  Future<void> _checkAndRefreshLogin() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final tokenValid = await apiService.isTokenValid();
    if (tokenValid) {
      return;
    }

    final username = await storage.read(key: _usernameKey);
    final password = await storage.read(key: _passwordKey);

    if (username != null && password != null) {
      try {
        await apiService.login(username, password);
        debugPrint('$_autoLoginSuccessMessage $username');
      } catch (e) {
        debugPrint('$_autoLoginErrorMessage $e');
        await storage.delete(key: _tokenKey);
        await storage.delete(key: _usernameKey);
        await storage.delete(key: _passwordKey);
        userProvider.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(_sessionExpiredMessage)),
          );
        }
      }
    }
  }

  Future<void> _checkForNewNotifications() async {
    if (_isCheckingNotifications) {
      debugPrint(_checkingNotificationsMessage);
      return;
    }

    _isCheckingNotifications = true;
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final notifications = await apiService.fetchAccountNotifications();
      final newCount = notifications.length;
      debugPrint('Liczba nowych powiadomień: $newCount');

      bool hasNewNotifications = false;
      for (var notification in notifications) {
        final notificationId = notification['notificationId'] as int;
        if (!_seenNotificationIds.contains(notificationId)) {
          hasNewNotifications = true;
          _displayNotification(notificationId, notification['message']?.toString());
        }
      }

      if (!hasNewNotifications) {
        debugPrint(_noNewNotificationsMessage);
      }

      Provider.of<NotificationProvider>(context, listen: false).setNotificationCount(newCount);
    } catch (e) {
      debugPrint('$_fetchNotificationsErrorMessage $e');
    } finally {
      _isCheckingNotifications = false;
    }
  }

  void _displayNotification(int id, String? message) {
    String title = _newNotificationTitle;
    final displayMessage = message?.isNotEmpty == true ? message! : _genericNotificationMessage;

    if (displayMessage.contains('wypożyczenie') && displayMessage.contains('zakończone')) {
      title = _rentalFinishedTitle;
    } else if (displayMessage.contains('zaakceptowane')) {
      title = _listingAcceptedTitle;
    }

    debugPrint('Wyświetlam powiadomienie: Tytuł: $title, Treść: $displayMessage');
    flutterLocalNotificationsPlugin.show(
      id,
      title,
      displayMessage,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _firebaseChannelId,
          _firebaseChannelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
    debugPrint('Powiadomienie wyświetlone.');
    _seenNotificationIds.add(id);
    _saveSeenNotificationIds();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      initialRoute: '/splash',
      routes: _buildRoutes(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE0E0E0),
      primaryColor: Colors.green,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: Colors.green,
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
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
    };
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
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
    final username = await storage.read(key: _usernameKey);
    setState(() {
      _username = username ?? '';
    });
  }

  double _getOverlayOpacity() {
    return (_dragOffset.abs() / 100).clamp(0.0, 1.0);
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_username!.isNotEmpty) {
      setState(() {
        _dragOffset = (_dragOffset + details.primaryDelta!).clamp(-100, 100);
      });
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            title: _homePageTitle,
            onNotificationPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          body: GestureDetector(
            onVerticalDragUpdate: _handleVerticalDragUpdate,
            onVerticalDragEnd: _handleVerticalDragEnd,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_username!.isNotEmpty) _buildLoggedInContentBody(context),
                if (_username!.isEmpty) _buildLoggedOutContent(context),
              ],
            ),
          ),
          bottomNavigationBar: _username!.isNotEmpty ? _buildProfileButton(context) : null,
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

  Widget _buildLoggedInContentBody(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    const double torHeight = 280.0;
    final double torTop = (screenHeight - torHeight) / 2;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: torTop,
          left: (MediaQuery.of(context).size.width - 80) / 2,
          child: _buildDragAreaBackground(torHeight),
        ),
        Positioned(
          top: 16.0,
          left: 0,
          right: 0,
          child: _buildUsernameGreeting(),
        ),
        Positioned(
          top: torTop - 40,
          left: 0,
          right: 0,
          child: _buildRentCarText(),
        ),
        Positioned(
          bottom: screenHeight - torTop - torHeight - 210,
          left: 0,
          right: 0,
          child: _buildOfferCarText(),
        ),
        Positioned(
          top: screenHeight / 2 + _dragOffset - 40,
          child: _buildDragIndicator(),
        ),
      ],
    );
  }

  Widget _buildDragAreaBackground(double height) {
    return Container(
      width: 80,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(40),
      ),
    );
  }

  Widget _buildUsernameGreeting() {
    return GradientText(
      "Cześć $_username!",
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      colors: const [Color(0xFF6B9071), Color(0xFF60A16B)],
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRentCarText() {
    return Text(
      _rentCarText,
      textAlign: TextAlign.center,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFAEC3B0),
      ),
    );
  }

  Widget _buildOfferCarText() {
    return Text(
      _offerCarText,
      textAlign: TextAlign.center,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFAEC3B0),
      ),
    );
  }

  Widget _buildDragIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF6B9071).withOpacity(0.8),
      ),
      child: const Icon(Icons.swap_vert, size: 40, color: Colors.white),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
              _profileButtonText,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWelcomeText(),
          const SizedBox(height: 20),
          _buildLoginRegisterButtons(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return GradientText(
      _welcomeMessage,
      style: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      colors: const [Color(0xFF6B9071), Color(0xFF60A16B)],
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoginRegisterButtons(BuildContext context) {
    return Column(
      children: [
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
            _loginButtonText,
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
            _registerButtonText,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
