import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../customs/custom.dart';
import '../utills/common.dart';
import '../utills/enums.dart';

class LockScreenController extends ChangeNotifier {

  static LockScreenController of(BuildContext context) => context.read<LockScreenController>();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _keyData = "LOCK_SCREEN";

  String _number = '';
  String get number => _number;
  set number(String n){
    _number = n;
    notifyListeners();
  }

  String _checkNumber = '';
  String get checkNumber => _checkNumber;
  set checkNumber(String n){
    _checkNumber = n;
    notifyListeners();
  }

  OverlayEntry? _entry;
  OverlayEntry? get entry => _entry;
  set entry(OverlayEntry? entry){
    _entry = entry;
    notifyListeners();
  }

  Future<void> showLockNumber(BuildContext context, LockScreenType type, {
    final String? text,
    final bool isCheck = false
  }) async{
    _cancelLockScreen(isCheck: isCheck);
    entry = OverlayEntry(builder: (context) => _buildLockScreen(context, type, text ?? "비밀번호 입력"));
    final OverlayState state = Overlay.of(context);
    if(entry != null) state.insert(entry!);
  }

  void _lockScreenHandler(BuildContext context, LockScreenType type){
    switch(type) {
      case LockScreenType.INSERT:
        _lockScreenInsert(context);
        break;
      case LockScreenType.UPDATE:
        _lockScreenUpdate(context);
        break;
      case LockScreenType.REMOVE:
        _lockScreenRemove();
        break;
      case LockScreenType.AUTH:
        _lockScreenAuth();
        break;
      case LockScreenType.CHECK:
        _lockScreenCheck();
    }
  }

  Future<String?> get lockScreenNumber {
    return SharedPreferences.getInstance().then((spf) {
      return spf.getString(_keyData);
    });
  }

  Future<void> _insertLockScreenNumber() async{
    SharedPreferences.getInstance().then((spf) {
      spf.setString(_keyData, number);
    });
  }

  void _removeLockScreenNumber() {
    SharedPreferences.getInstance().then((spf) {
      spf.remove(_keyData);
    });
  }

  void _lockScreenInsert(BuildContext context){
    showLockNumber(context, LockScreenType.CHECK, text: "비밀번호 확인", isCheck: true);
  }

  void _lockScreenUpdate(BuildContext context){
    lockScreenNumber.then((authNumber) {
      if(authNumber == null){
        _cancelLockScreen();
        showToast('비밀번호가 설정되어 있지 않습니다.');
      } else if(authNumber == number) {
        showLockNumber(context, LockScreenType.INSERT);
      } else {
        showToast('비밀번호가 일치하지 않습니다.');
        number = "";
      }
    });
  }

  void _lockScreenRemove(){
    lockScreenNumber.then((authNumber) {
      if(authNumber == null){
        _cancelLockScreen();
        showToast('비밀번호가 설정되어 있지 않습니다.');
      } else if(authNumber == number) {
        _removeLockScreenNumber();
        _cancelLockScreen();
        showToast('비밀번호가 삭제되었습니다.');
      } else {
        showToast('비밀번호가 일치하지 않습니다.');
        number = "";
      }
    });
  }

  void _lockScreenAuth() {
    lockScreenNumber.then((authNumber) {
      if(number == authNumber) {
        _cancelLockScreen();
      } else {
        number = '';
        showToast('비밀번호가 일치하지 않습니다.');
      }
    });
  }

  void _lockScreenCheck() {
    if(number == checkNumber) {
      showToast('비밀번호가 설정되었습니다.');
      _insertLockScreenNumber().whenComplete(() {
        _cancelLockScreen();
      });
    } else {
      showToast('비밀번호가 일치하지 않습니다.');
      checkNumber = "";
    }
  }

  void _localCheck(){
    _localAuth.isDeviceSupported().then((isSupported) {
      if(isSupported) {
        _localAuth.getAvailableBiometrics().then((types) {
          if(types.isNotEmpty) {
            _localAuth.authenticate(
                localizedReason: "잠금 화면",
                options: AuthenticationOptions()
            ).then((check) {
              if(check) {
                _cancelLockScreen();
              }
            });
          } else {
            showToast("사용 가능한 생체 인식기능이 없습니다.");
          }
        });
      } else {
        showToast("생체 인식을 지원하지 않는 기기입니다.");
      }
    });
  }

  void _cancelLockScreen({
    bool isCheck = false
  }){
    if(!isCheck) number = '';
    if(!isCheck) checkNumber = '';
    _entry?.remove();
    entry = null;
  }

  Widget _buildLockScreen(BuildContext context, LockScreenType type, final String text){
    return Consumer<LockScreenController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: Colors.grey,
            body: SafeArea(
              child: Container(
                padding: baseAllPadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(text, style: CustomTextStyle.classic(fontSize: 20)),
                    _buildInsertNumber(type),
                    ..._buildNumberButtons(context, type)
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildInsertNumber(LockScreenType type){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: EdgeInsets.all(20),
          height: 15,
          width: 15,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CustomColors.main),
              color: (type == LockScreenType.CHECK ? checkNumber.length : number.length) < index + 1 ? null : CustomColors.main
          ),
        );
      }),
    );
  }

  List<Widget> _buildNumberButtons(BuildContext context, LockScreenType type){
    return [
      Row(
        children: List.generate(3, (index) => _buildNumberButton(context, type, index + 1)),
      ),
      Row(
        children: List.generate(3, (index) => _buildNumberButton(context, type, index + 4)),
      ),
      Row(
        children: List.generate(3, (index) => _buildNumberButton(context, type, index + 7)),
      ),
      Row(
        children: [
          _buildTextButton('생체인식', _localCheck),
          _buildNumberButton(context, type, 0),
          _buildTextButton('취소', type == LockScreenType.AUTH ? () => exit(0) : _cancelLockScreen)
        ],
      )
    ];
  }

  Widget _buildNumberButton(BuildContext context, LockScreenType type, int n){
    return Expanded(
      child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: CustomColors.main)
          ),
          child: CupertinoButton(
              child: Text("$n", style: CustomTextStyle.classic(fontSize: 40)),
              onPressed: (){
                switch(type){
                  case LockScreenType.CHECK:
                    checkNumber += "$n";
                    if(checkNumber.length >= 4) {
                      _lockScreenHandler(context, type);
                    }
                    break;
                  default:
                    number += "$n";
                    if(number.length >= 4) {
                      _lockScreenHandler(context, type);
                    }
                }
              }
          )
      ),
    );
  }

  Widget _buildTextButton(final String text, final Function()? onTap){
    return Expanded(
      child: CupertinoButton(
        child: Text(text, style: CustomTextStyle.classic(color: Colors.black, fontSize: 18)),
        onPressed: onTap,
      ),
    );
  }
}