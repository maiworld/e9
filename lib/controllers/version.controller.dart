import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class VersionController extends ChangeNotifier {

  static VersionController of(BuildContext context) => context.read<VersionController>();

  PackageInfo? _info;
  PackageInfo? get info => _info;
  set info(PackageInfo? info) {
    _info = info;
    notifyListeners();
  }

  bool _isCheck = false;
  bool get isCheck => _isCheck;
  set isCheck(bool isCheck) {
    _isCheck = isCheck;
    notifyListeners();
  }

  Future<void> getVersion() {
    return PackageInfo.fromPlatform().then((info) {
      this.info = info;
    });
  }
}