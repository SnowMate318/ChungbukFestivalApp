class WebCameraContext {
  const WebCameraContext({
    this.isWeb = false,
    this.isSecureContext = false,
    this.hasMediaDevices = false,
    this.isInIframe = false,
    this.isInAppBrowser = false,
    this.scheme = '',
    this.host = '',
    this.userAgent = '',
  });

  final bool isWeb;
  final bool isSecureContext;
  final bool hasMediaDevices;
  final bool isInIframe;
  final bool isInAppBrowser;
  final String scheme;
  final String host;
  final String userAgent;
}
