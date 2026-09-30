import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

@pragma('vm:entry-point')
Future<void> pusherHubBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _pusherHubLog('Background message received: ${message.messageId}');
}

/// Every SDK log line goes through here, and only debug builds print — a
/// release build logs nothing, so push tokens, payloads, and server
/// responses never reach the device log of a shipped app.
void _pusherHubLog(String message) {
  if (kDebugMode) debugPrint('PusherHub: $message');
}

/// Enough of a push token to tell devices apart while debugging, without
/// writing a usable token to the log.
String _pusherHubMaskToken(String token) =>
    token.length <= 8 ? '***' : '${token.substring(0, 8)}…';

/// One in-app message returned by [PusherHub.fetchInAppMessages] — a banner,
/// modal, fullscreen, center-popup, or bottom-sheet message the backend
/// decided this device is currently eligible to see.
///
/// [contentMode] picks how it's rendered: 'simple' uses [heading]/[body]/
/// [image]/[buttonText] (the fixed fields below); 'blocks' uses [blocks], a
/// list of `{type: text|image|button, ...}` maps rendered in order; 'html'
/// uses [htmlContent], rendered in a WebView.
class InAppMessage {
  final int id;
  final String type;
  final String contentMode;
  final String? heading;
  final String? body;
  final List<Map<String, dynamic>> blocks;
  final String? htmlContent;
  final String? image;
  final String? buttonText;
  final String? buttonDeepLink;
  final String? backgroundColor;
  final String? textColor;
  final bool showCloseButton;
  final String? closeIconUrl;
  final double? closeIconWidth;
  final double? closeIconHeight;
  final String? backgroundImage;
  final double? padding;
  final int? dismissAfterSeconds;
  final Map<String, dynamic>? customData;

  InAppMessage({
    required this.id,
    required this.type,
    this.contentMode = 'simple',
    this.body,
    this.heading,
    this.blocks = const [],
    this.htmlContent,
    this.image,
    this.buttonText,
    this.buttonDeepLink,
    this.backgroundColor,
    this.textColor,
    this.showCloseButton = true,
    this.closeIconUrl,
    this.closeIconWidth,
    this.closeIconHeight,
    this.backgroundImage,
    this.padding,
    this.dismissAfterSeconds,
    this.customData,
  });

  factory InAppMessage.fromJson(Map<String, dynamic> json) {
    return InAppMessage(
      id: json['id'] as int,
      type: json['type'] as String,
      contentMode: json['content_mode'] as String? ?? 'simple',
      heading: json['heading'] as String?,
      body: json['body'] as String?,
      blocks: (json['blocks'] as List<dynamic>? ?? [])
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList(),
      htmlContent: json['html_content'] as String?,
      image: json['image'] as String?,
      buttonText: json['button_text'] as String?,
      buttonDeepLink: json['button_deep_link'] as String?,
      backgroundColor: json['background_color'] as String?,
      textColor: json['text_color'] as String?,
      showCloseButton: json['show_close_button'] as bool? ?? true,
      closeIconUrl: json['close_icon_url'] as String?,
      closeIconWidth: _pusherHubParseNum(json['close_icon_width'])?.toDouble(),
      closeIconHeight: _pusherHubParseNum(json['close_icon_height'])?.toDouble(),
      backgroundImage: json['background_image'] as String?,
      padding: _pusherHubParseNum(json['padding'])?.toDouble(),
      dismissAfterSeconds: _pusherHubParseNum(json['dismiss_after_seconds'])?.toInt(),
      customData: json['custom_data'] as Map<String, dynamic>?,
    );
  }
}

/// A custom SDK wrapper to manage push notifications with FCM and register
/// devices to the PusherHub backend.
///
/// Two-tier API, so a minimal integration stays minimal:
/// - [registerDevice] is the only required call. It needs nothing beyond
///   `firebase_core`/`firebase_messaging`/`http` and only prompts for
///   notification permission.
/// - [collectDeviceMetadata] is optional. Call it separately if you want
///   the device's brand/model/app version/language/country/timezone
///   recorded. GPS-based state/city is off by default — pass
///   `resolveLocation: true` to turn it on, which is the only thing that
///   prompts for a location permission.
/// - In-app messaging ([fetchInAppMessages] plus the tracking methods) is a
///   third, entirely optional tier — an app that never calls it behaves
///   exactly as if it didn't exist. Wrap your app in [PusherHubMessageHost] to
///   get automatic fetching-on-open and rendering for free.
///
/// Devices are identified the same way OneSignal identifies subscriptions:
/// every install gets a persistent, locally-generated anonymous ID
/// automatically — no login required to start receiving notifications. Once
/// the person signs in to your app, call [login] to alias this same device
/// to your app's real user ID (equivalent to `OneSignal.login(externalId)`).
/// Call [logout] to revert back to the anonymous identity.
class PusherHub {
  final String appKey;
  final String publicKey;

  /// Your PusherHub server's API root, e.g. `https://push.example.com/api`.
  /// Required — no default could be right for every app, and a wrong one
  /// fails quietly (the device just never registers).
  String baseUrl;

