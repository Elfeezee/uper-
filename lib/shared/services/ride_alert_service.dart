import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service responsible for ringing the phone and alerting the driver
/// when an incoming ride request is received.
class RideAlertService {
  static final RideAlertService _instance = RideAlertService._internal();
  factory RideAlertService() => _instance;
  RideAlertService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isRinging = false;
  bool _isInitialized = false;

  bool get isRinging => _isRinging;

  /// Initializes the local notification plugin and prepares audio player.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(initSettings);

      // Create high-importance notification channel for incoming requests
      const androidChannel = AndroidNotificationChannel(
        'ride_requests_channel',
        'Incoming Ride Requests',
        description: 'Urgent alerts for drivers when a passenger requests a ride',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        await androidPlugin.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      dev.log('Error initializing notifications: $e');
    }
  }

  /// Starts ringing the phone continuously until stopped.
  Future<void> startRingtone({
    required String passengerName,
    required String route,
    required String price,
  }) async {
    if (_isRinging) return;
    _isRinging = true;

    try {
      debugPrint('[RideAlert] Playing ringtone: sounds/ride_ringtone.wav');
      // 1. Play ringing sound in a continuous loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/ride_ringtone.wav'));
      debugPrint('[RideAlert] Audio player started successfully');
    } catch (e, stack) {
      debugPrint('[RideAlert] Error playing ringtone: $e\n$stack');
    }

    try {
      // 2. Trigger high-priority heads-up notification
      const androidDetails = AndroidNotificationDetails(
        'ride_requests_channel',
        'Incoming Ride Requests',
        channelDescription:
            'Urgent alerts for drivers when a passenger requests a ride',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        ticker: 'New ride request!',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        999,
        '🚖 New Ride Request from $passengerName',
        '$route • $price',
        notificationDetails,
      );
    } catch (e) {
      dev.log('Error displaying notification: $e');
    }
  }

  /// Stops ringing and clears the incoming request alert notification.
  Future<void> stopRingtone() async {
    _isRinging = false;
    try {
      await _audioPlayer.stop();
    } catch (e) {
      dev.log('Error stopping audio: $e');
    }

    try {
      await _notificationsPlugin.cancel(999);
    } catch (e) {
      dev.log('Error cancelling notification: $e');
    }
  }
}
