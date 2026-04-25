// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<bool> requestWebNotifPermission() async {
  final result = await html.Notification.requestPermission();
  return result == 'granted';
}

void showWebNotif(String title, {String? body}) {
  if (html.Notification.permission == 'granted') {
    html.Notification(title, body: body);
  }
}

bool get webNotifsGranted => html.Notification.permission == 'granted';