  /// Optional: called instead of the SDK's default behavior when a tapped
  /// notification carries a deep link. By default the SDK opens the deep
  /// link in an external browser; pass this if your app wants to handle it
  /// itself instead (e.g. push a specific in-app route via a Navigator/router).
  void Function(String deepLink)? onNotificationClick;

  // Bumped from 'pushhub_anonymous_id' to force installs that already
  // persisted an old 'anon-' prefixed id to generate a fresh plain-UUID one.
  static const _anonymousIdKey = 'pushhub_anonymous_id_v2';

  // The last notification permission the backend accepted, so a resume that
  // found nothing changed costs nothing.
  static const _lastReportedPermissionKey =
      'pushhub_last_reported_notification_permission';

  // The last FCM token the backend accepted. FCM rotates tokens without a
  // reinstall; reporting the one being replaced lets the backend keep this
  // install as the same device rather than counting a new install plus,
  // later, an uninstall. Cleared with the app's data on reinstall, which is
  // exactly when a new device row is the right answer.
  static const _lastRegisteredTokenKey = 'pushhub_last_registered_token';

  String? _currentToken;
  String? _currentExternalId;

  // Opens reported before the backend knew this device — track-open looks
  // the device up by token, so these wait for the first successful
  // registration instead of failing.
  final List<RemoteMessage> _pendingOpens = [];

  _PusherHubLifecycleObserver? _lifecycleObserver;
  Timer? _heartbeatTimer;

  /// Matches the window the backend's Realtime tab buckets by. Anything
  /// faster just upserts the same minute row for no extra information.
  static const _heartbeatInterval = Duration(seconds: 60);

  // Collected once on the first registerDevice() call and re-sent on every
  // subsequent registration (token refresh, login, logout) — the backend's
  // register endpoint replaces these fields wholesale, so omitting them on a
  // later call would wipe out what was already stored.
  String? _deviceModel;
  String? _deviceBrand;
  String? _appVersion;
  String? _language;
  String? _country;
  String? _timezone;
  String? _state;
  String? _city;

  PusherHub({
    required this.appKey,
    required this.publicKey,
    required this.baseUrl,
    this.onNotificationClick,
  });

  /// The identity currently registered with the backend for this device —
  /// either the auto-generated anonymous ID, or whatever was last passed to
  /// [login]. Null until [registerDevice] completes.
  String? get currentExternalId => _currentExternalId;

  /// Initializes FCM and registers the device with the PusherHub backend API.
  ///
  /// If [externalId] is omitted, a persistent anonymous ID is generated on
  /// first launch and reused across restarts (cleared only on uninstall) —
  /// matching OneSignal's default anonymous-subscription behavior. Pass an
  /// [externalId] explicitly only if the user is already known to be signed
  /// in when the app starts; otherwise prefer calling [login] later.
  Future<void> registerDevice({String? externalId}) async {
    final resolvedExternalId = externalId ?? await _getOrCreateAnonymousId();

    _pusherHubLog(
      'Starting device registration for externalId: $resolvedExternalId...',
    );

    try {
      // 1. Initialize Firebase if it hasn't been initialized yet
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        _pusherHubLog('Firebase initialized.');
      }

      // Queried as early as possible, right after Firebase is ready — on
      // some Android devices this returns null if it's only checked later,
      // after the permission prompt and the register-device network calls
      // below (a real ~1-2s delay), even though this launch genuinely was
      // caused by tapping a notification from a fully-killed app. The
      // RemoteMessage is stashed here and only acted on once _currentToken
      // is set further down, since reporting the open needs it.
      final messaging = FirebaseMessaging.instance;
      final initialMessage = await messaging.getInitialMessage();

      // 2. Request push notification permissions
      FirebaseMessaging.onBackgroundMessage(pusherHubBackgroundMessageHandler);
      FirebaseMessaging.onMessage.listen((message) {
        _pusherHubLog('Foreground message received: ${message.messageId}');
        _pusherHubLog('Foreground data: ${message.data}');
      });

      // Fires when the app was backgrounded (not terminated) and the user
      // taps the notification to bring it back to the foreground. Only
      // registered here, not fired until the user actually taps one, so
      // _currentToken is safely set (below) well before this can trigger.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

      messaging.onTokenRefresh.listen((newToken) {
        _pusherHubLog('FCM token refreshed. Re-registering device...');
        _currentToken = newToken;
        _registerToken(_currentExternalId ?? resolvedExternalId, newToken);
      });

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _pusherHubLog(
        'Notification authorization status: ${settings.authorizationStatus}',
      );
      // Registration deliberately continues even on a denial. The device
      // still has a perfectly valid FCM token, and registering it is the
      // only way the dashboard can report who opted out — bailing out here
      // would make a blocked user indistinguishable from one who never
      // installed the app. Nothing will actually be displayed to them until
      // they turn notifications back on.
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _pusherHubLog(
          'User denied push notification permissions — registering '
          'anyway so the backend records the opt-out.',
        );
      }

      _observeAppLifecycle();

      // 3. Retrieve the Firebase Cloud Messaging Token
      final token = await messaging.getToken();
      if (token == null) {
        _pusherHubLog('Error - Retrieved a null FCM token.');
        return;
      }

      _pusherHubLog('FCM token retrieved: ${_pusherHubMaskToken(token)}');

