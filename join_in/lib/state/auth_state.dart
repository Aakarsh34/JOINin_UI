import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/socket_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
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
    try {
      _user = await _users.getMe();
      _status = AuthStatus.signedIn;
      SocketClient.instance.connect();
    } catch (_) {
      await TokenStorage.instance.clear();
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<int> sendOtp(String phone) async {
    _setBusy(true);
    try {
      final expiresIn = await _auth.sendOtp(phone);
      _error = null;
      return expiresIn;
    } catch (e) {
      _error = _readableError(e);
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    _setBusy(true);
    try {
      final result = await _auth.verifyOtp(phone: phone, otp: otp);
      _user = result.user;
      _status = AuthStatus.signedIn;
      _error = null;
      SocketClient.instance.connect();
      notifyListeners();
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
    } catch (_) {}
  }

  Future<void> signOut() async {
    _setBusy(true);
    SocketClient.instance.disconnect();
    await _auth.logout();
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
