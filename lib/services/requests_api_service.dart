import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for the self-hosted Pignify Requests API.
///
/// The API is LAN/VPN only (port 8091), so the URL is typically something like
/// `http://192.168.1.30:8091` or `http://10.224.29.1:8091`.
class PignifyApiConfig {
  final String baseUrl;
  final String token;

  const PignifyApiConfig({required this.baseUrl, required this.token});

  bool get isConfigured =>
      baseUrl.trim().isNotEmpty && token.trim().isNotEmpty;

  PignifyApiConfig copyWith({String? baseUrl, String? token}) {
    return PignifyApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
    );
  }
}

class RequestSearchResult {
  final String videoId;
  final String title;
  final String artist;
  final String album;
  final int? duration;
  final String? thumbnail;
  final bool inLibrary;

  const RequestSearchResult({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.album,
    this.duration,
    this.thumbnail,
    this.inLibrary = false,
  });

  factory RequestSearchResult.fromJson(Map<String, dynamic> json) {
    String text(dynamic value) => value?.toString().trim() ?? '';

    final artists = json['artists'] ?? json['artist'] ?? json['uploader'];
    String artist;
    if (artists is List) {
      artist = artists
          .map((e) => e is Map ? (e['name'] ?? e).toString() : e.toString())
          .where((e) => e.trim().isNotEmpty)
          .join(', ');
    } else {
      artist = text(artists);
    }

    return RequestSearchResult(
      videoId: text(json['videoId'] ?? json['video_id'] ?? json['id']),
      title: text(json['title'] ?? json['name']),
      artist: artist.isEmpty ? 'Unknown artist' : artist,
      album: text(json['album'] ?? json['albumName']),
      duration: _asInt(json['duration'] ?? json['lengthSeconds']),
      thumbnail: text(json['thumbnail'] ?? json['thumbnailUrl'] ?? json['cover'])
              .isEmpty
          ? null
          : text(json['thumbnail'] ?? json['thumbnailUrl'] ?? json['cover']),
      inLibrary: json['inLibrary'] == true || json['in_library'] == true,
    );
  }

  String get durationLabel {
    final seconds = duration ?? 0;
    if (seconds <= 0) return '';
    final minutes = seconds ~/ 60;
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

enum RequestJobStatus {
  queued,
  downloading,
  tagging,
  moving,
  done,
  error;

  static RequestJobStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'queued':
      case 'pending':
        return RequestJobStatus.queued;
      case 'downloading':
        return RequestJobStatus.downloading;
      case 'tagging':
        return RequestJobStatus.tagging;
      case 'moving':
        return RequestJobStatus.moving;
      case 'done':
      case 'completed':
      case 'complete':
        return RequestJobStatus.done;
      case 'error':
      case 'failed':
        return RequestJobStatus.error;
      default:
        return RequestJobStatus.queued;
    }
  }
}

class RequestJob {
  final String id;
  final RequestJobStatus status;
  final double? progress;
  final String? error;
  final String? path;
  final String? songId;
  final String? title;

  const RequestJob({
    required this.id,
    required this.status,
    this.progress,
    this.error,
    this.path,
    this.songId,
    this.title,
  });

  bool get isTerminal =>
      status == RequestJobStatus.done || status == RequestJobStatus.error;

  factory RequestJob.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    double? progress;
    if (rawProgress is num) {
      var value = rawProgress.toDouble();
      if (value > 1) value /= 100;
      progress = value.clamp(0.0, 1.0).toDouble();
    }

    return RequestJob(
      id: (json['id'] ?? json['jobId'] ?? json['job_id'] ?? '').toString(),
      status: RequestJobStatus.parse(json['status']?.toString()),
      progress: progress,
      error: json['error']?.toString(),
      path: json['path']?.toString(),
      songId: json['songId']?.toString() ?? json['song_id']?.toString(),
      title: json['title']?.toString(),
    );
  }
}

class RequestsApiException implements Exception {
  final String message;
  const RequestsApiException(this.message);

  @override
  String toString() => message;
}

/// Thin client for the Pignify Requests API.
///
/// Endpoints: `GET /health`, `GET /search`, `POST /download`,
/// `GET /jobs/{id}`, `GET /jobs`.
class RequestsApiService {
  static final RequestsApiService _instance =
      RequestsApiService._internal();
  factory RequestsApiService() => _instance;
  RequestsApiService._internal();

  static const String _urlKey = 'pignify_requests_url';
  static const String _tokenKey = 'pignify_requests_token';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  PignifyApiConfig? _config;
  Dio? _dio;

