import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:viam_sdk/viam_sdk.dart' hide Credentials;

class AuthService {
  // TODO add client id from Viam auth provider
  static const _authClientID = '';
  static const _authDomain = 'auth.viam.com';

  // for fusionAuth audience is the client ID
  static const _audience = _authClientID;

  // ensure these URLs are configured in the auth provider
  static const _authLoginRedirectUri =
      'com.example.loginExample://login-callback';
  static const _authLogoutRedirectUri =
      'com.example.loginExample://logout-callback';

  static const _authIssuer = 'https://$_authDomain';

  static const appAuth = FlutterAppAuth();
  static const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ));

  static const _refreshTokenKey = 'refresh_token';

  static String? _userAccessToken;
  static String? _userRefreshToken;
  static DateTime? _accessTokenExpiration;
  static String? _idToken;
  static ViamUserProfile? _userProfile;

  static Future<bool> init() async {
    try {
      _userRefreshToken = await secureStorage.read(key: _refreshTokenKey);

      if (_userRefreshToken == null) {
        return false;
      }

      try {
        if (!_validTokens()) await _refreshTokens;
        return true;
      } catch (e, s) {
        print('error on Refresh Token: $e - stack: $s');
        // logOut() possibly
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<void> loginAction() async {
    final result = await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _authClientID,
        _authLoginRedirectUri,
        issuer: _authIssuer,
        scopes: <String>['openid', 'profile', 'email', 'offline_access'],
        preferEphemeralSession: true,
        additionalParameters: {
          'audience': _audience,
        },
      ),
    );

    await _setLocalVariables(result!);
  }

  static Future<void> logoutAction() async {
    appAuth.endSession(
      EndSessionRequest(
        issuer: _authIssuer,
        preferEphemeralSession: true,
        additionalParameters: {
          'client_id': _authClientID,
          'post_logout_redirect_uri': _authLogoutRedirectUri,
        },
      ),
    );

    _clearLocalVariables();
  }

  static Future<String> get accessToken async {
    if (!_validTokens()) await _refreshTokens;

    return _userAccessToken!;
  }

  static Future<ViamUserProfile> get currentUser async {
    if (!_validTokens()) await _refreshTokens;
    return _userProfile!;
  }

  static Future<Viam> get authenticatedViam async {
    return Viam.withAccessToken(await accessToken);
  }

  static Future<bool> get isLoggedIn async {
    return _userAccessToken == null ? false : true;
  }

  static bool _validTokens() {
    if (_userRefreshToken == null ||
        _userAccessToken == null ||
        _idToken == null ||
        _userProfile == null ||
        _accessTokenExpiration == null) {
      return false;
    }

    // check if the token is 1 minute or less away frome expiring
    if (_accessTokenExpiration!
        .isBefore(DateTime.now()..subtract(const Duration(minutes: 1)))) {
      return false;
    }

    return true;
  }

  static Future<TokenResponse> get _refreshTokens async {
    try {
      final result = await appAuth.token(
        TokenRequest(
          _authClientID,
          _authLoginRedirectUri,
          refreshToken: _userRefreshToken,
          additionalParameters: {'audience': _audience},
          issuer: _authIssuer,
          scopes: ['openid', 'profile', 'email', 'offline_access'],
        ),
      );

      await _setLocalVariables(result!);
      return result;
    } catch (e) {
      throw Exception('Exception refreshing token: $e');
    }
  }

  static _setLocalVariables(TokenResponse response) async {
    _userRefreshToken = response.refreshToken;
    _userAccessToken = response.accessToken;
    _idToken = response.idToken;
    _userProfile = ViamUserProfile.fromIdToken(_idToken!);
    _accessTokenExpiration = response.accessTokenExpirationDateTime;

    await secureStorage.write(key: _refreshTokenKey, value: _userRefreshToken);
  }

  static _clearLocalVariables() async {
    _userRefreshToken = null;
    await secureStorage.delete(key: _refreshTokenKey);
    _userAccessToken = null;
    _idToken = null;
    _userProfile = null;
    _accessTokenExpiration = null;
  }
}

class ViamUserProfile {
  ViamUserProfile(this.name, this.email, this.pictureUrl, this.sub);

  String? name;
  String? email;
  String? pictureUrl;
  String? sub;

  factory ViamUserProfile.fromIdToken(String idToken) {
    final parts = idToken.split(r'.');
    assert(parts.length == 3);

    final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final givenName = json['given_name'] ?? '';
    final familyName = json['family_name'] ?? '';
    final name = '$givenName $familyName';
    final email = json['email'];
    final pictureUrl = json['picture'];
    final sub = json['sub'];
    return ViamUserProfile(name, email, pictureUrl, sub);
  }
}

Future<void> showLogoutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.blueAccent),
            ),
            onPressed: () {
              AuthService.logoutAction();
              // the login screen is the first route - pop until that.
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          TextButton(
            child: const Text(
              'No',
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      );
    },
  );
}
