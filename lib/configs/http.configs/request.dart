part of "http.config.dart";

class Request{

  static final Config _config = Config();

  static Future<Response> post(String suffix, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    String? accessToken,
    bool hasToken = true,
  }) async{
    final HttpClient client = HttpClient();
    String url;
    if(suffix.startsWith("http")) {
      url = suffix;
    } else {
      url = "${_config.HOST_NAME}$suffix";
      accessToken ??= await _config.GET_TOKEN(TokenType.accessToken);
      if(params != null && params.isNotEmpty) {
        final StringBuffer sb = StringBuffer();
        for(int index = 0; index < params.length; index++) {
          final String key = params.keys.map((e) => e).toList()[index];
          final dynamic value = params[key];
          if(index == 0) {
            sb.write("?");
          } else if(index < params.length) {
            sb.write("&");
          }
          sb.write(key);
          sb.write("=");
          sb.write(value);
        }
        url += sb.toString();
      }
    }
    final Uri uri = Uri.parse(url);
    try {
      final HttpClientRequest req = await client.postUrl(uri);
      final String encodeBody = jsonEncode(body);
      final Uint8List encodeBytes = Uint8List.fromList(utf8.encode(encodeBody));
      req.headers.contentType = ContentType("application", "json", charset: "UTF-8");
      req.headers.set(HttpHeaders.acceptHeader, "*/*");
      req.headers.set(HttpHeaders.acceptEncodingHeader, "gzip, deflate, br");
      req.headers.set(HttpHeaders.connectionHeader, "keep-alive");
      req.headers.set("x-api-key", _config.API_KEY);
      if(accessToken != null && hasToken) req.headers.set(HttpHeaders.authorizationHeader, "Bearer $accessToken");
      req.contentLength = encodeBytes.length;
      if(headers != null) {
        for (String key in headers.keys) {
          final String? value = headers[key];
          if (value != null) req.headers.set(key, value);
        }
      }
      req.add(encodeBytes);
      log("🐶🐶🐶🐶🐶Request Info🐶🐶🐶🐶🐶\nurl: $url\nbody: $encodeBody\nheaders: ${req.headers}");
      final HttpClientResponse res = await req.close();
      switch(res.statusCode) {
        case 403:
          final String? at = await _reissueToken();
          if(at != null) {
            return post(suffix, headers: headers, body: body, params: params, hasToken: hasToken, accessToken: at);
          }
      }
      return Response.fromHttp(res);
    } on ArgumentError catch(e) {
      if(e.message.toString().contains("No host specified in URI")) {
        return Response(statusCode: 404, message: "존재하지 않는 URI 주소입니다.", error: e.message);
      }
    } on SocketException catch(e) {
      const String message = "";
      log("message", error: e.message, type: LogType.error);
      return Response(statusCode: null, message: message, error: e.message);
    }
    return Response(statusCode: null, message: "알 수 없는 오류가 발생했습니다.");
  }

  static Future<String?> _reissueToken() async{
    const TokenType at = TokenType.accessToken;
    const TokenType rt = TokenType.refreshToken;
    final Response res = await Request.post("/include/refreshtoken_login.php", body: {
      "RefreshToken": await _config.GET_TOKEN(rt),
      "FcmToken": await FirebaseMessaging.instance.getToken()
    });
    final String? accessToken = res.data[at.name];
    switch(res.statusCode) {
      case 200:
        await _config.SET_TOKEN(at, res.data[at.name]);
        await _config.SET_TOKEN(rt, res.data[rt.name]);
    }
    return accessToken;
  }
}