import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

import '../constant/enums.dart';

class MqttService {
  MqttClient client = _buildClient();

  final StreamController<String> _messageStream = StreamController.broadcast();
  final StreamController<MqttConnectionStatus> _connectionController =
      StreamController.broadcast();

  Stream<MqttConnectionStatus> get connectionStatusStream =>
      _connectionController.stream;

  Stream<String> get messages => _messageStream.stream;

  bool _isConnecting = false;
  bool _allowReconnect = true;
  bool _isDisposed = false;
  Timer? _reconnectTimer;
  final Set<String> _subscribedImeis = <String>{};
  StreamSubscription? _updatesSubscription;

  static MqttClient _buildClient() {
    if (kIsWeb) {
      return MqttClient.withPort(
        "gcam-mqtt.rtsiot.com",
        "gCam${Uuid().v1()}",
        1883,
      );
    }

    return MqttServerClient.withPort(
      "gcam-mqtt.rtsiot.com",
      "gCam${Uuid().v1()}",
      1883,
    );
  }

  MqttService() {
    _configureClient();
    _debug("Service initialized");
  }

  String get _connState => client.connectionStatus?.state.name ?? "null_status";

  void _debug(String message) {

  }

  void _configureClient() {
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;

    final connMessage = MqttConnectMessage()
        .authenticateAs('realiot', 'realmqtt@123')
        .startClean();
        // .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;
  }

  void dispose() {
    _debug("dispose() called");
    _isDisposed = true;
    _allowReconnect = false;
    _reconnectTimer?.cancel();
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    client.disconnect();
    _messageStream.close();
    _connectionController.close();
  }

  Future<void> connect() async {
    _debug("connect() called");
    if (_isDisposed) {
      _debug("connect() skipped: service disposed");
      return;
    }
    if (_isConnecting) {
      _debug("connect() skipped: already connecting");
      return;
    }

    // Explicit connect attempts (for example after fresh login) should
    // re-enable reconnect behavior even if a prior manual logout disabled it.
    _allowReconnect = true;

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      _debug("connect() skipped: already connected");
      return;
    }

    _isConnecting = true;
    _connectionController.add(MqttConnectionStatus.connecting);