      // 4. Send the device registration details to the backend API
      _currentToken = token;
      await _registerToken(resolvedExternalId, token);

      // Fires when the app was fully terminated and the user's tap on a
      // notification is what launched it — onMessageOpenedApp (above) never
      // sees this case, since there's no already-running app to resume.
      // Uses the RemoteMessage fetched early above; now that _currentToken
      // is set, it can actually be reported.
      if (initialMessage != null) {
        _handleNotificationOpened(initialMessage);
      }
    } catch (e) {
      _pusherHubLog('Unexpected error during registration: $e');
    }
  }

  /// Optional: enriches this device's record with brand, model, app
  /// version, language, country, and timezone — none of which need a
  /// permission. Safe to call any time after [registerDevice] has
  /// completed; skips quietly if called before that.
  ///
  /// Location is off by default, and then no location permission is ever
  /// requested — the backend estimates state from the device's IP address
  /// instead. Pass [resolveLocation] `true` for GPS-accurate state and city;
  /// that prompts for a location permission, and a denial only costs the
  /// location fields.
  Future<void> collectDeviceMetadata({bool resolveLocation = false}) async {
    if (_currentToken == null || _currentExternalId == null) {
      _pusherHubLog(
        'Error - collectDeviceMetadata() called before registerDevice() completed.',
      );
      return;
    }

    await _collectDeviceMetadata(resolveLocation);
    await _registerToken(_currentExternalId!, _currentToken!);
  }

  /// Aliases this device to a real signed-in user — equivalent to
  /// `OneSignal.login(externalId)`. Re-registers the same FCM token under
  /// the new external_id, so the backend re-links the existing device to
  /// that user instead of creating a duplicate device row.
  Future<void> login(String externalId) async {
    if (_currentToken == null) {
      _pusherHubLog('Error - login() called before registerDevice() completed.');
      return;
    }

    _pusherHubLog('Logging in as externalId: $externalId...');
    await _registerToken(externalId, _currentToken!);
  }

  /// Reverts this device back to its anonymous identity — equivalent to
  /// `OneSignal.logout()`. Call this when the signed-in user logs out, so
  /// notifications aimed at them stop reaching this device.
  Future<void> logout() async {
    if (_currentToken == null) {
      _pusherHubLog('Error - logout() called before registerDevice() completed.');
      return;
    }

    final anonymousId = await _getOrCreateAnonymousId();
    _pusherHubLog('Logging out, reverting to anonymous id: $anonymousId...');
    await _registerToken(anonymousId, _currentToken!);
  }

  /// Gathers device model/brand, app version, language, and timezone from
  /// the OS (no permissions needed for those), then — only when
  /// [resolveLocation] is true — state, city, and country via
  /// [_collectState], which does need a location permission.
  Future<void> _collectDeviceMetadata(bool resolveLocation) async {
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        _deviceBrand = info.brand;
        _deviceModel = info.model;
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        _deviceBrand = 'Apple';
        _deviceModel = info.utsname.machine;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;

      // Sent as raw codes ("en", "US") — the backend translates these to
      // full names (LocaleNameResolver) so the SDK doesn't need to ship
      // its own copy of those lookup tables.
      final locale = PlatformDispatcher.instance.locale;
      _language = locale.languageCode;
      _country = locale.countryCode;

      _timezone = (await FlutterTimezone.getLocalTimezone()).identifier;

      if (resolveLocation) {
        await _collectState();
      }

      _pusherHubLog(
        'Device metadata — brand: $_deviceBrand, model: $_deviceModel, '
        'version: $_appVersion, language: $_language, country: $_country, '
        'timezone: $_timezone, state: $_state',
      );
    } catch (e) {
      _pusherHubLog('Failed to collect device metadata: $e');
    }
  }

  /// Resolves the device's state/province and city via GPS + reverse
  /// geocoding, using the OS's own free geocoder (Android's Geocoder / iOS's
  /// CLGeocoder) — no API key needed. Only runs when the app passed
  /// `resolveLocation: true`. Requires a location permission prompt; if the
  /// user denies it or location is unavailable, this fails quietly and the
  /// location fields simply stay unset rather than blocking registration.
  Future<void> _collectState() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _pusherHubLog('Location services disabled — skipping state lookup.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _pusherHubLog('Location permission denied — skipping state lookup.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _state = placemark.administrativeArea;
        _city = placemark.locality;

        // Overrides the locale-based guess in _collectDeviceMetadata() with
        // the real, GPS-derived country. Locale region is just a user-set OS
        // preference (e.g. many phones default to "English (United States)"
        // regardless of where they're actually used) — it can be flatly
        // wrong. A geocoded result from actual coordinates is trustworthy.
        final geocodedCountry = placemark.country;
        if (geocodedCountry != null && geocodedCountry.isNotEmpty) {
          _country = geocodedCountry;
        }
      }
    } catch (e) {
      _pusherHubLog('Failed to resolve state via geocoding: $e');
    }
  }

  /// This device's notification permission as the backend records it:
  /// 'granted', 'denied', or 'not_determined'.
  ///
  /// Read fresh from the OS on every call rather than cached from the
  /// [registerDevice] prompt, so a user who flips the setting in iOS/Android
  /// system settings long afterwards is reported accurately.
  Future<String> _notificationPermissionStatus() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();

      switch (settings.authorizationStatus) {
        // Provisional (iOS quiet delivery) and ephemeral (App Clips) both
        // mean notifications do arrive, which is what's being asked.
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return 'granted';
        case AuthorizationStatus.denied:
          return 'denied';
        case AuthorizationStatus.notDetermined:
          return 'not_determined';
        default:
          return 'granted';
      }
    } catch (e) {
      _pusherHubLog('Failed to read notification permission: $e');
      return 'not_determined';
    }
  }

  /// Re-reports the notification permission when it no longer matches what
  /// the backend was last told — the user turning notifications off (or back
  /// on) in system settings weeks later, which produces no callback of any
  /// kind.
  ///
  /// A no-op with no network call in the overwhelmingly common case where
  /// nothing changed, so it's safe on every foreground.
  Future<void> _syncNotificationPermissionIfChanged() async {
    final token = _currentToken;
    if (token == null) return;

    final permission = await _notificationPermissionStatus();
    final prefs = await SharedPreferences.getInstance();
    if (permission == prefs.getString(_lastReportedPermissionKey)) return;

    await _registerToken(
      _currentExternalId ?? await _getOrCreateAnonymousId(),
      token,
    );
  }

  /// Watches the app moving between foreground and background, which drives
  /// two things: re-reporting a notification permission changed in system
  /// settings, and running the Realtime heartbeat only while the app is
  /// actually on screen. Neither needs anything from the host app.
  void _observeAppLifecycle() {
    if (_lifecycleObserver != null) return;

    try {
      final observer = _PusherHubLifecycleObserver(this);
      WidgetsBinding.instance.addObserver(observer);
      _lifecycleObserver = observer;
      _startHeartbeat();
    } catch (e) {
      // No binding yet (registerDevice() called before
      // WidgetsFlutterBinding.ensureInitialized()) — permission changes then
      // simply reach the backend on the next registerDevice() instead, and
      // this device won't appear on the Realtime tab between launches.
      _pusherHubLog('Could not observe app lifecycle: $e');
    }
  }

  /// Tells the backend this device has the app open right now — the signal
  /// behind the dashboard's Realtime tab, and the only thing separating
  /// "using the app" from registerDevice()'s "launched it at some point".
  ///
  /// Silently skipped before registration completes; the next tick picks it
  /// up once a token exists.
  Future<void> _sendHeartbeat() async {
    final token = _currentToken;
    if (token == null) return;

    try {
      await http
          .post(
            Uri.parse('$baseUrl/heartbeat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $publicKey',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'app_key': appKey, 'token': token}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // A dropped heartbeat only costs one minute of Realtime resolution —
      // never worth surfacing to the host app.
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _sendHeartbeat();
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _sendHeartbeat(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<String> _getOrCreateAnonymousId() async {
    final prefs = await SharedPreferences.getInstance();

    var id = prefs.getString(_anonymousIdKey);
    if (id == null) {
      id = _generateUuidV4();
      await prefs.setString(_anonymousIdKey, id);
      _pusherHubLog('Generated new anonymous device id: $id');
    }

    return id;
  }

  String _generateUuidV4() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  Future<void> _registerToken(String externalId, String token) async {
    final permission = await _notificationPermissionStatus();
    final prefs = await SharedPreferences.getInstance();
    final previousToken = prefs.getString(_lastRegisteredTokenKey);
    final uri = Uri.parse('$baseUrl/register-device');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $publicKey',
      // Harmless against a real server; needed only when baseUrl points at
      // a free-tier ngrok tunnel — without it, ngrok returns an HTML
      // "visit site" warning page instead of forwarding to PusherHub.
      'ngrok-skip-browser-warning': 'true',
    };

    final body = jsonEncode({
      'app_key': appKey,
      'external_id': externalId,
      'token': token,
      // Covers both ways a rotation arrives: onTokenRefresh while running,
      // and getToken() returning a different token on a later launch.
      if (previousToken != null && previousToken != token)
        'previous_token': previousToken,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'unknown',
      'device': _deviceModel,
      'brand': _deviceBrand,
      'version': _appVersion,
      'language': _language,
      'country': _country,
      'state': _state,
      'city': _city,
      'timezone': _timezone,
      'notification_permission': permission,
    });

    _pusherHubLog('Registering device with backend at: $uri');
    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      _currentExternalId = externalId;
      // Only cached once the backend has actually taken it — caching a value
      // a failed request never delivered would suppress the retry on the
      // next resume. The token likewise: if this request failed, the next
      // attempt must still report the old token as the one being replaced.
      await prefs.setString(_lastReportedPermissionKey, permission);
      await prefs.setString(_lastRegisteredTokenKey, token);
      _pusherHubLog(
        'Device registered successfully. Status: ${response.statusCode}',
      );
      _flushPendingOpens();
    } else {
      _pusherHubLog(
        'Failed to register device. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  /// Reports [message] as opened — and as clicked-through too, if it carried
  /// a deep link — without navigating anywhere. `notification_id` travels in
  /// the FCM data payload (set server-side in FcmService) purely for this;
  /// a message without one isn't a PusherHub notification and is ignored.
  ///
  /// The SDK already reports every tap it sees by itself. Call this only for
  /// the ones it can't see:
  /// - Your app reads the launch notification itself with
  ///   `FirebaseMessaging.instance.getInitialMessage()` to open the right
  ///   screen. Firebase hands that message out only once, so read it before
  ///   [registerDevice] and pass it here.
  /// - A notification your app displayed itself while open on screen (e.g.
  ///   with flutter_local_notifications). Rebuild it from the payload you
  ///   stored: `RemoteMessage(data: payload)`.
  ///
  /// Safe to call before [registerDevice] finishes — the report is held
  /// until the device is registered — and safe to call for a tap already
  /// reported, since the backend only counts a device's first open.
  Future<void> trackNotificationOpened(RemoteMessage message) async {
    final notificationId = message.data['notification_id']?.toString();
    if (notificationId == null) {
      return;
    }

    if (_currentToken == null || _currentExternalId == null) {
      _pendingOpens.add(message);
      return;
    }

    _pusherHubLog('Notification opened: $notificationId');
    await _trackEvent('track-open', notificationId);

    if (_deepLinkOf(message) != null) {
      await _trackEvent('track-click', notificationId);
    }
  }

  /// A tap the SDK saw itself — resuming a backgrounded app, or cold-
  /// launching a terminated one: report it, then follow its deep link.
  void _handleNotificationOpened(RemoteMessage message) {
    if (message.data['notification_id'] == null) {
      return;
    }

    trackNotificationOpened(message);

    final deepLink = _deepLinkOf(message);
    if (deepLink != null) {
      _openDeepLink(deepLink);
    }
  }

  String? _deepLinkOf(RemoteMessage message) {
    final deepLink = message.data['deep_link']?.toString();
    return deepLink == null || deepLink.isEmpty ? null : deepLink;
  }

  void _flushPendingOpens() {
    final pending = List.of(_pendingOpens);
    _pendingOpens.clear();
    for (final message in pending) {
      trackNotificationOpened(message);
    }
  }

  /// Hands the deep link to [onNotificationClick] if the app registered
  /// one, otherwise opens it in an external browser by default — matching
  /// how OneSignal's "Launch URL" behaves out of the box.
  Future<void> _openDeepLink(String deepLink) async {
    if (onNotificationClick != null) {
      onNotificationClick!(deepLink);
      return;
    }

    final uri = Uri.tryParse(deepLink);
    if (uri == null) {
      _pusherHubLog('Ignoring malformed deep link: $deepLink');
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _pusherHubLog('No handler available to open deep link: $deepLink');
    }
  }

  Future<void> _trackEvent(String endpoint, String notificationId) async {
    if (_currentToken == null) {
      _pusherHubLog('Skipping $endpoint — no FCM token registered yet.');
      return;
    }

    final uri = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $publicKey',
      'ngrok-skip-browser-warning': 'true',
    };
    final body = jsonEncode({
      'app_key': appKey,
      'notification_id': int.tryParse(notificationId) ?? notificationId,
      'token': _currentToken,
    });

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _pusherHubLog('$endpoint reported successfully.');
      } else {
        _pusherHubLog(
          'Failed to report $endpoint. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      _pusherHubLog('Error reporting $endpoint: $e');
    }
  }

  /// Fetches the in-app messages currently eligible for this device —
  /// active, within their display window, matching this device's audience,
  /// and not already shown once (for messages set to display only once).
  /// Call this whenever you want to check for messages to show (e.g. on
  /// app open) — [PusherHubMessageHost] does this automatically.
  Future<List<InAppMessage>> fetchInAppMessages() async {
    if (_currentToken == null) {
      _pusherHubLog('Skipping fetchInAppMessages — no FCM token registered yet.');
      return [];
    }

    final uri = Uri.parse('$baseUrl/fetch-in-app-messages');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $publicKey',
      'ngrok-skip-browser-warning': 'true',
    };
    final body = jsonEncode({'app_key': appKey, 'token': _currentToken});

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _pusherHubLog(
          'Failed to fetch in-app messages. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return [];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = (decoded['messages'] as List<dynamic>? ?? [])
          .map((json) => InAppMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      _pusherHubLog('Fetched ${messages.length} eligible in-app message(s).');
      return messages;
    } catch (e) {
      _pusherHubLog('Error fetching in-app messages: $e');
      return [];
    }
  }

  /// Reports that [message] was actually displayed to the user.
  Future<void> trackInAppShown(InAppMessage message) => _trackInAppEvent('track-in-app-shown', message.id);

  /// Reports that the user tapped [message]'s button.
  Future<void> trackInAppClick(InAppMessage message) => _trackInAppEvent('track-in-app-click', message.id);

  /// Reports that [message] was closed without the button being tapped.
  Future<void> trackInAppDismiss(InAppMessage message) => _trackInAppEvent('track-in-app-dismiss', message.id);

  Future<void> _trackInAppEvent(String endpoint, int inAppMessageId) async {
    if (_currentToken == null) {
      _pusherHubLog('Skipping $endpoint — no FCM token registered yet.');
      return;
    }

    final uri = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $publicKey',
      'ngrok-skip-browser-warning': 'true',
    };
    final body = jsonEncode({
      'app_key': appKey,
      'in_app_message_id': inAppMessageId,
      'token': _currentToken,
    });

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _pusherHubLog('$endpoint reported successfully.');
      } else {
        _pusherHubLog(
          'Failed to report $endpoint. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      _pusherHubLog('Error reporting $endpoint: $e');
    }
  }
}

/// Wraps a screen that stays mounted for the app's lifetime (typically
/// `MaterialApp.home`) to automatically fetch and display [InAppMessage]s —
/// on first frame and every time the app is resumed from the background.
/// Entirely optional: an app that never uses this widget sees no in-app-
/// message behavior at all.
///
/// Must be placed *inside* the `Navigator` (i.e. as `home`, not wrapped
/// around the whole `MaterialApp`) since banner/modal/fullscreen/bottom-
/// sheet rendering all need a `BuildContext` with a Navigator/Overlay
/// ancestor:
///
/// ```dart
/// MaterialApp(home: PusherHubMessageHost(pusherHub: pusherHub, child: MyHomePage()))
/// ```
/// Watches the app move between foreground and background: re-reports a
/// notification permission the user changed in system settings while away,
/// and runs the Realtime heartbeat only while the app is actually on screen.
/// Attached automatically by [PusherHub.registerDevice] — host apps never
/// construct this themselves.
class _PusherHubLifecycleObserver with WidgetsBindingObserver {
  _PusherHubLifecycleObserver(this._pusherHub);

  final PusherHub _pusherHub;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pusherHub._syncNotificationPermissionIfChanged();
      _pusherHub._startHeartbeat();
      return;
    }

    // inactive/paused/hidden/detached all mean the app is no longer the
    // thing the user is looking at, so it should stop reporting itself as
    // active.
    _pusherHub._stopHeartbeat();
  }
}

