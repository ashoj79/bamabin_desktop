import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/window_chrome.dart';
import 'package:bamabin_desktop/core/widgets/stroke_text.dart';
import 'package:bamabin_desktop/data/local/database/model/watch_data.dart';
import 'package:bamabin_desktop/data/local/database/model/watched_episode.dart';
import 'package:bamabin_desktop/data/local/database/model/watched_movie.dart';
import 'package:bamabin_desktop/data/local/database/model/watching_episode.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/screen/player/bloc/player_bloc.dart';
import 'package:bamabin_desktop/screen/player/player_args.dart';
import 'package:bamabin_desktop/screen/player/widgets/player_dialogs.dart';
import 'package:bamabin_desktop/screen/player/widgets/player_seasons_dialog.dart';
import 'package:bamabin_desktop/screen/player/widgets/player_settings_panel.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

export 'player_args.dart';

String _formatPlayerDuration(Duration d) {
  if (d.inMilliseconds < 0) return '00:00';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) {
    return '$h:${m.padLeft(2, '0')}:$s';
  }
  return '$m:$s';
}

String _getClearTitle(String title) {
  var t = title.trim();
  t = t.replaceAll(RegExp(r'[اآبپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی]'), '').trim();
  return t;
}

const _trackLabelSpecialNames = [
  'Gapfilm',
  'Alphamedia',
  'Alpha Media',
  'Soren',
  'Qualima',
  'Namava',
  'Filimo',
  'Fimnet',
  'Avaje',
  'Glory',
  'Moasese',
  'Filmnet',
  'IRIB',
  'Dubbed',
];

String _languageCodeToPersianName(String code) {
  switch (code) {
    case 'fa':
    case 'per':
      return 'فارسی';
    case 'und':
      return 'زبان اصلی';
    case 'en':
    case 'mul':
      return 'انگلیسی';
    case 'ar':
    case 'ara':
      return 'عربی';
    case 'ko':
    case 'kor':
      return 'کره‌ای';
    case 'ja':
    case 'jpn':
      return 'ژاپنی';
    case 'es':
    case 'spa':
      return 'اسپانیایی';
    case 'fr':
    case 'fre':
      return 'فرانسوی';
    case 'de':
    case 'ger':
      return 'آلمانی';
    case 'nl':
    case 'dut':
      return 'هلندی';
    case 'tr':
    case 'tur':
      return 'ترکی';
    case 'ta':
    case 'tam':
      return 'تمیل';
    case 'ru':
    case 'rus':
      return 'روسی';
    default:
      return '';
  }
}

String _trackDisplayName(String? title, String? language, String id) {
  final trimmed = title?.trim();
  final lbl = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;

  if (lbl != null && lbl.contains('زیرنویس افزوده')) {
    return lbl;
  }

  if (lbl != null) {
    final lower = lbl.toLowerCase();
    for (final n in _trackLabelSpecialNames) {
      if (lower.contains(n.toLowerCase())) {
        return '$lbl - فارسی';
      }
    }
  }

  final lngName = _languageCodeToPersianName((language ?? '').toLowerCase());

  if (lbl != null) {
    return '$lbl - $lngName';
  }
  if (lngName.isNotEmpty) {
    return lngName;
  }
  return id;
}

Color _getSubTextColor(int index) {
  switch (index) {
    case 1:
      return const Color(0xFFFFEB3B);
    case 2:
      return const Color(0xFF2196F3);
    default:
      return Colors.white;
  }
}

Color _getSubBgColor(int index) {
  switch (index) {
    case 1:
      return Colors.black.withValues(alpha: 0.5);
    case 2:
      return Colors.transparent;
    default:
      return Colors.black;
  }
}

String _getSubFont(int index) {
  switch (index) {
    case 1:
      return 'vazir';
    case 2:
      return 'dana';
    default:
      return 'iransans';
  }
}

/// Renders currently active subtitle lines with an outlined [StrokeText].
class _PlayerSubtitleLayer extends StatefulWidget {
  const _PlayerSubtitleLayer({
    required this.player,
    required this.style,
    required this.padding,
  });

  final Player player;
  final TextStyle style;
  final EdgeInsets padding;

  @override
  State<_PlayerSubtitleLayer> createState() => _PlayerSubtitleLayerState();
}

class _PlayerSubtitleLayerState extends State<_PlayerSubtitleLayer> {
  static const double _kTextScaleRefWidth = 1920;
  static const double _kTextScaleRefHeight = 1080;

