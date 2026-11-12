import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../services/requests_api_service.dart';
import '../../theme/ytm_tokens.dart';
import '../../utils/context_extensions.dart';

/// Search YouTube Music through the self-hosted Requests API and download the
/// selected track into the Navidrome library.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final RequestsApiService _api = RequestsApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  PignifyApiConfig? _config;
  bool _loadingConfig = true;
  bool? _healthy;

  Timer? _debounce;
  Timer? _pollTimer;
  int _searchGeneration = 0;
  bool _searching = false;
  String? _searchError;
  String _query = '';
  List<RequestSearchResult> _results = const [];

  final Set<String> _starting = <String>{};
  final Set<String> _completedVideoIds = <String>{};
  final Map<String, RequestJob> _jobs = <String, RequestJob>{};
  final Map<String, String> _videoByJob = <String, String>{};
  final Map<String, String> _jobByVideo = <String, String>{};
  final Set<String> _notifiedDone = <String>{};

  @override
  void initState() {
    super.initState();
    _restoreConfig();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pollTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _restoreConfig() async {
    final config = await _api.loadConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _loadingConfig = false;
    });
    if (config != null) {
      _checkHealth();
    }
  }

  Future<void> _checkHealth() async {
    try {
      await _api.health();
      if (!mounted) return;
      setState(() => _healthy = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _healthy = false);
    }
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
        _searchError = null;
        _searching = false;
      });
      return;
    }
    if (_config == null) {
      setState(() {
        _query = query;
        _results = const [];
        _searchError = null;
      });
      return;
    }

    final generation = ++_searchGeneration;
    setState(() {
      _query = query;
      _searching = true;
      _searchError = null;
    });

    try {
      final results = await _api.search(query, limit: 20);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searching = false;
        _searchError = error.toString();
      });
    }
  }

  Future<void> _requestDownload(RequestSearchResult result) async {
    if (result.videoId.isEmpty || _starting.contains(result.videoId)) return;
    setState(() => _starting.add(result.videoId));
    try {
      final jobId = await _api.download(result);
      if (!mounted) return;
      setState(() {
        _jobs[jobId] = RequestJob(
          id: jobId,
          status: RequestJobStatus.queued,
          title: result.title,
        );
        _videoByJob[jobId] = result.videoId;
        _jobByVideo[result.videoId] = jobId;
        _starting.remove(result.videoId);
      });
      _ensurePolling();
      _showSnack('Queued “${result.title}”.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _starting.remove(result.videoId));
      _showSnack(error.toString(), isError: true);
    }
  }

  void _ensurePolling() {
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollJobs(),
    );
  }

  Future<void> _pollJobs() async {
    final pending =
        _jobs.values.where((job) => !job.isTerminal).toList(growable: false);
    if (pending.isEmpty) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    for (final job in pending) {
      try {
        final updated = await _api.getJob(job.id);
        if (!mounted) return;
        final videoId = _videoByJob[updated.id] ?? _videoByJob[job.id];
        setState(() {
          _jobs[updated.id] = updated;
          if (updated.status == RequestJobStatus.done && videoId != null) {
            _completedVideoIds.add(videoId);
            _jobByVideo.remove(videoId);
          }
        });
        if (updated.status == RequestJobStatus.done &&
            _notifiedDone.add(updated.id)) {
          _showSnack('Added to your library.');
          Provider.of<LibraryProvider>(context, listen: false)
              .refresh()
              .catchError((_) {});
        } else if (updated.status == RequestJobStatus.error &&
            _notifiedDone.add(updated.id)) {
          _showSnack(updated.error ?? 'Download failed.', isError: true);
          if (videoId != null) {
            setState(() => _jobByVideo.remove(videoId));
          }
        }
      } catch (_) {
        // Transient network error: keep polling while the job is active.
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFB3261E) : YtmColors.surfaceHighest,
      ),
    );
  }

  Future<void> _showConfigSheet() async {
    final current = _config;
    final urlController = TextEditingController(
      text: current?.baseUrl ?? 'http://192.168.1.30:8091',
    );
    final tokenController = TextEditingController(text: current?.token ?? '');
    var saving = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.isDark ? YtmColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: YtmRadii.sheetRadius),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = context.isDark;
            final fieldColor =
                isDark ? YtmColors.surfaceHigh : YtmColors.lightSurface;

            Future<void> save() async {
              final url = urlController.text.trim();
              final token = tokenController.text.trim();
              if (url.isEmpty || token.isEmpty) {
                setSheetState(() => error = 'URL and token are required.');
                return;
              }
              setSheetState(() {
                saving = true;
                error = null;
              });
              final normalizedUrl = url.startsWith('http://') ||
                      url.startsWith('https://')
                  ? url
                  : 'http://$url';
              final config = PignifyApiConfig(
                baseUrl: normalizedUrl,
                token: token,
              );
              try {
                await _api.saveConfig(config);
                if (!mounted) return;
                setState(() {
                  _config = config.copyWith(
                    baseUrl: _apiNormalizedUrl(normalizedUrl),
                  );
                });
                Navigator.of(sheetContext).pop();
                _checkHealth();
                if (_query.isNotEmpty) {
                  _runSearch(_query);
                }
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  error = e.toString();
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: YtmSpacing.lg,
                right: YtmSpacing.lg,
                top: YtmSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + YtmSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requests API',
                    style: YtmText.sectionTitle.copyWith(
                      color: isDark
                          ? YtmColors.textPrimary
                          : YtmColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: YtmSpacing.xs),
                  Text(
                    'The API runs on your server and is reachable only on the '
                    'LAN or through WireGuard. The token is in '
                    '~/Pignify_server/.env (PIGNIFY_API_TOKEN).',
                    style: YtmText.listSubtitle.copyWith(
                      color: isDark
                          ? YtmColors.textSecondary
                          : YtmColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: YtmSpacing.lg),
                  TextField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    style: YtmText.body.copyWith(
                      color: isDark
                          ? YtmColors.textPrimary
                          : YtmColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'API URL',
                      hintText: 'http://192.168.1.30:8091',
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: YtmRadii.cardRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: YtmSpacing.md),
                  TextField(
                    controller: tokenController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: YtmText.body.copyWith(
                      color: isDark
                          ? YtmColors.textPrimary
                          : YtmColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'API token',
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: YtmRadii.cardRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: YtmSpacing.sm),
                    Text(
                      error!,
                      style: const TextStyle(color: YtmColors.danger),
                    ),
                  ],
                  const SizedBox(height: YtmSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving ? null : save,
                      style: FilledButton.styleFrom(
                        backgroundColor: YtmColors.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: YtmRadii.cardRadius,
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    urlController.dispose();
    tokenController.dispose();
  }

  String _apiNormalizedUrl(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  RequestJob? _activeJobFor(String videoId) {
    final jobId = _jobByVideo[videoId];
    if (jobId == null) return null;
    return _jobs[jobId];
  }

  String _jobLabel(RequestJob job) {
    switch (job.status) {
      case RequestJobStatus.queued:
        return 'Queued';
      case RequestJobStatus.downloading:
        return 'Downloading';
      case RequestJobStatus.tagging:
        return 'Tagging';
      case RequestJobStatus.moving:
        return 'Adding to library';
      case RequestJobStatus.done:
        return 'Added';
      case RequestJobStatus.error:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = isDark ? YtmColors.bg : YtmColors.lightBg;
    final foreground =
        isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Requests',
          style: YtmText.sectionTitle.copyWith(color: foreground),
        ),
        actions: [
          if (_config != null)
            Tooltip(
              message: _healthy == null
                  ? 'Checking server…'
                  : _healthy == true
                      ? 'API online'
                      : 'API unreachable',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _healthy == null
                          ? YtmColors.textTertiary
                          : _healthy == true
                              ? const Color(0xFF3DD68C)
                              : YtmColors.danger,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Requests settings',
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            onPressed: _showConfigSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loadingConfig
          ? const Center(child: CircularProgressIndicator())
          : _config == null
              ? _buildNotConfigured(isDark)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        YtmSpacing.md,
                        YtmSpacing.xs,
                        YtmSpacing.md,
                        YtmSpacing.sm,
                      ),
                      child: _buildSearchField(isDark),
                    ),
                    Expanded(child: _buildBody(isDark)),
                  ],
                ),
    );
  }

  Widget _buildNotConfigured(bool isDark) {
    final foreground =
        isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    final secondary =
        isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(YtmSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark ? YtmColors.surfaceHigh : YtmColors.lightSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.cloud_download,
                size: 40,
                color: YtmColors.brand,
              ),
            ),
            const SizedBox(height: YtmSpacing.lg),
            Text(
              'Download music on request',
              textAlign: TextAlign.center,
              style: YtmText.sectionTitle.copyWith(color: foreground),
            ),
            const SizedBox(height: YtmSpacing.xs),
            Text(
              'Connect to the Pignify Requests API to search YouTube Music and '
              'send tracks to your Navidrome library.',
              textAlign: TextAlign.center,
              style: YtmText.listSubtitle.copyWith(color: secondary),
            ),
            const SizedBox(height: YtmSpacing.xl),
            FilledButton.icon(
              onPressed: _showConfigSheet,
              style: FilledButton.styleFrom(
                backgroundColor: YtmColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: YtmSpacing.xl,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: YtmRadii.pillRadius,
                ),
              ),
              icon: const Icon(CupertinoIcons.settings, size: 18),
              label: const Text('Configure'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    final fieldColor =
        isDark ? YtmColors.surfaceHigh : YtmColors.lightSurface;
    final foreground =
        isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      textInputAction: TextInputAction.search,
      onChanged: _onQueryChanged,
      onSubmitted: _runSearch,
      style: YtmText.body.copyWith(color: foreground),
      decoration: InputDecoration(
        hintText: 'Search YouTube Music',
        hintStyle: YtmText.body.copyWith(
          color:
              isDark ? YtmColors.textTertiary : YtmColors.lightTextTertiary,
        ),
        prefixIcon: Icon(
          CupertinoIcons.search,
          size: 20,
          color:
              isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _runSearch('');
                },
              ),
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: YtmRadii.pillRadius,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final secondary =
        isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;

    if (_searching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(YtmSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: YtmColors.danger,
                size: 32,
              ),
              const SizedBox(height: YtmSpacing.sm),
              Text(
                _searchError!,
                textAlign: TextAlign.center,
                style: YtmText.listSubtitle.copyWith(color: secondary),
              ),
              const SizedBox(height: YtmSpacing.md),
              TextButton(
                onPressed: () => _runSearch(_query),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(YtmSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.music_note_2,
                size: 36,
                color: secondary,
              ),
              const SizedBox(height: YtmSpacing.sm),
              Text(
                'Find a song and add it to your library.',
                textAlign: TextAlign.center,
                style: YtmText.listSubtitle.copyWith(color: secondary),
              ),
              const SizedBox(height: YtmSpacing.xxs),
              Text(
                'Downloads run one at a time, max 10 per day.',
                textAlign: TextAlign.center,
                style: YtmText.caption.copyWith(color: secondary),
              ),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No results for “$_query”.',
          style: YtmText.listSubtitle.copyWith(color: secondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: YtmSpacing.xxl),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultTile(context, result, isDark);
      },
    );
  }

  Widget _buildResultTile(
    BuildContext context,
    RequestSearchResult result,
    bool isDark,
  ) {
    final foreground =
        isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    final secondary =
        isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;
    final activeJob = _activeJobFor(result.videoId);
    final inLibrary =
        result.inLibrary || _completedVideoIds.contains(result.videoId);
    final starting = _starting.contains(result.videoId);
    final failed = activeJob?.status == RequestJobStatus.error;

    final subtitleParts = <String>[
      result.artist,
      if (result.album.isNotEmpty) result.album,
      if (result.durationLabel.isNotEmpty) result.durationLabel,
    ];
    if (activeJob != null && !activeJob.isTerminal) {
      subtitleParts.add(_jobLabel(activeJob));
    }

    Widget trailing;
    if (inLibrary) {
      trailing = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 22,
            color: Color(0xFF3DD68C),
          ),
          const SizedBox(height: 2),
          Text(
            'In library',
            style: YtmText.caption.copyWith(
              color: secondary,
              fontSize: 9,
            ),
          ),
        ],
      );
    } else if (starting) {
      trailing = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (activeJob != null && !activeJob.isTerminal) {
      trailing = SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          value: activeJob.progress,
          color: YtmColors.brand,
        ),
      );
    } else {
      trailing = IconButton(
        tooltip: failed ? 'Retry download' : 'Download',
        onPressed: () {
          if (failed) {
            setState(() {
              _jobs.remove(activeJob.id);
              _videoByJob.remove(activeJob.id);
              _jobByVideo.remove(result.videoId);
              _notifiedDone.remove(activeJob.id);
            });
          }
          _requestDownload(result);
        },
        icon: Icon(
          failed
              ? CupertinoIcons.arrow_clockwise_circle
              : CupertinoIcons.arrow_down_circle,
          size: 26,
          color: failed ? YtmColors.danger : foreground,
        ),
      );
    }

    return InkWell(
      onTap: inLibrary ? null : () => _requestDownload(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: YtmSpacing.md,
          vertical: YtmSpacing.xs,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: YtmRadii.cardRadius,
              child: SizedBox(
                width: 56,
                height: 56,
                child: result.thumbnail == null
                    ? Container(
                        color: isDark
                            ? YtmColors.surfaceHigh
                            : YtmColors.lightSurfaceHigh,
                        child: Icon(
                          CupertinoIcons.music_note,
                          color: secondary,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: result.thumbnail!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: isDark
                              ? YtmColors.surfaceHigh
                              : YtmColors.lightSurfaceHigh,
                          child: Icon(
                            CupertinoIcons.music_note,
                            color: secondary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: YtmSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    result.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: YtmText.listTitle.copyWith(color: foreground),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: YtmText.listSubtitle.copyWith(color: secondary),
                  ),
                  if (activeJob != null && !activeJob.isTerminal)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: YtmRadii.pillRadius,
                        child: LinearProgressIndicator(
                          value: activeJob.progress,
                          minHeight: 2,
                          backgroundColor: isDark
                              ? YtmColors.surfaceHigh
                              : YtmColors.lightSurfaceHigh,
                          color: YtmColors.brand,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: YtmSpacing.sm),
            trailing,
          ],
        ),
      ),
    );
  }
}