class PusherHubMessageHost extends StatefulWidget {
  final PusherHub pusherHub;
  final Widget child;

  const PusherHubMessageHost({super.key, required this.pusherHub, required this.child});

  @override
  State<PusherHubMessageHost> createState() => _PusherHubMessageHostState();
}

class _PusherHubMessageHostState extends State<PusherHubMessageHost> with WidgetsBindingObserver {
  final List<InAppMessage> _queue = [];
  final Set<int> _shownThisRun = {};
  bool _showingMessage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForMessages());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForMessages();
    }
  }

  Future<void> _checkForMessages() async {
    final messages = await widget.pusherHub.fetchInAppMessages();
    final unseen = messages.where((m) => !_shownThisRun.contains(m.id));

    _queue.addAll(unseen);
    _showNextIfIdle();
  }

  void _showNextIfIdle() {
    if (_showingMessage || _queue.isEmpty || !mounted) return;

    final message = _queue.removeAt(0);
    _shownThisRun.add(message.id);
    _showingMessage = true;

    widget.pusherHub.trackInAppShown(message);
    _display(message).whenComplete(() {
      _showingMessage = false;
      _showNextIfIdle();
    });
  }

  /// Tracks a click and opens a link — [overrideLink] wins when given
  /// (a blocks-mode element's or the HTML mode's own click target),
  /// otherwise falls back to the message's single [InAppMessage.buttonDeepLink]
  /// (simple mode's one button).
  Future<void> _handleButtonTap(InAppMessage message, {String? overrideLink}) async {
    widget.pusherHub.trackInAppClick(message);

    final deepLink = overrideLink ?? message.buttonDeepLink;
    if (deepLink == null || deepLink.isEmpty) return;

    if (widget.pusherHub.onNotificationClick != null) {
      widget.pusherHub.onNotificationClick!(deepLink);
      return;
    }

    final uri = Uri.tryParse(deepLink);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Starts the optional auto-dismiss timer for [message], if it has one —
  /// an explicit per-message admin setting (unlike the old hardcoded
  /// banner timer this replaced), calling [dismiss] once it elapses unless
  /// the message was already closed by then.
  Timer? _startDismissTimer(InAppMessage message, VoidCallback dismiss) {
    final seconds = message.dismissAfterSeconds;
    if (seconds == null) return null;
    return Timer(Duration(seconds: seconds), dismiss);
  }

  Future<void> _display(InAppMessage message) {
    switch (message.type) {
      case 'banner':
        return _showBanner(message);
      case 'fullscreen':
        return _showFullscreen(message);
      case 'bottom_sheet':
        return _showBottomSheet(message);
      case 'modal':
      case 'center_popup':
      default:
        return _showModal(message);
    }
  }

  /// Picks the right content renderer for [message] — a WebView for 'html',
  /// the native card for 'simple'/'blocks' — behind one shared
  /// activate/close callback shape every _show* method below can use the
  /// same way regardless of content mode.
  Widget _buildCard(
    InAppMessage message, {
    required void Function(String? link) onActivate,
    required VoidCallback onClose,
    bool expand = false,
  }) {
    if (message.contentMode == 'html') {
      return _HtmlMessageCard(
        message: message,
        expand: expand,
        onActivate: onActivate,
        onClose: onClose,
        onTrackClick: () => widget.pusherHub.trackInAppClick(message),
      );
    }

    return _MessageCard(message: message, expand: expand, onActivate: onActivate, onClose: onClose);
  }

  Future<void> _showBanner(InAppMessage message) async {
    final completer = Completer<void>();
    late OverlayEntry entry;
    var resolved = false;
    Timer? dismissTimer;

    void closeWith({String? link, required bool asClick}) {
      if (resolved) return;
      resolved = true;
      dismissTimer?.cancel();
      entry.remove();
      if (asClick) {
        _handleButtonTap(message, overrideLink: link);
      } else {
        widget.pusherHub.trackInAppDismiss(message);
      }
      completer.complete();
    }

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: _buildCard(
            message,
            onActivate: (link) => closeWith(link: link, asClick: true),
            onClose: () => closeWith(asClick: false),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    dismissTimer = _startDismissTimer(message, () => closeWith(asClick: false));

    return completer.future;
  }

  Future<void> _showModal(InAppMessage message) async {
    Timer? dismissTimer;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        dismissTimer ??= _startDismissTimer(message, () => Navigator.of(context).pop());
        return Dialog(
          child: _buildCard(
            message,
            onActivate: (link) => Navigator.of(context).pop({'link': link}),
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      },
    );

    dismissTimer?.cancel();

    if (result != null) {
      await _handleButtonTap(message, overrideLink: result['link'] as String?);
    } else {
      widget.pusherHub.trackInAppDismiss(message);
    }
  }

  Future<void> _showBottomSheet(InAppMessage message) async {
    Timer? dismissTimer;

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        dismissTimer ??= _startDismissTimer(message, () => Navigator.of(context).pop());
        return _buildCard(
          message,
          onActivate: (link) => Navigator.of(context).pop({'link': link}),
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );

    dismissTimer?.cancel();

    if (result != null) {
      await _handleButtonTap(message, overrideLink: result['link'] as String?);
    } else {
      widget.pusherHub.trackInAppDismiss(message);
    }
  }

  Future<void> _showFullscreen(InAppMessage message) async {
    Timer? dismissTimer;

    final result = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          dismissTimer ??= _startDismissTimer(message, () => Navigator.of(context).pop());
          // No AppBar — a fullscreen message is meant to be an immersive,
          // edge-to-edge design (especially with a background image), and a
          // separate white bar above it just to hold a close icon breaks
          // that. The close (X) is instead the same floating overlay
          // _MessageCard already draws for every other display type.
          return Scaffold(
            body: _buildCard(
              message,
              expand: true,
              onActivate: (link) => Navigator.of(context).pop({'link': link}),
              onClose: () => Navigator.of(context).pop(),
            ),
          );
        },
      ),
    );

    dismissTimer?.cancel();

    if (result != null) {
      await _handleButtonTap(message, overrideLink: result['link'] as String?);
    } else {
      widget.pusherHub.trackInAppDismiss(message);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Color? _pusherHubParseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
  return value == null ? null : Color(value);
}

