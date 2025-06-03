# FrocarMobile
## Funkcjonalności

| ID        | Opis funkcjonalności                                      | API | Web | Mobile | Desktop |
|-----------|----------------------------------------------------------|-----|-----|--------|---------|
| RENT-01   | Pierwszy administrator jest automatycznie dodany do systemu.  | ✅    |     |        |         |
| RENT-02   | Administrator może zalogować się w systemie.            | ✅    |     |        | ✓       |
| RENT-03   | Administrator może dodawać pojazdy do systemu.          | ✅    |     |        | ✓       |
| RENT-04   | Administrator może edytować i usuwać pojazdy.           | ✅    |     |        | ✓       |
| RENT-05   | Administrator może zatwierdzać i usuwać ogłoszenia użytkowników. | ✅    |     |        | ✓       |
| RENT-06   | Administrator widzi statystyki systemowe.               |    |     |        | ✓       |
| RENT-07   | Użytkownik może przeglądać dostępne pojazdy.            | ✅    | ✅   | ✅     |         |
| RENT-08   | Użytkownik może filtrować pojazdy według kategorii, ceny i lokalizacji. | ✅    | ✅  | ✅      |         |
| RENT-09   | Użytkownik może zobaczyć lokalizację pojazdu na mapie.  | ✅    | ✅   | ✅      |         |
| RENT-10   | Użytkownik może zarejestrować się w systemie.           | ✅    | ✅   | ✅      |         |
| RENT-11   | Użytkownik może zalogować się w systemie.               | ✅    | ✅   | ✅      |         |
| RENT-12   | Użytkownik może zresetować swoje hasło.                 | ✅   | ✅   | ✅      |         |
| RENT-13   | Użytkownik może wynająć pojazd na określony czas.       | ✅   | ✅   | ✅      |         |
| RENT-14   | Użytkownik otrzymuje powiadomienia o statusie rezerwacji. | ✅   | ✅   | ✅      |         |
| RENT-15   | Użytkownik widzi historię swoich wynajmów.              | ✅️   | ✅️   | ✅      |         |
| RENT-16   | Właściciel pojazdu może dodać swój pojazd do wynajmu.   | ✅    | ✅   | ✅      |         |
| RENT-17   | Właściciel może edytować i usuwać swoje ogłoszenia.     | ✅    | ✅   | ✅      |         |
| RENT-18   | Użytkownik może oceniać i recenzować wynajęte pojazdy.  | ✅️   | ✅️   | ✅      |         |
| RENT-19   | Użytkownik może się wylogować.                          |   ✅   | ✅   | ✅      |         |

## 🔗 Linki do innych części FroCar:

- [🔌 API](https://github.com/dawid-skowronski/FrocarAPI)
- [🌐 Web](https://github.com/dawid-skowronski/FrocarWeb)
- [🖥️ Desktop](https://github.com/dawid-skowronski/FrocarDesktop)


# Instrukcja Uruchomienia Aplikacji Mobilnej

## Wymagania Wstępne

Zanim zaczniesz, upewnij się, że masz zainstalowane i skonfigurowane następujące narzędzia:

- **Flutter SDK**: Sprawdź, czy masz zainstalowaną wersję Fluttera kompatybilną z projektem (zalecana 3.29.0). Wersję sprawdzisz komendą `flutter --version` w terminalu.
- **IDE**: Rekomenduję Android Studio z zainstalowanym pluginem Flutter.
- **Urządzenie/Emulator**: Potrzebujesz aktywnego emulatora Androida/iOS lub fizycznego urządzenia mobilnego z włączonym debugowaniem USB.
- **Połączenie z Internetem**: Jest niezbędne do pobrania zależności projektu oraz komunikacji z backendem.
- **Klucz API Google Maps**: Upewnij się, że masz skonfigurowany klucz API Google Maps dla swojego projektu Flutter.

## Uruchomienie Lokalne

Aby uruchomić aplikację mobilną z kodem źródłowym na swoim komputerze:

### Sklonuj Repozytorium:

Otwórz terminal (lub Wiersz Polecenia / PowerShell na Windowsie), sklonuj projekt, a następnie przejdź do katalogu aplikacji mobilnej:

```bash
git clone https://github.com/dawid-skowronski/FrocarMobile
cd FrocarMobile/frocar_project
```

Pobierz Zależności:
W katalogu FrocarMobile/frocar_project uruchom poniższą komendę, aby pobrać wszystkie wymagane pakiety:

```bash
flutter pub get
```

Uruchom Aplikację:
Upewnij się, że masz uruchomiony emulator lub podłączone fizyczne urządzenie. Następnie uruchom aplikację:

```bash
flutter run
```

Aplikacja zostanie zbudowana i zainstalowana na wybranym urządzeniu/emulatorze.

Konfiguracja Backendu (jeśli lokalny):
Jeśli zamierzasz uruchomić backend lokalnie, musisz upewnić się, że jest on dostępny pod adresem, który jest skonfigurowany w aplikacji mobilnej. 
Domyślnie, w pliku lib/services/api_service.dart znajduje się adres zdalny. 

Uruchomienie Zdalne (Wersja Produkcyjna)
Aplikacja mobilna jest domyślnie skonfigurowana do komunikacji ze zdalnym backendem. Adres URL tego backendu jest zdefiniowany w pliku lib/services/api_service.dart. Aktualnie to:

```bash
final String baseUrl = 'https://projekt-tripify.hostingasp.pl';
```

Dla uruchomienia zdalnego nie są wymagane żadne dodatkowe kroki konfiguracyjne poza standardowym uruchomieniem aplikacji (flutter run). 
Wystarczy, że zdalny backend jest dostępny pod podanym adresem URL. Aplikacja, uruchomiona w ten sposób, będzie automatycznie pobierać i wysyłać dane do zdalnie hostowanego systemu.