  late List<String> _lines = widget.player.state.subtitle;
  StreamSubscription<List<String>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.player.stream.subtitle.listen((value) {
      if (mounted) setState(() => _lines = value);
    });
  }

  @override
  void dispose() {
    final s = _subscription;
    _subscription = null;
    if (s != null) unawaited(s.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nr = constraints.maxWidth * constraints.maxHeight;
        const dr = _kTextScaleRefWidth * _kTextScaleRefHeight;
        final textScaleFactor = math.sqrt((nr / dr).clamp(0.0, 1.0));
        final text = [
          for (final line in _lines)
            if (line.trim().isNotEmpty) line.trim(),
        ].join('\n');
        if (text.isEmpty) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            alignment: Alignment.bottomCenter,
            child: StrokeText(
              text: text,
              strokeWidth: 2,
              style: widget.style,
              textAlign: TextAlign.center,
              textScaler: TextScaler.linear(textScaleFactor),
            ),
          ),
        );
      },
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.args});

  final PlayerArgs args;

  // Figma tokens (node 35:2052)
  static const _bg = Color(0xFF0C0C14);
  static const _gradientEdge = Color(0xFF131321);
  static const _iconBtnBg = Color(0x17FFFFFF); // white 9%
  static const _iconBtnBorder = Color(0x0FFFFFFF); // white 6%
  static const _mutedText = Color(0xB3FFFFFF); // white 70%
  static const _track = Color(0x33FFFFFF); // white 20%
  static const _volumeFill = Color(0xBFFFFFFF); // white 75%
  static const _badgeBg = Color(0xFFEC4E42);
  static const _badgeText = Color(0xFFFFE3DE);
  /// Space occupied by the bottom control bar (progress + buttons + padding).
  static const _controlsSubtitleLift = 120.0;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late Player _player;
  late VideoController _controller;
  late MovieType _type;

  int _seasonIndex = -1,
      _episodeIndex = -1,
      _qualityIndex = -1,
      _subTextColorCurrent = 0,
      _subBgColorCurrent = 0,
      _subFontCurrent = 0,
      _videoSpeedCurrent = 1;

  double _subSize = 30, _subMargin = 69;

  String _currentQualityCode = '', _aspectRatioName = '', _subFont = '';
  String _newTime = '';
  bool _showController = true, _showSettings = false, _isLocked = false;
  bool _isWindowFullScreen = false;
  BoxFit _aspectRatio = BoxFit.cover;
  static const double _maxVolume = 100;
  double _volume = 100, _videoSpeed = 1.0;

  Color _subTextColor = Colors.white, _subBgColor = Colors.transparent;

  Timer? _hideControllerTimer, _hideAspectRatioTimer, _updateNewTimeTimer, _saveWatchingEpisodeTimer;

  List<AudioTrack> _audioTracks = [];
  List<SubtitleTrack> _subtitleTracks = [];

  final GlobalKey _speedButtonKey = GlobalKey();
  final GlobalKey _subtitleButtonKey = GlobalKey();
  final GlobalKey _audioButtonKey = GlobalKey();
  final GlobalKey _qualityButtonKey = GlobalKey();

  final List<WatchedEpisode> _watchedEpisodes = [];
  WatchingEpisode? _watchingEpisode;
  WatchData? _watchData;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;

  Duration _position = Duration.zero, _duration = Duration.zero;
  bool _playing = false, _buffering = false, _isLoaded = false;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<PlayerBloc>(context).add(PlayerGetSubDefaultsEvent());
    _seasonIndex = widget.args.season;
    _episodeIndex = widget.args.episode;
    _type = widget.args.type;
    _player = Player();
    _controller = VideoController(_player);
    unawaited(_player.open(Media(getPlayLink()), play: true));
    unawaited(_tryResumePlayback());
    unawaited(_loadWatchedEpisodes());

    _player.stream.tracks.listen((t) {
      if (!mounted) return;
      _setDefaultTracks(t.audio, t.subtitle);
      setState(() {
        _audioTracks = t.audio;
        _subtitleTracks = t.subtitle;
        _isLoaded = true;
      });
    });
    _player.stream.volume.listen((v) {
      if (!mounted) return;
      setState(() => _volume = v.clamp(0, _maxVolume).toDouble());
    });
    _playingSub = _player.stream.playing.listen((v) {
      if (!mounted) return;
      setState(() => _playing = v);
      if (v) {
        _hideController();
      } else {
        _hideControllerTimer?.cancel();
      }
    });
    _positionSub = _player.stream.position.listen((d) {
      if (mounted) setState(() => _position = d);
    });
    _durationSub = _player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _bufferingSub = _player.stream.buffering.listen((b) {
      if (mounted) setState(() => _buffering = b);
    });

    _saveWatchingEpisode();
    _hideController();
  }

  @override
  void dispose() {
    unawaited(_exitFullScreenIfNeeded());
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_playingSub?.cancel());
    unawaited(_bufferingSub?.cancel());
    _hideControllerTimer?.cancel();
    _hideAspectRatioTimer?.cancel();
    _updateNewTimeTimer?.cancel();
    _saveWatchingEpisodeTimer?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _exitFullScreenIfNeeded() async {
    if (!_isWindowFullScreen) return;
    windowNativeFullscreen.value = false;
    await defaultExitNativeFullscreen();
    _isWindowFullScreen = false;
  }

  Future<void> _toggleFullScreen() async {
    final next = !_isWindowFullScreen;
    windowNativeFullscreen.value = next;
    if (next) {
      await defaultEnterNativeFullscreen();
    } else {
      await defaultExitNativeFullscreen();
    }
    if (mounted) setState(() => _isWindowFullScreen = next);
  }

  void setShowController(bool value) {
    if (_showController == value) return;
    setState(() => _showController = value);
    if (value) {
      _hideController();
    } else {
      _hideControllerTimer?.cancel();
    }
    if (_showSettings) {
      setShowSettings(false);
    }
  }

  /// Shows chrome on pointer activity and restarts the auto-hide timer.
  void _onPointerActivity() {
    if (_isLocked) return;
    if (!_showController) {
      setState(() => _showController = true);
    }
    _hideController();
  }

  void _hideController() {
    _hideControllerTimer?.cancel();
    _hideControllerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _player.state.playing && !_showSettings) {
        setState(() => _showController = false);
      }
    });
  }

  void setShowSettings(bool value) {
    if (_showSettings == value) return;
    setState(() => _showSettings = value);
  }

  void _saveWatchingEpisode() {
    _saveWatchingEpisodeTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) {
      if (!mounted) return;
      if (widget.args.isLocalPlayback) return;

      final position = _player.state.position.inMilliseconds;
      final duration = _player.state.duration.inMilliseconds;
      final isEnded =
          position >= duration * 0.8 && duration > Duration.zero.inMilliseconds;

      if (!isEnded) unawaited(_saveWatchData());

      if (isEnded) {
        unawaited(_saveWatchedEpisode());
        BlocProvider.of<PlayerBloc>(
          context,
        ).add(PlayerDeleteWatchDataEvent(id: widget.args.data.id));
        timer.cancel();
        return;
      }

      if (!widget.args.data.isSeries) return;

      final watchingEpisode = WatchingEpisode(
        id: widget.args.data.id,
        season: widget.args.data.isSeries ? _seasonIndex : -1,
        episode: _episodeIndex,
        type: _type.name,
        time: _player.state.position.inSeconds,
        duration: _player.state.duration.inSeconds,
        pk: _watchingEpisode?.pk,
      );
      BlocProvider.of<PlayerBloc>(context).add(
        PlayerSaveWatchingEpisodeEvent(
          watchingEpisode: watchingEpisode,
          isNew: _watchingEpisode == null,
        ),
      );
    });
  }

  Future<void> _loadWatchedEpisodes() async {
    if (widget.args.isLocalPlayback || !widget.args.data.isSeries) return;
    final list = await locator<VideoRepository>().getWatchedEpisodes(
      widget.args.data.id,
    );
    if (!mounted) return;
    _watchedEpisodes
      ..clear()
      ..addAll(list);
  }

  Future<void> _tryResumePlayback() async {
    if (widget.args.isLocalPlayback) return;
    final season = widget.args.data.isSeries ? _seasonIndex : -1;
    final videoRepository = locator<VideoRepository>();

    final data = await videoRepository.getWatchData(
      widget.args.data.id,
      season,
      _episodeIndex,
    );
    _watchData = data;

    await videoRepository.saveWatchedMovie(
      WatchedMovie(
        id: widget.args.data.id,
        time: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    if (!mounted || data == null || data.time <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      unawaited(_player.pause());
      final shouldResume = await PlayerResumeAlert.show(context);
      if (!mounted) return;

      if (shouldResume) {
        await _player.seek(Duration(milliseconds: data.time));
      } else {
        await videoRepository.saveWatchData(
          WatchData(
            id: widget.args.data.id,
            type: _type.name,
            quality: data.quality,
            qualityCode: data.qualityCode,
            time: 0,
            duration: data.duration,
            season: season,
            episode: _episodeIndex,
            audioTrack: data.audioTrack,
            subtitleTrack: data.subtitleTrack,
            pk: data.pk,
          ),
        );
        _watchData = null;
      }
      await _player.play();
    });
  }

  Future<void> _saveWatchedEpisode() async {
    if (!widget.args.data.isSeries) return;

    final alreadySaved = _watchedEpisodes.any(
      (e) => e.season == _seasonIndex && e.episode == _episodeIndex,
    );
    if (alreadySaved) return;

    final videoRepository = locator<VideoRepository>();
    final watchedEpisode = WatchedEpisode(
      id: widget.args.data.id,
      season: _seasonIndex,
      episode: _episodeIndex,
    );

    await videoRepository.saveWatchedEpisode(watchedEpisode);
    _watchedEpisodes.add(watchedEpisode);

    final currentWatching =
        _watchingEpisode ??
        await videoRepository.getWatchingEpisode(
          widget.args.data.id,
          _seasonIndex,
          _episodeIndex,
        );
    if (currentWatching != null) {
      await videoRepository.deleteWatchingEpisode(currentWatching);
      if (_watchingEpisode?.season == currentWatching.season &&
          _watchingEpisode?.episode == currentWatching.episode) {
        _watchingEpisode = null;
      }
    }
  }

  int _currentAudioTrackIndex() {
    final tracks = _usableAudioTracks();
    final currentId = _player.state.track.audio.id;
    if (currentId == 'auto') {
      return tracks.indexWhere((e) => e.isDefault == true);
    }
    return tracks.indexWhere((e) => e.id == currentId);
  }

  int _currentSubtitleTrackIndex() {
    final tracks = _usableSubtitleTracks();
    final currentId = _player.state.track.subtitle.id;
    if (currentId == 'auto') {
      return tracks.indexWhere((e) => e.isDefault == true);
    }
    return tracks.indexWhere((e) => e.id == currentId);
  }

  Future<void> _saveWatchData() async {
    if (widget.args.isLocalPlayback) return;
    final positionMs = _player.state.position.inMilliseconds;
    final durationMs = _player.state.duration.inMilliseconds;
    final isEnd = durationMs > 0 && positionMs >= (durationMs * 0.8);

    if (isEnd || positionMs <= 0) return;

    final data = widget.args.data.isSeries
        ? widget.args.data.seasons![_seasonIndex].items.getEpisodeInfo(
            _type,
            _episodeIndex,
            _qualityIndex,
          )
        : widget.args.data.movieDownloadBox!.getItemInfo(_type, _qualityIndex);

    final season = widget.args.data.isSeries ? _seasonIndex : -1;
    final videoRepository = locator<VideoRepository>();

    await videoRepository.saveWatchData(
      WatchData(
        id: widget.args.data.id,
        type: _type.name,
        quality: data[0],
        qualityCode: data[1],
        time: positionMs,
        duration: durationMs,
        season: season,
        episode: _episodeIndex,
        audioTrack: _currentAudioTrackIndex(),
        subtitleTrack: _currentSubtitleTrackIndex(),
        pk: _watchData?.pk,
      ),
    );

    _watchData = await videoRepository.getWatchData(
      widget.args.data.id,
      season,
      _episodeIndex,
    );
  }

  String getPlayLink() {
    final localPath = widget.args.localFilePath;
    if (localPath != null && localPath.isNotEmpty) {
      return Uri.file(localPath).toString();
    }

    var url = '';

    if (widget.args.data.isSeries) {
      final items = widget.args.data.seasons![_seasonIndex].items;

      if (_qualityIndex == -1) {
        _qualityIndex = items.getDefaultQualityIndex(_type, _episodeIndex);
      }

      final info = items.getEpisodeInfo(_type, _episodeIndex, _qualityIndex);
      _currentQualityCode = info[1];
      url = items.getLink(_type, _episodeIndex, qualityIndex: _qualityIndex);
    } else {
      final box = widget.args.data.movieDownloadBox!;

      if (_qualityIndex == -1) {
        _qualityIndex = _seasonIndex;
      }
      final info = box.getItemInfo(_type, _qualityIndex);
      _currentQualityCode = info[1];
      url = box.getLink(_type, _qualityIndex);
    }

    return url;
  }

  String get _displayTitle => _getClearTitle(widget.args.data.title);

  String get _displaySubtitle {
    final data = widget.args.data;
    if (!data.isSeries) return '';
    final seasons = data.seasons;
    if (seasons == null || seasons.isEmpty) return '';
    final si = _seasonIndex.clamp(0, seasons.length - 1);
    final season = seasons[si];
    final episodeName = season.items.getName(_type, _episodeIndex);
    return 'فصل ${season.name} - قسمت $episodeName';
  }

  void _updateNewTime(Duration position) {
    setState(() {
      _newTime = _formatPlayerDuration(position);
    });
    _updateNewTimeTimer?.cancel();
    _updateNewTimeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _newTime = '');
      }
    });
  }

  Future<void> _seekToSeconds(double seconds) {
    final d = _player.state.duration;
    final ms = (seconds * 1000).round();
    final clamped = ms.clamp(0, d.inMilliseconds);
    final newPosition = Duration(milliseconds: clamped);
    _updateNewTime(newPosition);
    return _player.seek(newPosition);
  }

  Future<void> _forward10() async {
    final p = _player.state.position + const Duration(seconds: 10);
    final d = _player.state.duration;
    _updateNewTime(p > d ? d : p);
    await _player.seek(p > d ? d : p);
  }

  Future<void> _replay10() async {
    final p = _player.state.position - const Duration(seconds: 10);
    _updateNewTime(p < Duration.zero ? Duration.zero : p);
    await _player.seek(p < Duration.zero ? Duration.zero : p);
  }

  void _cycleAspectRatio() {
    _hideAspectRatioTimer?.cancel();
    setState(() {
      if (_aspectRatio == BoxFit.cover) {
        _aspectRatio = BoxFit.contain;
      } else if (_aspectRatio == BoxFit.contain) {
        _aspectRatio = BoxFit.fill;
      } else if (_aspectRatio == BoxFit.fill) {
        _aspectRatio = BoxFit.fitHeight;
      } else if (_aspectRatio == BoxFit.fitHeight) {
        _aspectRatio = BoxFit.fitWidth;
      } else if (_aspectRatio == BoxFit.fitWidth) {
        _aspectRatio = BoxFit.cover;
      }
      _aspectRatioName = _getAspectRatioName();
    });
    _hideAspectRatioTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _aspectRatioName = '');
      }
    });
  }

  String _getAspectRatioName() {
    switch (_aspectRatio) {
      case BoxFit.cover:
        return 'بهترین تناسب';
      case BoxFit.contain:
        return 'برش';
      case BoxFit.fill:
        return 'کشیده';
      case BoxFit.fitHeight:
        return 'ارتفاع تمام‌صفحه';
      case BoxFit.fitWidth:
        return 'عرض تمام‌صفحه';
      default:
        return 'بهترین تناسب';
    }
  }

  List<String> _qualityLabels() {
    if (widget.args.isLocalPlayback) return const [];
    if (widget.args.data.isSeries) {
      return widget.args.data.seasons![_seasonIndex].items
          .getAllQualities(_type, _episodeIndex);
    }
    return widget.args.data.movieDownloadBox!.getQualities(_type);
  }

  static const _dialogSpeedLabels = [
    '0.5x',
    '0.75x',
    '1.0x',
    '1.25x',
    '1.5x',
    '2.0x',
    '3.0x',
  ];
  static const _dialogSpeedValues = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0];
  static const _prefsSpeedValues = [0.75, 1.0, 1.25, 1.5, 2.0];

  Future<void> _showSpeedDialog() async {
    var current = _dialogSpeedValues.indexWhere(
      (v) => (v - _videoSpeed).abs() < 0.01,
    );
    if (current < 0) current = 2;

    final wasPlaying = _player.state.playing;
    if (wasPlaying) {
      unawaited(_player.pause());
    }
    final selected = await PlayerAnchorMenu.show(
      context,
      anchorKey: _speedButtonKey,
      items: _dialogSpeedLabels,
      currentItem: current,
    );
    if (wasPlaying) {
      unawaited(_player.play());
    }
    if (!mounted || selected == null) return;
    if (selected < 0 || selected >= _dialogSpeedValues.length) return;

    final rate = _dialogSpeedValues[selected];
    final prefsIndex = _prefsSpeedValues.indexWhere(
      (v) => (v - rate).abs() < 0.01,
    );
    if (prefsIndex >= 0) {
      BlocProvider.of<PlayerBloc>(
        context,
      ).add(PlayerSetSubDefaultsEvent(videoSpeed: prefsIndex));
      _videoSpeedCurrent = prefsIndex;
    }
    unawaited(_player.setRate(rate));
    setState(() => _videoSpeed = rate);
  }

  Future<void> _showQualitiesDialog() async {
    final labels = _qualityLabels();
    if (labels.isEmpty) return;
    final current = _qualityIndex.clamp(0, labels.length - 1);
    final wasPlaying = _player.state.playing;
    if (wasPlaying) {
      unawaited(_player.pause());
    }
    final selected = await PlayerAnchorMenu.show(
      context,
      anchorKey: _qualityButtonKey,
      items: labels,
      currentItem: current,
    );
    if (selected == null) {
      if (wasPlaying) {
        unawaited(_player.play());
      }
      return;
    }
    await _onQualityChosen(selected, wasPlaying);
  }

  Future<void> _onQualityChosen(int selectedIndex, bool wasPlaying) async {
    if (selectedIndex == _qualityIndex) {
      if (wasPlaying) {
        unawaited(_player.play());
      }
      return;
    }
    final pos = _player.state.position;
    setState(() {
      _qualityIndex = selectedIndex;
      if (widget.args.data.isSeries) {
        final items = widget.args.data.seasons![_seasonIndex].items;
        final info = items.getEpisodeInfo(_type, _episodeIndex, _qualityIndex);
        _currentQualityCode = info[1];
      } else {
        final info =
            widget.args.data.movieDownloadBox!.getItemInfo(_type, _qualityIndex);
        _currentQualityCode = info[1];
      }
    });
    final url = widget.args.data.isSeries
        ? widget.args.data.seasons![_seasonIndex].items.getLink(
            _type,
            _episodeIndex,
            qualityIndex: _qualityIndex,
          )
        : widget.args.data.movieDownloadBox!.getLink(_type, _qualityIndex);
    await _player.open(Media(url), play: true);
    await _player.seek(pos);
  }

  List<AudioTrack> _usableAudioTracks() {
    return _audioTracks.where((e) => e.id != 'auto' && e.id != 'no').toList();
  }

  List<SubtitleTrack> _usableSubtitleTracks() {
    return _subtitleTracks
        .where((e) => e.id != 'auto' && e.id != 'no')
        .toList();
  }

  Future<void> _showAudioDialog() async {
    final tracks = _usableAudioTracks();
    if (tracks.length <= 1) return;
    final labels = tracks
        .map((t) => _trackDisplayName(t.title, t.language, t.id))
        .toList();
    final currentTrack = _player.state.track.audio;
    var currentIndex = tracks.indexWhere((t) => t.id == currentTrack.id);
    if (currentIndex < 0) currentIndex = 0;
    final isPlaying = _player.state.playing;
    if (isPlaying) {
      unawaited(_player.pause());
    }
    final selected = await PlayerAnchorMenu.show(
      context,
      anchorKey: _audioButtonKey,
      items: labels,
      currentItem: currentIndex,
      itemGap: 6,
    );
    if (isPlaying) {
      unawaited(_player.play());
    }
    if (!mounted || selected == null) return;
    if (selected < 0 || selected >= tracks.length) return;
    if (tracks[selected].id == _player.state.track.audio.id) return;
    unawaited(_player.setAudioTrack(tracks[selected]));
  }

  Future<void> _showSubtitleDialog() async {
    final tracks = _usableSubtitleTracks();
    final labels = tracks
        .map((t) => _trackDisplayName(t.title, t.language, t.id))
        .toList();
    final currentTrack = _player.state.track.subtitle;
    var currentIndex = -1;
    if (currentTrack.id == 'auto') {
      currentIndex = tracks.indexWhere((t) => t.isDefault == true);
    } else if (currentTrack.id != 'no') {
      currentIndex = tracks.indexWhere((t) => t.id == currentTrack.id);
    }
    if (currentIndex < 0 && labels.isNotEmpty) currentIndex = 0;

    final isPlaying = _player.state.playing;
    if (isPlaying) {
      unawaited(_player.pause());
    }

    final selected = await PlayerAnchorMenu.show(
      context,
      anchorKey: _subtitleButtonKey,
      items: labels,
      currentItem: currentIndex,
      footerLabel: 'بارگذاری از دستگاه',
      itemGap: 6,
    );
    if (isPlaying) {
      unawaited(_player.play());
    }
    if (!mounted || selected == null) return;
    if (selected == -1) {
      await _loadSubtitleFromDevice();
      return;
    }
    if (selected < 0 || selected >= tracks.length) return;
    if (tracks[selected].id == _player.state.track.subtitle.id) return;
    unawaited(_player.setSubtitleTrack(tracks[selected]));
  }

  Future<void> _loadSubtitleFromDevice() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['srt', 'vtt', 'ass', 'ssa', 'sub'],
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty || !mounted) return;
    await _player.setSubtitleTrack(
      SubtitleTrack.uri(
        Uri.file(path).toString(),
        title: result!.files.single.name,
      ),
    );
  }

  void _setDefaultTracks(
    List<AudioTrack> audioTracks,
    List<SubtitleTrack> subtitleTracks,
  ) {
    final hasDefaultSubtitleTrack = subtitleTracks.any(
      (e) => e.isDefault == true,
    );
    final hasDefaultAudioTrack = audioTracks.any((e) => e.isDefault == true);

    final hasPersianSubtitleTrack = subtitleTracks.any(
      (e) => e.language == 'fa' || e.language == 'per',
    );
    final hasPersianAudioTrack = audioTracks.any(
      (e) => e.language == 'fa' || e.language == 'per',
    );

    if (hasDefaultSubtitleTrack) {
      unawaited(
        _player.setSubtitleTrack(
          subtitleTracks.firstWhere((e) => e.isDefault == true),
        ),
      );
    } else if (hasPersianSubtitleTrack) {
      unawaited(
        _player.setSubtitleTrack(
          subtitleTracks.firstWhere(
            (e) => e.language == 'fa' || e.language == 'per',
          ),
        ),
      );
    }

    if (hasDefaultAudioTrack) {
      unawaited(
        _player.setAudioTrack(
          audioTracks.firstWhere((e) => e.isDefault == true),
        ),
      );
    } else if (hasPersianAudioTrack) {
      unawaited(
        _player.setAudioTrack(
          audioTracks.firstWhere(
            (e) => e.language == 'fa' || e.language == 'per',
          ),
        ),
      );
    }
  }

  Future<void> _showSeasonsDialog() async {
    if (!widget.args.data.isSeries) return;
    final seasons = widget.args.data.seasons;
    if (seasons == null || seasons.isEmpty) return;

    await PlayerSeasonsAlert.show(
      context,
      seasons: seasons,
      currentSeason: _seasonIndex,
      currentEpisode: _episodeIndex,
      currentType: _type,
      onEpisodeSelected: (seasonIndex, episodeIndex, type) {
        _onEpisodeSelected(seasonIndex, episodeIndex, type);
      },
    );
  }

  void _onEpisodeSelected(int seasonIndex, int episodeIndex, MovieType type) {
    if (seasonIndex == _seasonIndex && episodeIndex == _episodeIndex) return;
    _seasonIndex = seasonIndex;
    _episodeIndex = episodeIndex;
    _type = type;
    _qualityIndex = -1;
    unawaited(_player.stop());
    unawaited(_player.open(Media(getPlayLink()), play: true));
    setState(() {});
  }

  void _skipToNextEpisode() {
    final data = widget.args.data;
    if (!data.isSeries) return;
    final seasons = data.seasons;
    if (seasons == null || seasons.isEmpty) return;
    final count = seasons[_seasonIndex].items.getEpisodesCount();
    if (_episodeIndex + 1 < count) {
      _onEpisodeSelected(_seasonIndex, _episodeIndex + 1, _type);
    } else if (_seasonIndex + 1 < seasons.length) {
      _onEpisodeSelected(_seasonIndex + 1, 0, _type);
    }
  }

  void _updateSubTitleViewConfiguration({
    int? subTextColor,
    int? subBgColor,
    int? subFont,
    int? subSize,
    int? subMargin,
  }) {
    setState(() {
      _subTextColorCurrent = subTextColor ?? _subTextColorCurrent;
      _subBgColorCurrent = subBgColor ?? _subBgColorCurrent;
      _subTextColor = _getSubTextColor(_subTextColorCurrent);
      _subBgColor = _getSubBgColor(_subBgColorCurrent);
      _subFontCurrent = subFont ?? _subFontCurrent;
      _subFont = _getSubFont(_subFontCurrent);
      _subSize = subSize?.toDouble() ?? _subSize;
      _subMargin = subMargin?.toDouble() ?? _subMargin;
    });
    BlocProvider.of<PlayerBloc>(context).add(
      PlayerSetSubDefaultsEvent(
        subTextColor: subTextColor ?? _subTextColorCurrent,
        subBgColor: subBgColor ?? _subBgColorCurrent,
        subFont: subFont ?? _subFontCurrent,
        subSize: subSize ?? _subSize.toInt(),
        subMargin: subMargin ?? _subMargin.toInt(),
        videoSpeed: _videoSpeedCurrent,
      ),
    );
  }

  void _resetSubtitleSettings() {
    BlocProvider.of<PlayerBloc>(context).add(
      PlayerSetSubDefaultsEvent(
        subTextColor: 0,
        subBgColor: 2,
        subFont: 1,
        subSize: 30,
        subMargin: 69,
        videoSpeed: 1,
      ),
    );

    setState(() {
      _subTextColorCurrent = 0;
      _subBgColorCurrent = 2;
      _subTextColor = _getSubTextColor(_subTextColorCurrent);
      _subBgColor = _getSubBgColor(_subBgColorCurrent);
      _subFontCurrent = 1;
      _subFont = _getSubFont(_subFontCurrent);
      _subSize = 30;
      _subMargin = 69;
      _videoSpeedCurrent = 1;
      _videoSpeed = 1;
    });
    unawaited(_player.setRate(1));
  }

  void _changeLockState() {
    setState(() {
      _isLocked = !_isLocked;
      _showController = false;
      setShowSettings(false);
    });
  }

  void _setVolume(double value) {
    final clamped = value.clamp(0, _maxVolume).toDouble();
    unawaited(_player.setVolume(clamped));
    setState(() => _volume = clamped);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {},
      child: BlocListener<PlayerBloc, PlayerBlocState>(
        listener: (context, state) {
          if (state is PlayerGetSubDefaultsSuccess) {
            _updateSubTitleViewConfiguration(
              subTextColor: state.subTextColor,
              subBgColor: state.subBgColor,
              subFont: state.subFont,
              subSize: state.subSize,
              subMargin: state.subMargin,
            );
            setState(() {
              _videoSpeedCurrent = state.videoSpeed;
              const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
              _videoSpeed = speeds[state.videoSpeed.clamp(0, speeds.length - 1)];
            });
            unawaited(_player.setRate(_videoSpeed));
          }
          if (state is PlayerSaveWatchingEpisodeSuccess) {
            _watchingEpisode = state.watchingEpisode;
          }
        },
        child: Scaffold(
          backgroundColor: PlayerScreen._bg,
          body: Directionality(
            // Player chrome matches Figma LTR layout (scrubber / transport).
            textDirection: TextDirection.ltr,
            child: MouseRegion(
              opaque: false,
              onHover: (_) => _onPointerActivity(),
              onEnter: (_) => _onPointerActivity(),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerHover: (_) => _onPointerActivity(),
                onPointerMove: (_) => _onPointerActivity(),
                child: Stack(
              fit: StackFit.expand,
              children: [
                Video(
                  controller: _controller,
                  fit: _aspectRatio,
                  controls: NoVideoControls,
                  subtitleViewConfiguration: const SubtitleViewConfiguration(
                    visible: false,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: _PlayerSubtitleLayer(
                      player: _player,
                      style: TextStyle(
                        color: _subTextColor,
                        fontSize: _subSize * 1.4,
                        fontFamily: _subFont,
                        backgroundColor: _subBgColor,
                      ),
                      padding: EdgeInsets.only(
                        bottom: _subMargin +
                            (_showController && !_isLocked
                                ? PlayerScreen._controlsSubtitleLift
                                : 0),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isLocked) return;
                    if (_showSettings) {
                      setShowSettings(false);
                      return;
                    }
                    unawaited(_player.playOrPause());
                    _onPointerActivity();
                  },
                ),
                if (!_isLocked)
                  IgnorePointer(
                    ignoring: !_showController,
                    child: AnimatedOpacity(
                      opacity: _showController ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              PlayerScreen._gradientEdge,
                              const Color(0x00131321),
                              const Color(0x00131321),
                              PlayerScreen._gradientEdge,
                            ],
                            stops: const [0.0, 0.15, 0.85, 1.0],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {},
                                child: _PlayerHeader(
                                  title: _displayTitle,
                                  subtitle: _displaySubtitle,
                                  onBack: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    }
                                  },
                                ),
                              ),
                              if (_aspectRatioName.isNotEmpty ||
                                  _newTime.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _aspectRatioName.isNotEmpty
                                      ? _aspectRatioName
                                      : _newTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    unawaited(_player.playOrPause());
                                    _onPointerActivity();
                                  },
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {},
                                child: _PlayerBottomBar(
                                  position: _position,
                                  duration: _duration,
                                  playing: _playing,
                                  isLoaded: _isLoaded,
                                  isSeries: widget.args.data.isSeries,
                                  showQuality: !widget.args.isLocalPlayback,
                                  qualityLabel: _currentQualityCode,
                                  volume: _volume,
                                  audioTrackCount: _usableAudioTracks().length,
                                  speedButtonKey: _speedButtonKey,
                                  subtitleButtonKey: _subtitleButtonKey,
                                  audioButtonKey: _audioButtonKey,
                                  qualityButtonKey: _qualityButtonKey,
                                  onSeek: (ratio) => unawaited(
                                    _seekToSeconds(
                                      ratio * _duration.inSeconds,
                                    ),
                                  ),
                                  onVolumeChanged: (ratio) =>
                                      _setVolume(ratio * _maxVolume),
                                  onLock: _changeLockState,
                                  onAspectRatio: _cycleAspectRatio,
                                  isFullScreen: _isWindowFullScreen,
                                  onFullscreen: () =>
                                      unawaited(_toggleFullScreen()),
                                  onSkipNext: _skipToNextEpisode,
                                  onReplay10: () => unawaited(_replay10()),
                                  onPlayPause: () =>
                                      unawaited(_player.playOrPause()),
                                  onForward10: () => unawaited(_forward10()),
                                  onShowSeasons: () =>
                                      unawaited(_showSeasonsDialog()),
                                  onShowSpeed: () =>
                                      unawaited(_showSpeedDialog()),
                                  onShowSubtitles: () =>
                                      unawaited(_showSubtitleDialog()),
                                  onShowAudio: () =>
                                      unawaited(_showAudioDialog()),
                                  onShowQuality: () =>
                                      unawaited(_showQualitiesDialog()),
                                  onShowSettings: () =>
                                      setShowSettings(!_showSettings),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  right: _showSettings ? 0 : -433,
                  width: 433,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: PlayerSettingsPanel(
                      subTextColor: _subTextColorCurrent,
                      subBgColor: _subBgColorCurrent,
                      subFont: _subFontCurrent,
                      subSize: _subSize.toInt(),
                      subMargin: _subMargin.toInt(),
                      videoSpeed: _videoSpeedCurrent,
                      onSubTextColorSelected: (i) =>
                          _updateSubTitleViewConfiguration(subTextColor: i),
                      onSubBgColorSelected: (i) =>
                          _updateSubTitleViewConfiguration(subBgColor: i),
                      onSubFontSelected: (i) =>
                          _updateSubTitleViewConfiguration(subFont: i),
                      onSubSizeChanged: (i) =>
                          _updateSubTitleViewConfiguration(subSize: i),
                      onSubMarginChanged: (i) =>
                          _updateSubTitleViewConfiguration(subMargin: i),
                      onVideoSpeedSelected: (i, speed) {
                        BlocProvider.of<PlayerBloc>(
                          context,
                        ).add(PlayerSetSubDefaultsEvent(videoSpeed: i));
                        unawaited(_player.setRate(speed));
                        setState(() {
                          _videoSpeedCurrent = i;
                          _videoSpeed = speed;
                        });
                      },
                      onReset: _resetSubtitleSettings,
                      onClose: () => setShowSettings(false),
                    ),
                  ),
                ),
                if (_isLocked)
                  Positioned(
                    top: 24,
                    left: 24,
                    child: _PlayerIconButton(
                      asset: 'assets/img/player/player_lock.svg',
                      tooltip: 'باز کردن قفل',
                      tooltipBelow: true,
                      onTap: _changeLockState,
                    ),
                  ),
                if (_buffering)
                  const Center(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _PlayerIconButton(
            asset: 'assets/img/player/player_back.svg',
            tooltip: 'بازگشت',
            tooltipBelow: true,
            onTap: onBack,
          ),
          const Spacer(),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 20 / 18,
                    letterSpacing: -0.16,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: PlayerScreen._mutedText,
                      height: 18 / 15,
                      letterSpacing: -0.16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBottomBar extends StatelessWidget {
  const _PlayerBottomBar({
    required this.position,
    required this.duration,
    required this.playing,
    required this.isLoaded,
    required this.isSeries,
    this.showQuality = true,
    required this.qualityLabel,
    required this.volume,
    required this.audioTrackCount,
    required this.speedButtonKey,
    required this.subtitleButtonKey,
    required this.audioButtonKey,
    required this.qualityButtonKey,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onLock,
    required this.onAspectRatio,
    required this.isFullScreen,
    required this.onFullscreen,
    required this.onSkipNext,
    required this.onReplay10,
    required this.onPlayPause,
    required this.onForward10,
    required this.onShowSeasons,
    required this.onShowSpeed,
    required this.onShowSubtitles,
    required this.onShowAudio,
    required this.onShowQuality,
    required this.onShowSettings,
  });

  final Duration position;
  final Duration duration;
  final bool playing;
  final bool isLoaded;
  final bool isSeries;
  final bool showQuality;
  final String qualityLabel;
  final double volume;
  final int audioTrackCount;
  final GlobalKey speedButtonKey;
  final GlobalKey subtitleButtonKey;
  final GlobalKey audioButtonKey;
  final GlobalKey qualityButtonKey;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onLock;
  final VoidCallback onAspectRatio;
  final bool isFullScreen;
  final VoidCallback onFullscreen;
  final VoidCallback onSkipNext;
  final VoidCallback onReplay10;
  final VoidCallback onPlayPause;
  final VoidCallback onForward10;
  final VoidCallback onShowSeasons;
  final VoidCallback onShowSpeed;
  final VoidCallback onShowSubtitles;
  final VoidCallback onShowAudio;
  final VoidCallback onShowQuality;
  final VoidCallback onShowSettings;

  @override
  Widget build(BuildContext context) {
    final durSec = duration.inMilliseconds / 1000.0;
    final posSec = position.inMilliseconds / 1000.0;
    final progress = durSec > 0 ? (posSec / durSec).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _TimeLabel(_formatPlayerDuration(position)),
              const SizedBox(width: 10),
              Expanded(
                child: _ProgressBar(
                  progress: progress,
                  duration: duration,
                  onSeek: onSeek,
                ),
              ),
              const SizedBox(width: 10),
              _TimeLabel(_formatPlayerDuration(duration)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _PlayerIconButton(
                      asset: 'assets/img/player/player_lock.svg',
                      tooltip: 'قفل',
                      onTap: onLock,
                    ),
                    const SizedBox(width: 8),
                    _PlayerIconButton(
                      asset: 'assets/img/player/player_aspect_ratio.svg',
                      tooltip: 'حالت تصویر',
                      onTap: onAspectRatio,
                    ),
                    const SizedBox(width: 8),
                    _PlayerIconButton(
                      asset: isFullScreen
                          ? 'assets/img/player/player_quit_full_screen.svg'
                          : 'assets/img/player/player_fullscreen.svg',
                      tooltip:
                          isFullScreen ? 'خروج از تمام‌صفحه' : 'تمام‌صفحه',
                      onTap: onFullscreen,
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        _PlayerIconButton(
                          asset: 'assets/img/player/player_volume.svg',
                          tooltip: 'صدا',
                          onTap: () => onVolumeChanged(volume <= 0 ? 1 : 0),
                        ),
                        const SizedBox(width: 4),
                        _VolumeSlider(
                          progress: volume / 100,
                          onChanged: onVolumeChanged,
                        ),
                      ],
                    ),
                    if (isSeries) ...[
                      const SizedBox(width: 8),
                      _PlayerIconButton(
                        asset: 'assets/img/player/player_skip_next.svg',
                        tooltip: 'قسمت بعد',
                        onTap: onSkipNext,
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  _PlayerIconButton(
                    asset: 'assets/img/player/player_rewind_10.svg',
                    iconSize: 25,
                    tooltip: '۱۰ ثانیه عقب',
                    onTap: onReplay10,
                  ),
                  const SizedBox(width: 8),
                  _PlayerIconButton(
                    asset: playing
                        ? 'assets/img/player/player_pause.svg'
                        : 'assets/img/player/player_play.svg',
                    tooltip: playing ? 'توقف' : 'پخش',
                    onTap: onPlayPause,
                  ),
                  const SizedBox(width: 8),
                  _PlayerIconButton(
                    asset: 'assets/img/player/player_forward_10.svg',
                    iconWidth: 26,
                    iconHeight: 25,
                    tooltip: '۱۰ ثانیه جلو',
                    onTap: onForward10,
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isSeries) ...[
                      _PlayerIconButton(
                        asset: 'assets/img/player/player_layers.svg',
                        tooltip: 'قسمت ها',
                        onTap: onShowSeasons,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _PlayerIconButton(
                      key: speedButtonKey,
                      asset: 'assets/img/player/player_speed.svg',
                      tooltip: 'سرعت',
                      onTap: onShowSpeed,
                    ),
                    if (isLoaded) ...[
                      const SizedBox(width: 8),
                      _PlayerIconButton(
                        key: subtitleButtonKey,
                        asset: 'assets/img/player/player_subtitles.svg',
                        tooltip: 'زیرنویس',
                        onTap: onShowSubtitles,
                      ),
                      if (audioTrackCount > 1) ...[
                        const SizedBox(width: 8),
                        _PlayerIconButton(
                          key: audioButtonKey,
                          asset: 'assets/img/player/player_mic.svg',
                          tooltip: 'دوبله',
                          onTap: onShowAudio,
                        ),
                      ],
                    ],
                    if (showQuality) ...[
                      const SizedBox(width: 8),
                      _QualityButton(
                        buttonKey: qualityButtonKey,
                        qualityLabel: qualityLabel,
                        onTap: onShowQuality,
                      ),
                    ],
                    const SizedBox(width: 8),
                    _PlayerIconButton(
                      asset: 'assets/img/player/player_settings.svg',
                      tooltip: 'تنظیمات',
                      onTap: onShowSettings,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QualityButton extends StatelessWidget {
  const _QualityButton({
    required this.buttonKey,
    required this.qualityLabel,
    required this.onTap,
  });

  final GlobalKey buttonKey;
  final String qualityLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: buttonKey,
      width: _PlayerIconButton.size,
      height: _PlayerIconButton.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _PlayerIconButton(
            asset: 'assets/img/player/player_quality.svg',
            tooltip: 'کیفیت',
            onTap: onTap,
          ),
          if (qualityLabel.isNotEmpty)
            Positioned(
              top: -14,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: PlayerScreen._badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    qualityLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PlayerScreen._badgeText,
                      height: 14 / 11,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerTooltip extends StatefulWidget {
  const _PlayerTooltip({
    required this.message,
    required this.child,
    this.preferBelow = false,
  });

  final String message;
  final Widget child;
  final bool preferBelow;

  @override
  State<_PlayerTooltip> createState() => _PlayerTooltipState();
}

class _PlayerTooltipState extends State<_PlayerTooltip> {
  bool _visible = false;

  void _setVisible(bool value) {
    if (_visible == value) return;
    setState(() => _visible = value);
  }

  @override
  Widget build(BuildContext context) {
    final bubble = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: blueColor.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'dana',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 14 / 12,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
    final arrow = CustomPaint(
      size: const Size(12, 5.5),
      painter: _TooltipArrowPainter(
        color: blueColor.withValues(alpha: 0.24),
        pointUp: widget.preferBelow,
      ),
    );

    return MouseRegion(
      onEnter: (_) => _setVisible(true),
      onExit: (_) => _setVisible(false),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_visible)
            Positioned(
              top: widget.preferBelow ? 56 : null,
              bottom: widget.preferBelow ? null : 56,
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.preferBelow
                      ? [arrow, bubble]
                      : [bubble, arrow],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  _TooltipArrowPainter({required this.color, this.pointUp = false});

  final Color color;
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = pointUp
        ? (Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..close())
        : (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0)
          ..close());
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TooltipArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointUp != pointUp;
}

class _PlayerIconButton extends StatelessWidget {
  const _PlayerIconButton({
    super.key,
    required this.asset,
    required this.onTap,
    this.tooltip,
    this.tooltipBelow = false,
    this.iconSize = 26,
    this.iconWidth,
    this.iconHeight,
  });

  static const double size = 48;

  final String asset;
  final VoidCallback onTap;
  final String? tooltip;
  final bool tooltipBelow;
  final double iconSize;
  final double? iconWidth;
  final double? iconHeight;

  @override
  Widget build(BuildContext context) {
    final w = iconWidth ?? iconSize;
    final h = iconHeight ?? iconSize;
    final button = Material(
      color: PlayerScreen._iconBtnBg,
      shape: const CircleBorder(
        side: BorderSide(color: PlayerScreen._iconBtnBorder),
      ),
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SvgPicture.asset(asset, width: w, height: h),
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return button;
    return _PlayerTooltip(
      message: tooltip!,
      preferBelow: tooltipBelow,
      child: button,
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 16 / 15,
        letterSpacing: -0.12,
      ),
    );
  }
}

/// Progress scrubber for desktop player controls.
/// [onSeek] receives the seek ratio in the 0..1 range.
class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.progress,
    required this.duration,
    required this.onSeek,
  });

  final double progress;
  final Duration duration;
  final ValueChanged<double> onSeek;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  static const double _thumb = 16;

  bool _hovering = false;
  double _hoverX = 0;
  double _barWidth = 0;

  double get _hoverRatio {
    if (_barWidth <= 0) return 0;
    return (_hoverX / _barWidth).clamp(0.0, 1.0);
  }

  String get _hoverTimeLabel {
    final totalMs = widget.duration.inMilliseconds;
    if (totalMs <= 0) return _formatPlayerDuration(Duration.zero);
    final ms = (totalMs * _hoverRatio).round();
    return _formatPlayerDuration(Duration(milliseconds: ms));
  }

  void _updateHover(Offset local, double width) {
    setState(() {
      _hovering = true;
      _hoverX = local.dx.clamp(0.0, width);
      _barWidth = width;
    });
  }

  void _clearHover() {
    if (!_hovering) return;
    setState(() => _hovering = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          void handleSeek(Offset local) {
            final ratio = (local.dx / width).clamp(0.0, 1.0);
            widget.onSeek(ratio);
          }

          final clamped = widget.progress.clamp(0.0, 1.0);
          final thumbCenter = width * clamped;
          final trackHeight = _hovering ? 5.0 : 2.0;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (e) => _updateHover(e.localPosition, width),
            onHover: (e) => _updateHover(e.localPosition, width),
            onExit: (_) => _clearHover(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => handleSeek(d.localPosition),
              onHorizontalDragUpdate: (d) {
                _updateHover(d.localPosition, width);
                handleSeek(d.localPosition);
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: PlayerScreen._track,
                        borderRadius: BorderRadius.circular(trackHeight),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    width: thumbCenter.clamp(0.0, width),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: blueColor,
                        borderRadius: BorderRadius.circular(trackHeight),
                      ),
                    ),
                  ),
                  if (_hovering)
                    Positioned(
                      left: (_hoverX - 0.75).clamp(0.0, width - 1.5),
                      top: 4,
                      bottom: 4,
                      child: Container(
                        width: 1.5,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  Positioned(
                    left: (thumbCenter - _thumb / 2).clamp(0.0, width - _thumb),
                    child: Container(
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        color: blueColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  if (_hovering && widget.duration > Duration.zero)
                    Positioned(
                      left: _hoverX,
                      bottom: 28,
                      child: IgnorePointer(
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: blueColor.withValues(alpha: 0.24),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _hoverTimeLabel,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'dana',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 14 / 12,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: const Size(12, 5.5),
                                painter: _TooltipArrowPainter(
                                  color: blueColor.withValues(alpha: 0.24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Volume slider for desktop player controls.
/// [onChanged] receives the volume ratio in the 0..1 range.
class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({required this.progress, required this.onChanged});

  final double progress;
  final ValueChanged<double> onChanged;

  static const double _width = 120;
  static const double _thumb = 12;
  static const double _pad = 8;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final thumbCenter = _pad + (_width - _pad * 2) * clamped;

    void handle(Offset local) {
      final ratio = ((local.dx - _pad) / (_width - _pad * 2)).clamp(0.0, 1.0);
      onChanged(ratio);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => handle(d.localPosition),
        onHorizontalDragUpdate: (d) => handle(d.localPosition),
        child: SizedBox(
          width: _width,
          height: 24,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: thumbCenter,
                right: _pad,
                child: Container(height: 1.5, color: PlayerScreen._track),
              ),
              Positioned(
                left: _pad,
                width: (thumbCenter - _pad).clamp(0.0, _width),
                child: Container(
                  height: 1.5,
                  color: PlayerScreen._volumeFill,
                ),
              ),
              Positioned(
                left: thumbCenter - _thumb / 2,
                child: Container(
                  width: _thumb,
                  height: _thumb,
                  decoration: const BoxDecoration(
                    color: PlayerScreen._volumeFill,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
