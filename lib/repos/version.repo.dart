import '../configs/config/config.dart';

class VersionRepo extends Config{

  static VersionRepo get instance => VersionRepo();

  // Future<Response> versionCheck({
  //   required final String version,
  //   required final int buildNumber,
  // }) async{
  //   final Map<String, dynamic> body = <String, dynamic>{
  //     "name": version.trim(),
  //     "build": buildNumber,
  //     "type": Platform.isAndroid ? 1 : 2
  //   };
  //   return Request.post('$BASE_API/app_version_check.php', body: body);
  // }
}