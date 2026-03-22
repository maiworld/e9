part of "http.config.dart";

class Response<T> extends Equatable{

  final int? statusCode;

  final Map<String, dynamic>? body;

  final String? message;

  final String? error;

  final T? data;

  const Response({
    required this.statusCode,
    this.body,
    this.message,
    this.error,
    this.data,
  });

  static Future<Response> fromHttp(HttpClientResponse res, {bool isLogged = true}) async{

    final String streamResponse = await res.transform(utf8.decoder).join();
    final Map<String, dynamic>? body = streamResponse.isEmpty ? null : json.decode(streamResponse);

    final int statusCode = res.statusCode;

    if(isLogged) {
      log("🐶🐶🐶🐶🐶Response Info🐶🐶🐶🐶🐶\nstatusCode: $statusCode\nbody: ${body}\nmessage: ${body?["message"]}\nerror: ${body?["error"]}\ndata: ${body?["data"]}");
    }

    return Response(
      statusCode: statusCode,
      body: body,
      message: body?["message"],
      error: body?["error"],
      data: body?["data"],
    );
  }

  @override
  List<Object?> get props => [statusCode, body, message, data, error];
}