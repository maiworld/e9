import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:inain/configs/http.configs/http.config.dart';
import 'package:inain/controllers/location.controller.dart';
import 'package:inain/repos/member.repo.dart';
import 'package:inain/utills/enums.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../configs/config/config.dart';
import '../controllers/device.controller.dart';
import '../controllers/inapp-web.controller.dart';
import '../controllers/notification.controller.dart';
import '../controllers/overlay.controller.dart';
import 'package:http/http.dart' as http;

import '../utills/common.dart';

class WebViewPage extends StatefulWidget {

  static const String routeName = '/webViewPage';

  const WebViewPage({Key? key}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {

  late final DeviceController _deviceCtr = DeviceController.of(context);
  late final OverlayController _overlayCtr = OverlayController.of(context);
  late final InAppWebController _inAppWebCtr = InAppWebController.of(context);
  late final NotificationController _notificationCtr = NotificationController.of(context);
  late final LocationController _locationCtr = LocationController.of(context);

  Map<String, String> get _initialHeader => <String, String>{
    "fcm-token": NotificationController.of(context).fcmToken ?? '',
    "device-code": _deviceCtr.deviceCode ?? "",
    "device-uuid": _deviceCtr.deviceId ?? "",
    "device-type": _deviceCtr.deviceType ?? ""
  };

  final List<String> _allowFiles = <String>[
    ".pdf",
    ".hwp",
    ".docx",
    ".xlsx",
    ".hwpx",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: _buildBody(context)
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: InAppWebView(
        onDownloadStartRequest: _onDownloadStartRequest,
        androidShouldInterceptRequest: _androidShouldInterceptRequest,
        shouldInterceptAjaxRequest: _shouldInterceptAjaxRequest,
        shouldInterceptFetchRequest: _shouldInterceptFetchRequest,
        shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
        onLoadResource: _onLoadResource,
        initialUrlRequest: URLRequest(
            url: Uri.parse(Config.instance.HOST_NAME),
            headers: _initialHeader
        ),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
            useOnLoadResource: true,
            useShouldInterceptAjaxRequest: true,
            useShouldInterceptFetchRequest: true,
            useShouldOverrideUrlLoading: true,
            allowFileAccessFromFileURLs: true,
          ),
        ),
        onWebViewCreated: _onWebViewCreated,
        onLoadStart: _onLoadStart,
        onLoadStop: _onLoadStop,
      ),
    );
  }

  void _onDownloadStartRequest(InAppWebViewController ctr, DownloadStartRequest req) {
    debugPrint("${req.url}");
  }

  Future<WebResourceResponse> _androidShouldInterceptRequest(InAppWebViewController ctr, WebResourceRequest req) async{
    return WebResourceResponse();
  }

  void _onLoadResource(InAppWebViewController ctr, LoadedResource resource) {
  }

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(InAppWebViewController ctr, NavigationAction action) async{
    final String? url = action.request.url?.toString();
    if(url != null) {
      if(!url.startsWith(Config.instance.HOST_NAME) && !url.contains("youtube")){
        openURL(url);
        return NavigationActionPolicy.CANCEL;
      } else if(url.endsWith(".pdf") || url.endsWith(".hwp") || url.endsWith(".docx") || url.endsWith(".xlsx") || url.endsWith(".hwpx")){
        return _fileDownload(url);
      } else {
        return NavigationActionPolicy.ALLOW;
      }
    } else {
      return NavigationActionPolicy.CANCEL;
    }
  }

  Future<AjaxRequest?> _shouldInterceptAjaxRequest(InAppWebViewController ctr, AjaxRequest req) async{
    return req;
  }

  Future<FetchRequest?> _shouldInterceptFetchRequest(InAppWebViewController ctr, FetchRequest req) async{
    return req;
  }

  void _onWebViewCreated(InAppWebViewController ctr) {
    String javascriptCode = "";
    for(final MapEntry<String, dynamic> map in _initialHeader.entries) {
      javascriptCode += "sessionStorage.setItem('${map.key}', '${map.value}');\n";
    }
    ctr.addJavaScriptHandler(handlerName: "mobile", callback: _mobileJavascriptHandler);
    InAppWebController.of(context).webViewCtr = ctr;
    InAppWebController.of(context).webViewCtr.evaluateJavascript(source: javascriptCode);
  }

  void _onLoadStart(InAppWebViewController ctr, Uri? uri){
  }

  void _onLoadStop(InAppWebViewController ctr, Uri? uri) {
    if(!InAppWebController.of(context).firstLoad) {
      _overlayCtr.removeOverlay();
      _inAppWebCtr.firstLoad = true;
      _notificationCtr.firebasePushListener(context);
      _locationCtr.initialLocationSettings(_deviceCtr.deviceId ?? "");
    }
    _getCookies();
  }

  void _mobileJavascriptHandler(List<dynamic> obj) {
  }

  Future<NavigationActionPolicy> _fileDownload(String? url) async {
    if(url != null) {
      final Uri uri = Uri.parse(url);
      final http.Response res = await http.get(uri);
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = "${directory.path}/${url.split("/").last}";
      final File file = File(filePath);
      if(!(await File(filePath).exists())) await file.writeAsBytes(res.bodyBytes.buffer.asUint8List());
      OpenFilex.open(filePath);
      return NavigationActionPolicy.CANCEL;
    } else {
      return NavigationActionPolicy.CANCEL;
    }
  }

  Future<void> _getCookies() async{
    final String? refreshToken = await Config.instance.GET_TOKEN(TokenType.refreshToken);
    if(refreshToken == null) {
      final CookieManager cm = CookieManager.instance();
      final List<Cookie> cookies = await cm.getCookies(url: Uri.parse(Config.instance.HOST_NAME));
      log("COOKIES: $cookies");
      try {
        final Cookie cookie = cookies.singleWhere((c) => c.name == "ref_token");
        await Config.instance.SET_TOKEN(TokenType.refreshToken, (cookie.value.replaceAll("%24", "\$") as String).replaceAll("%2F", "/"));
        final Response res = await MemberRepo.instance.reissueToken(_notificationCtr.fcmToken);
        switch(res.statusCode){
          case 200:
        }
      } catch(e) {
      }
    }
  }
}