  Future<PignifyApiConfig?> loadConfig() async {
    if (_config != null && _config!.isConfigured) return _config;
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_urlKey) ?? '';
    final token = await _secureStorage.read(key: _tokenKey) ?? '';
    final config = PignifyApiConfig(baseUrl: url, token: token);
    _config = config.isConfigured ? config : null;
    return _config;
  }

  Future<void> saveConfig(PignifyApiConfig config) async {
    final normalized = config.copyWith(
      baseUrl: _normalizeBaseUrl(config.baseUrl),
      token: config.token.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, normalized.baseUrl);
    await _secureStorage.write(key: _tokenKey, value: normalized.token);
    _config = normalized;
    _dio = null;
  }

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
    await _secureStorage.delete(key: _tokenKey);
    _config = null;
    _dio = null;
  }

  String _normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<Dio> _client() async {
    final existing = _dio;
    if (existing != null) return existing;

    final config = await loadConfig();
    if (config == null) {
      throw const RequestsApiException(
        'Requests API is not configured yet.',
      );
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Authorization': 'Bearer ${config.token}'},
      ),
    );
    _dio = dio;
    return dio;
  }

  Future<Map<String, dynamic>> health() async {
    final dio = await _client();
    try {
      final response = await dio.get<dynamic>('/health');
      return _asMap(response.data);
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  Future<List<RequestSearchResult>> search(
    String query, {
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return const [];
    final dio = await _client();
    try {
      final response = await dio.get<dynamic>(
        '/search',
        queryParameters: {'q': query.trim(), 'limit': limit},
      );
      return _parseSearchResults(response.data);
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  Future<String> download(
    RequestSearchResult result, {
    String? playlist,
  }) async {
    final dio = await _client();
    try {
      final response = await dio.post<dynamic>(
        '/download',
        data: {
          'videoId': result.videoId,
          'artist': result.artist,
          'title': result.title,
          'album': result.album,
          if (result.duration != null) 'duration': result.duration,
          if (playlist != null && playlist.isNotEmpty) 'playlist': playlist,
        },
      );
      final data = _asMap(response.data);
      final jobId = (data['jobId'] ?? data['job_id'] ?? data['id'] ?? '')
          .toString();
      if (jobId.isEmpty) {
        throw const RequestsApiException(
          'The server did not return a job id.',
        );
      }
      return jobId;
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  Future<RequestJob> getJob(String jobId) async {
    final dio = await _client();
    try {
      final response = await dio.get<dynamic>('/jobs/$jobId');
      final data = _asMap(response.data);
      if ((data['id'] ?? data['jobId'] ?? data['job_id'] ?? '')
          .toString()
          .isEmpty) {
        data['id'] = jobId;
      }
      return RequestJob.fromJson(data);
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  Future<List<RequestJob>> getJobs({int limit = 20}) async {
    final dio = await _client();
    try {
      final response = await dio.get<dynamic>(
        '/jobs',
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      final raw = data is Map
          ? (data['jobs'] ?? data['items'] ?? data['results'] ?? const [])
          : data;
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => RequestJob.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  List<RequestSearchResult> _parseSearchResults(dynamic data) {
    dynamic raw = data;
    if (data is Map) {
      raw = data['youtube'] ??
          data['results'] ??
          data['items'] ??
          data['songs'] ??
          const [];
      // Some servers return `{local: [...], youtube: [...]}`; when only
      // local results exist we still want to show them.
      if (raw is! List || raw.isEmpty) {
        raw = data['local'] ?? const [];
      }
    }
    if (raw is! List) return const [];

    final results = <RequestSearchResult>[];
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final result = RequestSearchResult.fromJson(
        Map<String, dynamic>.from(item),
      );
      // Only YouTube video ids are downloadable through the Requests API.
      if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(result.videoId)) continue;
      if (!seen.add(result.videoId)) continue;
      results.add(result);
    }
    return results;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  RequestsApiException _friendlyError(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? detail;
    if (data is Map) {
      detail = (data['detail'] ?? data['error'] ?? data['message'])?.toString();
    }
    if (status == 401 || status == 403) {
      return const RequestsApiException(
        'Invalid API token. Check it in the Requests settings.',
      );
    }
    if (detail != null && detail.isNotEmpty) {
      return RequestsApiException(detail);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const RequestsApiException(
        'The server did not respond. Are you on the LAN or VPN?',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const RequestsApiException(
        'Cannot reach the Requests API. Check the URL and your LAN/VPN.',
      );
    }
    if (status != null) {
      return RequestsApiException('Server error (HTTP $status).');
    }
    debugPrint('RequestsApiService error: $error');
    return const RequestsApiException('Unexpected server error.');
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}
