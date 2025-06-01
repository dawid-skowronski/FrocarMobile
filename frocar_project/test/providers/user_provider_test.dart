import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/providers/user_provider.dart';

import 'user_provider_test.mocks.dart';

class MockJwtDecoder extends Mock implements JwtDecoderInterface {
  @override
  Map<String, dynamic> decode(String token) => super.noSuchMethod(
    Invocation.method(#decode, [token]),
    returnValue: <String, dynamic>{},
    returnValueForMissingStub: <String, dynamic>{},
  );
}

@GenerateMocks([], customMocks: [
  MockSpec<FlutterSecureStorage>(as: #MockUserFlutterSecureStorage),
])
void main() {
  group('UserProvider Tests', () {
    late UserProvider provider;
    late MockUserFlutterSecureStorage mockStorage;
    late MockJwtDecoder mockJwtDecoder;

    setUp(() {
      mockStorage = MockUserFlutterSecureStorage();
      mockJwtDecoder = MockJwtDecoder();
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);
      provider = UserProvider(storage: mockStorage, jwtDecoder: mockJwtDecoder);
      return Future.delayed(Duration.zero);
    });

    test('Początkowy userId to null, jeśli nie ma zapisanego tokenu', () async {
      expect(provider.userId, null);
      verify(mockStorage.read(key: 'token')).called(1);
    });

    test('Wczytuje userId z tokenu, jeśli token istnieje', () async {
      const token = 'valid_token';
      final decodedToken = {
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier': '123'
      };
      reset(mockStorage);
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
      when(mockJwtDecoder.decode(token)).thenReturn(decodedToken);

      provider = UserProvider(storage: mockStorage, jwtDecoder: mockJwtDecoder);
      await Future.delayed(Duration.zero);

      expect(provider.userId, 123);
      verify(mockStorage.read(key: 'token')).called(1);
      verify(mockJwtDecoder.decode(token)).called(1);
    });

    test('setUserId ustawia userId i powiadamia słuchaczy', () {
      var notifyCalled = false;
      provider.addListener(() {
        notifyCalled = true;
      });

      provider.setUserId(456);

      expect(provider.userId, 456);
      expect(notifyCalled, true);
      verify(mockStorage.read(key: 'token')).called(1);
    });

    test('logout usuwa token, ustawia userId na null i powiadamia słuchaczy', () async {
      when(mockStorage.delete(key: 'token')).thenAnswer((_) async => {});
      provider.setUserId(789);
      var notifyCalled = false;
      provider.addListener(() {
        notifyCalled = true;
      });

      await provider.logout();

      expect(provider.userId, null);
      expect(notifyCalled, true);
      verify(mockStorage.delete(key: 'token')).called(1);
      verify(mockStorage.read(key: 'token')).called(1);
    });

    test('Błąd dekodowania tokenu ustawia userId na null', () async {
      const token = 'invalid_token';
      reset(mockStorage);
      when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
      when(mockJwtDecoder.decode(token)).thenThrow(Exception('Błąd dekodowania'));

      provider = UserProvider(storage: mockStorage, jwtDecoder: mockJwtDecoder);
      await Future.delayed(Duration.zero);

      expect(provider.userId, null);
      verify(mockStorage.read(key: 'token')).called(1);
      verify(mockJwtDecoder.decode(token)).called(1);
    });
  });
}