    try {
      _debug("Trying broker connect to ${client.server}:${client.port}");
      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        _debug("connect() result: not connected, scheduling reconnect");
        _scheduleReconnect();
      } else {
        _debug("connect() result: connected");
        _listenToUpdates();
        _subscribeToCachedImeiTopics();
      }
    } on SocketException catch (e) {
      log("MQTT socket error: $e");
      _safeDisconnectClient();
      _connectionController.add(MqttConnectionStatus.disconnected);
      _scheduleReconnect();
    } catch (e) {
      log("MQTT connect error: $e");
      _safeDisconnectClient();
      _connectionController.add(MqttConnectionStatus.disconnected);
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
      _debug("connect() finished");
    }
  }

  void subscribe(String topic) {
  client.subscribe(topic, MqttQos.atLeastOnce);
}

  void _listenToUpdates() {
    _debug("Listening to MQTT updates stream");
    _updatesSubscription?.cancel();
    _updatesSubscription = client.updates?.listen(
      (events) {
        if (events.isEmpty) return;
        final recMess = events.first.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        final topic = events.first.topic;
        // log("Message received from topic: $recMess");
        // log("RAW INCOMING TOPIC: $topic");
        // log("RAW INCOMING PAYLOAD: $payload");
        if (!_messageStream.isClosed) {
          _messageStream.add(jsonEncode({"topic": topic, "payload": payload}));
        }
      },
      onError: (e) {
        log("MQTT stream error: $e");
      },
      cancelOnError: false,
    );
  }

  void _safeDisconnectClient() {
    try {
      client.disconnect();
    } catch (_) {}
  }

  void _scheduleReconnect() {
    if (_isDisposed || !_allowReconnect) {
      _debug(
        "Reconnect not scheduled (disposed=$_isDisposed, allowReconnect=$_allowReconnect)",
      );
      return;
    }
    _reconnectTimer?.cancel();
    _debug("Reconnect scheduled in 3 seconds");
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed || !_allowReconnect) {
        _debug(
          "Reconnect timer skipped (disposed=$_isDisposed, allowReconnect=$_allowReconnect)",
        );
        return;
      }
      _debug("Reconnect timer fired");
      connect();
    });
  }

  void disconnect({bool manual = true}) {
    _debug("disconnect() called (manual=$manual)");
    if (manual) {
      _allowReconnect = false;
      _debug("Reconnect disabled due to manual disconnect");
    }
    _reconnectTimer?.cancel();
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _safeDisconnectClient();
    if (!_connectionController.isClosed) {
      _connectionController.add(MqttConnectionStatus.disconnected);
    }
  }

  Future<void> resumeAndReconnect() async {
    _debug("resumeAndReconnect() called");
    if (_isDisposed) {
      _debug("resumeAndReconnect() skipped: service disposed");
      return;
    }
    _allowReconnect = true;
    await connect();
  }

  void _subscribeToCachedImeiTopics() {
    _debug("Subscribing cached device Id");
    for (final deviceId in _subscribedImeis) {
      // final garbageTopic = '$deviceId/garbage_level';
      // final cameraTopic = '$deviceId/camera_event';
      // final liveTopic = '$deviceId/device_response';
      // final plateTopic = '$deviceId/anpr_camera';

      // log("MQTT DEBUG | subscribe cached topic=$garbageTopic");
      // client.subscribe(garbageTopic, MqttQos.atLeastOnce);

      // // log("MQTT DEBUG | subscribe cached topic=$cameraTopic");
      // client.subscribe(cameraTopic, MqttQos.atLeastOnce);
      
      // // log("MQTT DEBUG | subscribe cached topic=$liveTopic");
      // client.subscribe(liveTopic, MqttQos.atLeastOnce);
      
      // // log("MQTT DEBUG | subscribe cached topic=$plateTopic");
      // client.subscribe(plateTopic, MqttQos.atLeastOnce);

    }
  }

  void subscribeToDevices(List<String> devid) {
    log("MQTT DEBUG | subscribeToDevices called: count=${devid.length}");
    _subscribedImeis.addAll(devid);
    for (final imei in devid) {
      // final garbageTopic = '$imei/garbage_level';
      // final cameraTopic = '$imei/camera_event';
      // final liveTopic = '$imei/device_response';
      // final plateTopic = '$imei/anpr_camera';

      // if (client.connectionStatus?.state == MqttConnectionState.connected) {
      //   // log("MQTT DEBUG | subscribe live topic=$garbageTopic");
      //   client.subscribe(garbageTopic, MqttQos.atLeastOnce);

      //   // log("MQTT DEBUG | subscribe live topic=$cameraTopic");
      //   client.subscribe(cameraTopic, MqttQos.atLeastOnce);

      //   // log('MQTT DEBUG | subscribe live topic=$liveTopic');
      //   client.subscribe(liveTopic, MqttQos.atLeastOnce);

      //   // log('MQTT DEBUG | subscribe live topic=$plateTopic');
      //   client.subscribe(plateTopic, MqttQos.atLeastOnce);
      // } else {
        // log("MQTT DEBUG | queue subscription: $garbageTopic");
        // log("MQTT DEBUG | queue subscription: $cameraTopic");
      // }
    }
  }

  void publish(String topic, String message) {
    // if (client.connectionStatus?.state != MqttConnectionState.connected) {
    //   log(
    //     "MQTT DEBUG | publish skipped: not connected | topic=$topic | conn=$_connState",
    //   );
    //   return;
    // }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    log("my publish msg: $message");
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void onConnected() {
    _debug("onConnected callback");
    _reconnectTimer?.cancel();
    _connectionController.add(MqttConnectionStatus.connected);
  }

  void onDisconnected() {
    _debug("onDisconnected callback");
    if (!_connectionController.isClosed) {
      _connectionController.add(MqttConnectionStatus.disconnected);
    }
    _scheduleReconnect();
  }

  void onSubscribed(String? topic) {
    log('Subscribed topic: $topic');
  }

  void onSubscribeFail(String topic) {
    log('Failed to subscribe $topic');
  }

  void pong() {
    //  log('Ping response client callback invoked');
  }
  //   void disconnect() {
  //   if (client.connectionStatus?.state ==
  //       MqttConnectionState.connected) {
  //     log("MQTT Service: Manual disconnect");
  //     log("MQTT Service: Disconnecting due to app lifecycle");
  //     client.disconnect();
  //   }
  // }
}

class MqttCubit extends Cubit<MqttConnectionStatus> {
  late final StreamSubscription _sub;

  MqttCubit(MqttService mqttService)
    : super(MqttConnectionStatus.disconnected) {
    _sub = mqttService.connectionStatusStream.listen(emit);
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
