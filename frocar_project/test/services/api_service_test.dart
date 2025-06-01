import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/car_rental_review.dart';
import 'package:test_project/models/notification.dart';

import 'api_service_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<http.Client>(as: #MockHttpClient),
  MockSpec<FlutterSecureStorage>(as: #MockFlutterSecureStorage),
])
void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockHttpClient mockHttpClient;
    late MockFlutterSecureStorage mockStorage;

    const String baseUrl = 'https://projekt-tripify.hostingasp.pl';
    const String defaultToken = 'jwt_token';
    const Map<String, String> defaultHeaders = {
      'Content-Type': 'application/json',
    };
    const Map<String, String> authHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $defaultToken',
    };

    CarListing createCarListing({
      int id = 1,
      String brand = 'Toyota',
      double engineCapacity = 2.0,
      String fuelType = 'Petrol',
      int seats = 5,
      String carType = 'Sedan',
      List<String> features = const ['AC', 'GPS'],
      double latitude = 52.2297,
      double longitude = 21.0122,
      int userId = 1,
      bool isAvailable = true,
      double rentalPricePerDay = 100.0,
      bool isApproved = false,
      double averageRating = 4.5,
    }) {
      return CarListing(
        id: id,
        brand: brand,
        engineCapacity: engineCapacity,
        fuelType: fuelType,
        seats: seats,
        carType: carType,
        features: features,
        latitude: latitude,
        longitude: longitude,
        userId: userId,
        isAvailable: isAvailable,
        rentalPricePerDay: rentalPricePerDay,
        isApproved: isApproved,
        averageRating: averageRating,
      );
    }

    Map<String, dynamic> createCarListingJson(CarListing carListing) {
      return {
        'id': carListing.id,
        'brand': carListing.brand,
        'engineCapacity': carListing.engineCapacity,
        'fuelType': carListing.fuelType,
        'seats': carListing.seats,
        'carType': carListing.carType,
        'features': carListing.features,
        'latitude': carListing.latitude,
        'longitude': carListing.longitude,
        'userId': carListing.userId,
        'isAvailable': carListing.isAvailable,
        'rentalPricePerDay': carListing.rentalPricePerDay,
        'isApproved': carListing.isApproved,
        'averageRating': carListing.averageRating,
      };
    }

    Map<String, dynamic> createCarRentalJson(CarRental carRental) {
      return {
        'carRentalId': carRental.carRentalId,
        'carListingId': carRental.carListingId,
        'userId': carRental.userId,
        'rentalStartDate': carRental.rentalStartDate.toIso8601String(),
        'rentalEndDate': carRental.rentalEndDate.toIso8601String(),
        'rentalPrice': carRental.rentalPrice,
        'rentalStatus': carRental.rentalStatus,
        'carListing': createCarListingJson(carRental.carListing),
      };
    }

    Map<String, dynamic> createUserJson({
      int id = 1,
      String username = 'testuser',
      String email = 'test@example.com',
    }) {
      return {
        'id': id,
        'username': username,
        'email': email,
      };
    }

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockStorage = MockFlutterSecureStorage();
      apiService = ApiService(storage: mockStorage, client: mockHttpClient);

      when(mockStorage.read(key: 'token')).thenAnswer((_) async => defaultToken);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value'))).thenAnswer((_) async {});
      when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
    });

    test('register returns response on success', () async {
      final url = Uri.parse('$baseUrl/api/account/register');
      final responseBody = {'message': 'Registration successful'};
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);
      when(mockHttpClient.post(
        url,
        headers: defaultHeaders,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.register('testuser', 'test@example.com', 'password123', 'password123');

      expect(result, responseBody);
      verify(mockHttpClient.post(
        url,
        headers: defaultHeaders,
        body: json.encode({
          'Username': 'testuser',
          'Email': 'test@example.com',
          'Password': 'password123',
          'ConfirmPassword': 'password123',
        }),
      )).called(1);
    });

    test('register throws exception on error', () async {
      final url = Uri.parse('$baseUrl/api/account/register');
      final errorBody = {'message': 'User already exists'};
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);
      when(mockHttpClient.post(
        url,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(json.encode(errorBody), 400));

      expect(
            () => apiService.register('testuser', 'test@example.com', 'password123', 'password123'),
        throwsA(predicate((e) => e.toString().contains('User already exists'))),
      );
    });

    test('login saves token and returns response on success', () async {
      final url = Uri.parse('$baseUrl/api/account/login');
      final responseBody = {'token': defaultToken, 'message': 'Login successful'};
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);
      when(mockHttpClient.post(
        url,
        headers: defaultHeaders,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.login('testuser', 'password123');

      expect(result, responseBody);
      verify(mockStorage.write(key: 'token', value: defaultToken)).called(1);
      verify(mockStorage.write(key: 'username', value: 'testuser')).called(1);
    });

    test('login throws exception on invalid credentials', () async {
      final url = Uri.parse('$baseUrl/api/account/login');
      final errorBody = {'message': 'Invalid credentials'};
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);
      when(mockHttpClient.post(
        url,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(json.encode(errorBody), 401));

      expect(
            () => apiService.login('testuser', 'wrongpassword'),
        throwsA(predicate((e) => e.toString().contains('Invalid credentials'))),
      );
    });

    test('logout clears storage on success', () async {
      final url = Uri.parse('$baseUrl/api/Account/logout');
      when(mockHttpClient.post(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response('', 200));

      await apiService.logout();

      verify(mockStorage.delete(key: 'token')).called(1);
      verify(mockStorage.delete(key: 'username')).called(1);
    });

    test('createCarListing sends correct request', () async {
      final url = Uri.parse('$baseUrl/api/CarListings/create');
      final carListing = createCarListing();
      when(mockHttpClient.post(
        url,
        headers: authHeaders,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('', 200));

      await apiService.createCarListing(carListing);

      verify(mockHttpClient.post(
        url,
        headers: authHeaders,
        body: json.encode(carListing.toJson()),
      )).called(1);
    });

    test('updateCarListing sends correct request', () async {
      final carListing = createCarListing();
      final url = Uri.parse('$baseUrl/api/CarListings/1');
      when(mockHttpClient.put(
        url,
        headers: authHeaders,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('', 200));

      await apiService.updateCarListing(carListing);

      verify(mockHttpClient.put(
        url,
        headers: authHeaders,
        body: json.encode(carListing.toJson()),
      )).called(1);
    });

    test('getUserCarListings returns listings', () async {
      final url = Uri.parse('$baseUrl/api/CarListings/user');
      final responseBody = [
        createCarListingJson(createCarListing(id: 1)),
        createCarListingJson(createCarListing(id: 2, brand: 'Honda', rentalPricePerDay: 90.0, averageRating: 4.0)),
      ];
      when(mockHttpClient.get(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.getUserCarListings();

      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[1].id, 2);
    });

    test('getUserCarListings returns empty list on 404', () async {
      final url = Uri.parse('$baseUrl/api/CarListings/user');
      when(mockHttpClient.get(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response('', 404));

      final result = await apiService.getUserCarListings();

      expect(result, isEmpty);
    });

    test('getCarListings returns listings', () async {
      final url = Uri.parse('$baseUrl/api/CarListings/List');
      final responseBody = [
        createCarListingJson(createCarListing(id: 1)),
        createCarListingJson(createCarListing(id: 2, brand: 'Honda', rentalPricePerDay: 90.0, averageRating: 4.0)),
      ];
      when(mockHttpClient.get(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.getCarListings();

      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[1].id, 2);
    });

    test('getCarListings returns empty list on 404', () async {
      final url = Uri.parse('$baseUrl/api/CarListings/List');
      when(mockHttpClient.get(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response('', 404));

      final result = await apiService.getCarListings();

      expect(result, isEmpty);
    });

    test('deleteCarListing sends correct request', () async {
      final url = Uri.parse('$baseUrl/api/CarListings/1');
      when(mockHttpClient.delete(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response('', 200));

      await apiService.deleteCarListing(1);

      verify(mockHttpClient.delete(
        url,
        headers: authHeaders,
      )).called(1);
    });

    test('createCarRental sends correct request', () async {
      final url = Uri.parse('$baseUrl/api/CarRental/create');
      final startDate = DateTime(2025, 6, 1);
      final endDate = DateTime(2025, 6, 5);
      when(mockHttpClient.post(
        url,
        headers: authHeaders,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('', 200));

      await apiService.createCarRental(1, startDate, endDate);

      verify(mockHttpClient.post(
        url,
        headers: authHeaders,
        body: json.encode({
          'carListingId': 1,
          'rentalStartDate': startDate.toIso8601String(),
          'rentalEndDate': endDate.toIso8601String(),
        }),
      )).called(1);
    });

    test('getUserCarRentals returns rentals from active and history', () async {
      final activeUrl = Uri.parse('$baseUrl/api/CarRental/user');
      final historyUrl = Uri.parse('$baseUrl/api/CarRental/user/history');
      final carListing = createCarListing();
      final activeRentals = [
        {
          'carRentalId': 1,
          'carListingId': 1,
          'userId': 1,
          'rentalStartDate': '2025-06-01T00:00:00Z',
          'rentalEndDate': '2025-06-05T00:00:00Z',
          'rentalPrice': 500.0,
          'rentalStatus': 'Active',
          'carListing': createCarListingJson(carListing),
        },
      ];
      final endedRentals = [
        {
          'carRentalId': 2,
          'carListingId': 2,
          'userId': 1,
          'rentalStartDate': '2025-07-01T00:00:00Z',
          'rentalEndDate': '2025-07-05T00:00:00Z',
          'rentalPrice': 600.0,
          'rentalStatus': 'Ended',
          'carListing': createCarListingJson(carListing),
        },
      ];
      when(mockHttpClient.get(
        activeUrl,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(json.encode(activeRentals), 200));
      when(mockHttpClient.get(
        historyUrl,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(json.encode(endedRentals), 200));

      final result = await apiService.getUserCarRentals();

      expect(result.length, 2);
      expect(result[0].carRentalId, 2); // Najnowszy (2025-07-01)
      expect(result[1].carRentalId, 1); // Starszy (2025-06-01)
    });

    test('getUserCarRentals returns empty list when both active and history are empty', () async {
      final activeUrl = Uri.parse('$baseUrl/api/CarRental/user');
      final historyUrl = Uri.parse('$baseUrl/api/CarRental/user/history');
      when(mockHttpClient.get(
        activeUrl,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('', 404));
      when(mockHttpClient.get(
        historyUrl,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('', 404));

      final result = await apiService.getUserCarRentals();

      expect(result, isEmpty);
    });

    test('getReviewsForListing returns sorted reviews', () async {
      final url = Uri.parse('$baseUrl/api/CarRental/reviews/1');
      final carListing = createCarListing(id: 1);
      final carRental1 = CarRental(
        carRentalId: 1,
        carListingId: 1,
        userId: 1,
        rentalStartDate: DateTime.parse('2025-06-01T00:00:00Z'),
        rentalEndDate: DateTime.parse('2025-06-05T00:00:00Z'),
        rentalPrice: 500.0,
        rentalStatus: 'Ended',
        carListing: carListing,
      );
      final carRental2 = CarRental(
        carRentalId: 2,
        carListingId: 2,
        userId: 1,
        rentalStartDate: DateTime.parse('2025-07-01T00:00:00Z'),
        rentalEndDate: DateTime.parse('2025-07-05T00:00:00Z'),
        rentalPrice: 600.0,
        rentalStatus: 'Ended',
        carListing: createCarListing(id: 2),
      );
      final responseBody = [
        {
          'reviewId': 1,
          'carRentalId': 1,
          'carRental': createCarRentalJson(carRental1),
          'userId': 1,
          'user': createUserJson(id: 1, username: 'testuser1', email: 'test1@example.com'),
          'rating': 5,
          'comment': 'Great car!',
          'createdAt': '2025-06-01T00:00:00Z',
        },
        {
          'reviewId': 2,
          'carRentalId': 2,
          'carRental': createCarRentalJson(carRental2),
          'userId': 1,
          'user': createUserJson(id: 1, username: 'testuser1', email: 'test1@example.com'),
          'rating': 4,
          'comment': 'Good experience',
          'createdAt': '2025-07-01T00:00:00Z',
        },
      ];
      when(mockHttpClient.get(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.getReviewsForListing(1);

      expect(result.length, 2);
      expect(result[0].reviewId, 2); // Najnowszy (2025-07-01)
      expect(result[1].reviewId, 1); // Starszy (2025-06-01)
    });

    test('getReviewsForListing returns empty list on 404', () async {
      final url = Uri.parse('$baseUrl/api/CarRental/reviews/1');
      when(mockHttpClient.get(
        url,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('', 404));

      final result = await apiService.getReviewsForListing(1);

      expect(result, isEmpty);
    });

    test('addReview sends correct request', () async {
      final url = Uri.parse('$baseUrl/api/CarRental/review');
      when(mockHttpClient.post(
        url,
        headers: authHeaders,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('', 200));

      await apiService.addReview(1, 5, 'Great car!');

      verify(mockHttpClient.post(
        url,
        headers: authHeaders,
        body: json.encode({
          'carRentalId': 1,
          'rating': 5,
          'comment': 'Great car!',
        }),
      )).called(1);
    });

    test('fetchNotifications returns notifications', () async {
      final url = Uri.parse('$baseUrl/api/Notification');
      final responseBody = [
        {
          'notificationId': 1,
          'message': 'New notification',
          'userId': 1,
          'isRead': false,
          'createdAt': '2025-06-01T00:00:00Z',
        },
      ];
      when(mockHttpClient.get(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.fetchNotifications();

      expect(result.length, 1);
      expect(result[0].notificationId, 1);
    });

    test('fetchNotifications returns empty list on no notifications', () async {
      final url = Uri.parse('$baseUrl/api/Notification');
      final responseBody = {'message': 'No new notifications'};
      when(mockHttpClient.get(
        url,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.fetchNotifications();

      expect(result, isEmpty);
    });

    test('markNotificationAsRead sends correct request', () async {
      final url = Uri.parse('$baseUrl/api/Notification/1');
      when(mockHttpClient.patch(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response('', 200));

      await apiService.markNotificationAsRead(1);

      verify(mockHttpClient.patch(
        url,
        headers: authHeaders,
      )).called(1);
    });

    test('fetchAccountNotifications returns notifications', () async {
      final url = Uri.parse('$baseUrl/api/Account/Notification');
      final responseBody = [
        {'notificationId': 1, 'message': 'Account notification'},
      ];
      when(mockHttpClient.get(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.fetchAccountNotifications();

      expect(result.length, 1);
      expect(result[0]['notificationId'], 1);
    });

    test('fetchAccountNotifications returns empty list on no notifications', () async {
      final url = Uri.parse('$baseUrl/api/Account/Notification');
      final responseBody = {'message': 'No notifications'};
      when(mockHttpClient.get(
        url,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(json.encode(responseBody), 200));

      final result = await apiService.fetchAccountNotifications();

      expect(result, isEmpty);
    });

    test('fetchAccountNotifications throws on timeout', () async {
      final url = Uri.parse('$baseUrl/api/Account/Notification');
      when(mockHttpClient.get(
        url,
        headers: anyNamed('headers'),
      )).thenAnswer((_) => Future.delayed(Duration(seconds: 15), () => throw TimeoutException('Timeout')));

      expect(
            () => apiService.fetchAccountNotifications(),
        throwsA(predicate((e) => e.toString().contains('Przekroczono czas oczekiwania'))),
      );
    });

    test('markAccountNotificationAsRead sends correct request', () async {
      final url = Uri.parse('$baseUrl/api/Account/Notification/1');
      when(mockHttpClient.patch(
        url,
        headers: authHeaders,
      )).thenAnswer((_) async => http.Response('', 200));

      await apiService.markAccountNotificationAsRead(1);

      verify(mockHttpClient.patch(
        url,
        headers: authHeaders,
      )).called(1);
    });

    test('method throws when no token for auth required', () async {
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);

      expect(
            () => apiService.getCarListings(),
        throwsA(predicate((e) => e.toString().contains('Brak tokenu JWT'))),
      );
    });

    test('method throws on invalid JSON response', () async {
      final url = Uri.parse('$baseUrl/api/account/register');
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);
      when(mockHttpClient.post(
        url,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('invalid json', 400));

      expect(
            () => apiService.register('testuser', 'test@example.com', 'password123', 'password123'),
        throwsException,
      );
    });
  });
}