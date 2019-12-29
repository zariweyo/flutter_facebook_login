import 'dart:async';
import 'dart:js';

import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/src/web/entities/facebook_web_response.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class FacebookLoginPlugin {
  static MethodChannel channel;
  static FacebookLoginPlugin instance;
  static final String _ARG_PERMISSIONS = "permissions";
  static const String _METHOD_LOG_IN = "logIn";
  // static const String _METHOD_LOG_OUT = "logOut";
  // static const String _METHOD_GET_CURRENT_ACCESS_TOKEN = "getCurrentAccessToken";

  static void registerWith(Registrar registrar) {
    channel = MethodChannel(
        'com.roughike/flutter_facebook_login',
        const StandardMethodCodec(),
        registrar.messenger
    );

    instance = FacebookLoginPlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) {
    switch (call.method) {
      case _METHOD_LOG_IN:
        final List<dynamic> loginPermissions = call.arguments[_ARG_PERMISSIONS] as List;
        return _doLogIn(loginPermissions);
      default:
        var message ="The flutter_facebook_login plugin for web doesn't implement the method '${call.method}'";
        throw PlatformException(code: 'Unimplemented', details: message);
    }
  }

  Future<dynamic> _doLogIn(List<dynamic> permissions) {
    Completer completer = new Completer();
    var callback = (JsObject response) {
      String responseStatus = response['status'];
      switch (responseStatus) {
        case 'connected':
          FacebookWebResponse webResponse = FacebookWebResponse.fromJsObject(response);
          completer.complete(webResponse.toMap());
          break;
        case 'not_authorized': // TOOD: handle this status in the future.
        case 'unknown':
          completer.complete({"status": 'cancelledByUser'});
          break;
        default:
          completer.complete({"status": 'error'});
          break;
      }
    };

    // JS context from window browser
    var scope = { 'scope': permissions.join(',')};
    context['FB'].callMethod('login', [callback, scope]);
    return completer.future;
  }
}
