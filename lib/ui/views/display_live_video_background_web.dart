// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

class DisplayLiveVideoBackground extends StatefulWidget {
  const DisplayLiveVideoBackground({
    super.key,
    required this.asset,
    required this.restartKey,
  });

  final String asset;
  final String restartKey;

  @override
  State<DisplayLiveVideoBackground> createState() =>
      _DisplayLiveVideoBackgroundState();
}

class _DisplayLiveVideoBackgroundState
    extends State<DisplayLiveVideoBackground> {
  static final Set<String> _registeredViewTypes = <String>{};

  late String _viewType;

  @override
  void initState() {
    super.initState();
    _registerVideoView();
  }

  @override
  void didUpdateWidget(DisplayLiveVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset ||
        oldWidget.restartKey != widget.restartKey) {
      _registerVideoView();
    }
  }

  void _registerVideoView() {
    _viewType =
        'display-live-video-${widget.asset.hashCode}-${widget.restartKey.hashCode}';
    if (_registeredViewTypes.contains(_viewType)) {
      return;
    }

    final src = _assetUrl(widget.asset);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = html.VideoElement()
        ..src = src
        ..autoplay = true
        ..loop = true
        ..muted = true
        ..controls = false
        ..preload = 'auto';

      video
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..setAttribute('aria-hidden', 'true');

      video.style
        ..width = '100%'
        ..height = '100%'
        ..objectFit = 'cover'
        ..display = 'block'
        ..pointerEvents = 'none';

      video.onCanPlay.listen((_) => video.play());
      video.onLoadedData.listen((_) => video.play());
      return video;
    });
    _registeredViewTypes.add(_viewType);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(key: ValueKey(_viewType), viewType: _viewType);
  }
}

String _assetUrl(String asset) {
  final encodedPath = asset.split('/').map(Uri.encodeComponent).join('/');
  final baseUri = html.document.baseUri ?? '${html.window.location.origin}/';
  return Uri.parse(baseUri).resolve('assets/$encodedPath').toString();
}