/// Block field values come from admin-authored JSON — tolerate a numeric
/// field arriving as either a JSON number or a numeric string (e.g. an
/// unsanitized "16") rather than crashing with a type-cast error.
num? _pusherHubParseNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

/// Renders 'simple' (fixed heading/body/image/button) and 'blocks' content
/// modes natively. 'html' mode is [_HtmlMessageCard] instead — see
/// [_PusherHubMessageHostState._buildCard].
class _MessageCard extends StatelessWidget {
  final InAppMessage message;
  final bool expand;
  final void Function(String? link) onActivate;
  final VoidCallback onClose;

  const _MessageCard({
    required this.message,
    required this.onActivate,
    required this.onClose,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _pusherHubParseColor(message.backgroundColor) ?? Theme.of(context).cardColor;
    final fg = _pusherHubParseColor(message.textColor) ?? Theme.of(context).textTheme.bodyMedium?.color;
    final padding = message.padding ?? 16;

    final content = Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: expand ? null : BorderRadius.circular(12),
        image: message.backgroundImage != null
            ? DecorationImage(image: NetworkImage(message.backgroundImage!), fit: BoxFit.cover)
            : null,
      ),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: expand ? MainAxisAlignment.center : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: message.contentMode == 'blocks' ? _buildBlocks(fg) : _buildSimpleFields(fg),
      ),
    );

    if (!message.showCloseButton) return content;

    return Stack(
      children: [
        content,
        Positioned(
          // Fullscreen has no AppBar reserving space at the top (it's meant
          // to bleed edge-to-edge), so its close icon needs to clear the
          // status bar/notch itself — every other display type already
          // sits below that by virtue of not touching the very top edge.
          top: (expand ? MediaQuery.of(context).padding.top : 0) + 4,
          right: 4,
          child: IconButton(
            icon: message.closeIconUrl != null
                ? Image.network(
                    message.closeIconUrl!,
                    width: message.closeIconWidth ?? 18,
                    height: message.closeIconHeight ?? 18,
                  )
                : Icon(Icons.close, size: 18, color: fg),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSimpleFields(Color? fg) {
    return [
      if (message.image != null) ...[
        // fitWidth with no fixed height shows the whole image at its
        // natural aspect ratio (matches the dashboard preview's
        // <img class="w-full"> — no crop, no letterboxing).
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(message.image!, fit: BoxFit.fitWidth, width: double.infinity),
        ),
        const SizedBox(height: 12),
      ],
      if (message.heading != null) ...[
        Text(
          message.heading!,
          // Fullscreen is a centered "hero" layout (matches the admin
          // preview and the vertical MainAxisAlignment.center above it) —
          // every other display type keeps the default start/left align.
          textAlign: expand ? TextAlign.center : null,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
        ),
        const SizedBox(height: 4),
      ],
      if (message.body != null)
        Text(
          message.body!,
          textAlign: expand ? TextAlign.center : null,
          style: TextStyle(fontSize: 14, color: fg),
        ),
      if (message.buttonText != null) ...[
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => onActivate(message.buttonDeepLink),
          child: Text(message.buttonText!),
        ),
      ],
    ];
  }

  List<Widget> _buildBlocks(Color? fg) {
    final widgets = <Widget>[];

    for (final block in message.blocks) {
      final clickAction = block['click_action'] as Map<String, dynamic>?;

      void handleTap() {
        if (clickAction == null) return;
        switch (clickAction['type']) {
          case 'close':
            onClose();
          case 'open_url':
          case 'deep_link':
            onActivate(clickAction['value'] as String?);
        }
      }

      Widget? child;
      switch (block['type']) {
        case 'text':
          child = Text(
            block['text'] as String? ?? '',
            textAlign: switch (block['align']) {
              'center' => TextAlign.center,
              'right' => TextAlign.right,
              _ => TextAlign.left,
            },
            style: TextStyle(
              fontFamily: block['font_family'] as String?,
              fontSize: _pusherHubParseNum(block['font_size'])?.toDouble() ?? 16,
              color: _pusherHubParseColor(block['color'] as String?) ?? fg,
              fontWeight: block['bold'] == true ? FontWeight.bold : FontWeight.normal,
              fontStyle: block['italic'] == true ? FontStyle.italic : FontStyle.normal,
              decoration: block['underline'] == true ? TextDecoration.underline : TextDecoration.none,
            ),
          );
          if (clickAction != null) child = GestureDetector(onTap: handleTap, child: child);
        case 'image':
          // See _buildSimpleFields' image for why fitWidth + no fixed height.
          child = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(block['image'] as String? ?? '', fit: BoxFit.fitWidth, width: double.infinity),
          );
          if (clickAction != null) child = GestureDetector(onTap: handleTap, child: child);
        case 'button':
          child = ElevatedButton(
            onPressed: clickAction != null ? handleTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _pusherHubParseColor(block['background_color'] as String?),
              foregroundColor: _pusherHubParseColor(block['font_color'] as String?),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_pusherHubParseNum(block['corner_radius'])?.toDouble() ?? 8),
              ),
            ),
            child: Text(block['text'] as String? ?? ''),
          );
      }

      if (child != null) {
        widgets.add(child);
        widgets.add(const SizedBox(height: 8));
      }
    }

    if (widgets.isNotEmpty) widgets.removeLast();
    return widgets;
  }
}

