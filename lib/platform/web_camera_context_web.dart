// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'web_camera_context_model.dart';

WebCameraContext getWebCameraContext() {
  final navigator = html.window.navigator;
  final userAgent = navigator.userAgent;
  final lowerUserAgent = userAgent.toLowerCase();

  var isInIframe = false;
  try {
    isInIframe = html.window.top != html.window;
  } catch (_) {
    isInIframe = true;
  }

  final protocol = html.window.location.protocol.replaceAll(':', '');
  final host = html.window.location.host;
  final isInAppBrowser =
      lowerUserAgent.contains('kakaotalk') ||
      lowerUserAgent.contains('fb_iab') ||
      lowerUserAgent.contains('fbav') ||
      lowerUserAgent.contains('instagram') ||
      lowerUserAgent.contains('line/') ||
      lowerUserAgent.contains('naver') ||
      lowerUserAgent.contains('wv');

  return WebCameraContext(
    isWeb: true,
    isSecureContext: html.window.isSecureContext ?? false,
    hasMediaDevices: navigator.mediaDevices != null,
    isInIframe: isInIframe,
    isInAppBrowser: isInAppBrowser,
    scheme: protocol,
    host: host,
    userAgent: userAgent,
  );
}
