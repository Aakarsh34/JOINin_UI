import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/socket_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart';
import '../services/user_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState extends ChangeNotifier {
  AuthState() {
    ApiClient.instance.registerAuthExpiredHandler(_onAuthExpired);
  }

  final AuthService _auth = AuthService();
  final UserService _users = UserService();

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isBusy => _busy;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;

  Future<void> bootstrap() async {
    await TokenStorage.instance.hydrate();
    if (TokenStorage.instance.accessToken == null) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    // Optimistic path: if we cached the user from a previous run we render
    // MainNavigation immediately and refresh `/users/me` in the background.
    // This cuts the splash-to-home time on warm launches from ~1-2 s of
    // network round-trip down to a single secure-storage read (~10-30 ms).
    final cachedSnapshot = TokenStorage.instance.userSnapshot;
    if (cachedSnapshot != null) {
      try {
        final decoded = json.decode(cachedSnapshot);
        if (decoded is Map<String, dynamic>) {
          _user = AppUser.fromJson(decoded);
          _status = AuthStatus.signedIn;
          notifyListeners();
          SocketClient.instance.connect();
          unawaited(_refreshProfileInBackground());
          return;
        }
      } catch (_) {
        // Fall through to the network path on corrupt cache.
      }
    }

    try {
      _user = await _users.getMe();
      _status = AuthStatus.signedIn;
      unawaited(_persistUserSnapshot());
      SocketClient.instance.connect();
    } catch (_) {
      // The Dio interceptor already tries to refresh on 401 and signals via
      // _onAuthExpired if that fails, so any error here means the session
      // can't be recovered.
      await TokenStorage.instance.clear();
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> _refreshProfileInBackground() async {
    try {
      final fresh = await _users.getMe();
      _user = fresh;
      notifyListeners();
      await _persistUserSnapshot();
    } catch (_) {
      // Network hiccup — keep the cached user on-screen and try again next
      // bootstrap. Auth failures are handled by the Dio refresh interceptor.
    }
  }

  Future<void> _persistUserSnapshot() async {
    final user = _user;
    if (user == null) return;
    try {
      await TokenStorage.instance.saveUserSnapshot(json.encode(user.toJson()));
    } catch (_) {
      // Cache write is best-effort; runtime user state is unaffected.
    }
  }

  Future<void> loginWithPhone({required String phone, String? name}) async {
    _setBusy(true);
    try {
      final result = await _auth.loginWithPhone(phone: phone, name: name);
      _user = result.user;
      _status = AuthStatus.signedIn;
      _error = null;
      SocketClient.instance.connect();
      notifyListeners();
      unawaited(_persistUserSnapshot());
    } catch (e) {
      _error = _readableError(e);
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> loginWithGoogle({required String idToken}) async {
    _setBusy(true);
    try {
      final result = await _auth.loginWithGoogle(idToken: idToken);
      _user = result.user;
      _status = AuthStatus.signedIn;
      _error = null;
      SocketClient.instance.connect();
      notifyListeners();
      unawaited(_persistUserSnapshot());
    } catch (e) {
      _error = _readableError(e);
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> refreshProfile() async {
    if (!isSignedIn) return;
    try {
      _user = await _users.getMe();
      notifyListeners();
      await _persistUserSnapshot();
    } catch (_) {}
  }

  Future<void> signOut() async {
    _setBusy(true);
    SocketClient.instance.disconnect();
    await _auth.logout();
    try {
      await GoogleSignInService.instance.signOut();
    } catch (_) {}
    _user = null;
    _status = AuthStatus.signedOut;
    _error = null;
    _setBusy(false);
  }

  void _onAuthExpired() {
    SocketClient.instance.disconnect();
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  String _readableError(Object error) {
    final message = error.toString();
    if (message.contains('ApiException')) {
      final m = RegExp(r':\s(.+)$').firstMatch(message);
      if (m != null) return m.group(1)!;
    }
    return message;
  }
}
