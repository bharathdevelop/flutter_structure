import 'package:shared_preferences/shared_preferences.dart';

const String usernameKey = 'my_user_name';
const String tokenKey = 'my_token';
const String fcmKey = 'fcm_token';
const String mobilekey = 'mobile';


class Sharepref {

Future saveLoginData({
  String? username,
  String? token,
  String? mobile,
  String? fcm
}) async {
  final prefs = await SharedPreferences.getInstance();

  if (username != null) {
    await prefs.setString(usernameKey, username);
  }

  if (token != null) {
    await prefs.setString(tokenKey, token);
  }

  if (mobile != null) {
    await prefs.setString(mobilekey, mobile);
  }
  if ( fcm!= null) {
    await prefs.setString(fcmKey, fcm);
  }
}

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(usernameKey);
  }

  Future<String?> getuserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }
  Future<String?> getmobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(mobilekey);
  }

  //  Future<void> saveFcmToken(String token) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(fcmKey, token);
  // }

  Future<String?> getFCMtoken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(fcmKey);
  }

  Future<void> saveMapFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('map_font_size', size);
  }

  Future<double> getMapFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('map_font_size') ?? 20.0;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(usernameKey);
    await prefs.remove(tokenKey);
    await prefs.remove(fcmKey);
    await prefs.remove(mobilekey);
    await prefs.remove('map_font_size');
  }

}