/// Renders 'html' content mode: admin-authored HTML/CSS/JS in a WebView. The
/// loaded page gets a `window.PushHubIamApi` object — `.close()`,
/// `.openUrl(url)`, `.trackClick()` — mirroring OneSignal's `OneSignalIamApi`,
/// bridged back to [onClose]/[onActivate]/[onTrackClick] via a JS channel.
///
/// Known limitation: unlike the native modes, a WebView can't report its
/// content's actual height back into the Flutter layout, so non-fullscreen
/// messages get a fixed viewport rather than sizing to content — design HTML
/// messages to fit that, or use the fullscreen type where this doesn't apply.
class _HtmlMessageCard extends StatefulWidget {
  final InAppMessage message;
  final bool expand;
  final void Function(String? link) onActivate;
  final VoidCallback onClose;
  final VoidCallback onTrackClick;

  const _HtmlMessageCard({
    required this.message,
    required this.onActivate,
    required this.onClose,
    required this.onTrackClick,
    this.expand = false,
  });

  @override
  State<_HtmlMessageCard> createState() => _HtmlMessageCardState();
}

class _HtmlMessageCardState extends State<_HtmlMessageCard> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'PusherHubNative',
        onMessageReceived: (jsMessage) {
          try {
            final data = jsonDecode(jsMessage.message) as Map<String, dynamic>;
            switch (data['action']) {
              case 'close':
                widget.onClose();
              case 'open_url':
                widget.onActivate(data['value'] as String?);
              case 'track_click':
                widget.onTrackClick();
            }
          } catch (e) {
            _pusherHubLog('Malformed PushHubIamApi message: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _controller.runJavaScript('''
            window.PushHubIamApi = {
              close: function() { PusherHubNative.postMessage(JSON.stringify({action: "close"})); },
              openUrl: function(url) { PusherHubNative.postMessage(JSON.stringify({action: "open_url", value: url})); },
              trackClick: function() { PusherHubNative.postMessage(JSON.stringify({action: "track_click"})); }
            };
          '''),
        ),
      )
      ..loadHtmlString(widget.message.htmlContent ?? '');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expand) return WebViewWidget(controller: _controller);
    return SizedBox(height: 280, child: WebViewWidget(controller: _controller));
  }
}
