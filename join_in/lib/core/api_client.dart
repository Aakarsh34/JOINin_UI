import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'api_exception.dart';
import 'token_storage.dart';

typedef OnAuthExpired = void Function();

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
      responseType: ResponseType.json,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = TokenStorage.instance.accessToken;
        if (token != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final requestPath = error.requestOptions.path;
        final isRefresh = requestPath.contains('/auth/refresh');
        final triedRefresh = error.requestOptions.extra['_triedRefresh'] == true;

        if (status == 401 && !isRefresh && !triedRefresh) {
          final refreshed = await _attemptRefresh();
          if (refreshed) {
            final retried = error.requestOptions
              ..extra['_triedRefresh'] = true
              ..headers['Authorization'] =
                  'Bearer ${TokenStorage.instance.accessToken}';
            try {
              final response = await _dio.fetch(retried);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(e is DioException
                  ? e
                  : DioException(requestOptions: retried, error: e));
            }
          } else {
            _onAuthExpired?.call();
          }
        }

        return handler.next(error);
      },
    ));

    if (Env.enableHttpLogging && kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
    }
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  OnAuthExpired? _onAuthExpired;
  bool _refreshing = false;
  Completer<bool>? _refreshCompleter;

  void registerAuthExpiredHandler(OnAuthExpired handler) {
    _onAuthExpired = handler;
  }

  Future<bool> _attemptRefresh() async {
    if (_refreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }
    _refreshing = true;
    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = TokenStorage.instance.refreshToken;
      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final response = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      await TokenStorage.instance.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      _refreshCompleter!.complete(true);
      return true;
    } catch (_) {
      await TokenStorage.instance.clear();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<T> _request<T>(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) {
    return _request<T>(() => _dio.get(path, queryParameters: query));
  }

  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? query}) {
    return _request<T>(
      () => _dio.post(path, data: body, queryParameters: query),
    );
  }

  Future<T> patch<T>(String path, {Object? body}) {
    return _request<T>(() => _dio.patch(path, data: body));
  }

  Future<T> delete<T>(String path) {
    return _request<T>(() => _dio.delete(path));
  }

  Future<T> postMultipart<T>(String path, FormData form) {
    return _request<T>(() => _dio.post(path, data: form));
  }
}
