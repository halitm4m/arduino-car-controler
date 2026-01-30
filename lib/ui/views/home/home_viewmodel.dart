import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:stacked/stacked.dart';

class SongItem {
  final int index;
  final String name;

  const SongItem(this.index, this.name);
}

class HomeViewModel extends BaseViewModel {
  final BluetoothClassic _bluetooth = BluetoothClassic();

  static const String _sppUuid = '00001101-0000-1000-8000-00805f9b34fb';

  StreamSubscription<int>? _statusSub;
  StreamSubscription<Uint8List>? _dataSub;

  Device? _connectedDevice;
  bool _isConnecting = false;
  DateTime? _lastReconnectRequestedAt;

  String _statusMessage = 'Bluetooth bağlantısı hazırlanıyor...';

  DateTime? _lastForwardSentAt;
  DateTime? _lastBackwardSentAt;
  int _lastForwardValue = -1;
  int _lastBackwardValue = -1;

  DateTime? _lastSteerSentAt;
  int _lastSteerValue = 999999;

  bool _isForwardThrottleActive = false;
  bool _isBackwardThrottleActive = false;

  final StringBuffer _rxBuffer = StringBuffer();

  List<SongItem> _songs = const [];
  int _selectedSongIndex = -1;
  bool _isSongPlaying = false;
  String _playingSongName = '';

  String _hornName = '';
  bool _isHornHolding = false;

  Timer? _txTimer;
  bool _txInFlight = false;

  int _desiredForward = 0;
  int _desiredBackward = 0;
  int _desiredSteerSigned = 0;

  String get statusMessage => _statusMessage;
  bool get isConnected => _connectedDevice != null;

  bool get isForwardThrottleEnabled => !_isBackwardThrottleActive;
  bool get isBackwardThrottleEnabled => !_isForwardThrottleActive;

  List<SongItem> get songs => _songs;
  int get selectedSongIndex => _selectedSongIndex;

  bool get isSongPlaying => _isSongPlaying;
  String get playingSongName => _playingSongName;

  void setForwardThrottleActive(bool active) {
    if (_isForwardThrottleActive == active) return;
    _isForwardThrottleActive = active;

    if (active) {
      _isBackwardThrottleActive = false;
      _lastBackwardValue = -1;
      _lastBackwardSentAt = null;
    }

    rebuildUi();
  }

  void setBackwardThrottleActive(bool active) {
    if (_isBackwardThrottleActive == active) return;
    _isBackwardThrottleActive = active;

    if (active) {
      _isForwardThrottleActive = false;
      _lastForwardValue = -1;
      _lastForwardSentAt = null;
    }

    rebuildUi();
  }

  void setSelectedSongIndex(int index) {
    if (_selectedSongIndex == index) return;
    _selectedSongIndex = index;
    rebuildUi();
  }

  Future<void> initialize() async {
    await _setupListeners();
    await _initPermissionsAndConnect();
  }

  Future<void> _setupListeners() async {
    await _statusSub?.cancel();
    await _dataSub?.cancel();

    _statusSub = _bluetooth.onDeviceStatusChanged().listen((status) {
      if (status == Device.connected) {
        _statusMessage = '${_connectedDevice?.name ?? _connectedDevice?.address ?? "Cihaz"} bağlı.';
      } else if (status == Device.disconnected) {
        _connectedDevice = null;
        _statusMessage = 'Bluetooth bağlantısı kapandı.';
        _songs = const [];
        _selectedSongIndex = -1;
        _isSongPlaying = false;
        _playingSongName = '';
        _hornName = '';
        _isHornHolding = false;
        _stopTxLoop();
      } else {
        _statusMessage = 'Bluetooth durumu değişti: $status';
      }
      rebuildUi();
    });

    _dataSub = _bluetooth.onDeviceDataReceived().listen((bytes) {
      final String chunk = String.fromCharCodes(bytes);
      _appendIncoming(chunk);
    });
  }

  void _appendIncoming(String chunk) {
    if (chunk.isEmpty) return;
    _rxBuffer.write(chunk);

    String data = _rxBuffer.toString();
    int idx;

    while ((idx = data.indexOf('\n')) != -1) {
      final String line = data.substring(0, idx).trim();
      data = data.substring(idx + 1);
      if (line.isNotEmpty) _handleIncomingLine(line);
    }

    _rxBuffer
      ..clear()
      ..write(data);
  }

  void _handleIncomingLine(String line) {
    if (line.startsWith('SONGS|')) {
      final parts = line.split('|');
      final List<SongItem> parsed = [];
      String hornName = '';

      for (int i = 1; i + 1 < parts.length; i += 2) {
        final int? index = int.tryParse(parts[i]);
        final String name = parts[i + 1];
        if (index == null || name.isEmpty) continue;

        if (index == 0) {
          hornName = name;
          continue;
        }

        parsed.add(SongItem(index, name));
      }

      _hornName = hornName;
      _songs = parsed;

      if (_songs.isNotEmpty && (_selectedSongIndex == -1 || _selectedSongIndex == 0)) {
        _selectedSongIndex = _songs.first.index;
      }

      _statusMessage = 'Müzik listesi alındı (${_songs.length}).';
      rebuildUi();
      return;
    }

    if (line.startsWith('PLAYING|')) {
      final parts = line.split('|');
      if (parts.length >= 3) {
        final int? index = int.tryParse(parts[1]);
        final String name = parts.sublist(2).join('|');

        _isSongPlaying = true;
        _playingSongName = name;

        if (index != null && index != 0) {
          _selectedSongIndex = index;
          _statusMessage = 'Çalıyor: $name';
        } else {
          _statusMessage = 'Korna: $name';
        }

        rebuildUi();
      }
      return;
    }

    if (line.startsWith('DONE|')) {
      final parts = line.split('|');
      _isSongPlaying = false;
      _playingSongName = '';
      if (parts.length >= 2) {
        final int? index = int.tryParse(parts[1]);
        if (index == 0) {
          _statusMessage = 'Korna bitti.';
        } else {
          _statusMessage = index == null ? 'Parça bitti.' : 'Parça bitti (#$index).';
        }
      } else {
        _statusMessage = 'Parça bitti.';
      }
      rebuildUi();
      return;
    }

    if (line == 'STOPPED') {
      _isSongPlaying = false;
      _playingSongName = '';
      _statusMessage = 'Müzik durduruldu.';
      rebuildUi();
      return;
    }

    _statusMessage = 'Gelen: $line';
    rebuildUi();
  }

  Future<void> _initPermissionsAndConnect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      _statusMessage = 'Bluetooth izinleri kontrol ediliyor...';
      rebuildUi();

      await _bluetooth.initPermissions();

      _statusMessage = 'Eşleşmiş cihazlar aranıyor...';
      rebuildUi();

      final List<Device> paired = await _bluetooth.getPairedDevices();

      if (paired.isEmpty) {
        _statusMessage = 'Eşleşmiş Bluetooth cihazı bulunamadı.';
        rebuildUi();
        return;
      }

      final Device target = paired.firstWhere(
            (d) => (d.name ?? '').toUpperCase().contains('HC-06'),
        orElse: () => paired.first,
      );

      _connectedDevice = target;
      _statusMessage = '${target.name ?? target.address} cihazına bağlanılıyor...';
      rebuildUi();

      await _bluetooth.connect(target.address, _sppUuid);

      _statusMessage = '${target.name ?? target.address} bağlı.';
      rebuildUi();

      _startTxLoop();

      requestSongList();
    } catch (e) {
      _connectedDevice = null;
      _statusMessage = 'Bağlantı hatası: $e';
      rebuildUi();
      _stopTxLoop();
    } finally {
      _isConnecting = false;
      rebuildUi();
    }
  }

  void _startTxLoop() {
    _txTimer?.cancel();
    _txTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      unawaited(_flushTx());
    });
  }

  void _stopTxLoop() {
    _txTimer?.cancel();
    _txTimer = null;
    _txInFlight = false;
  }

  Future<void> _flushTx() async {
    if (_txInFlight) return;
    if (!isConnected) return;

    _txInFlight = true;

    try {
      final int steer = _desiredSteerSigned.clamp(-255, 255);

      int forward = _desiredForward.clamp(0, 255);
      int backward = _desiredBackward.clamp(0, 255);

      if (forward > 0) {
        backward = 0;
        _desiredBackward = 0;
      } else if (backward > 0) {
        forward = 0;
        _desiredForward = 0;
      }

      final DateTime now = DateTime.now();

      await _trySendSteer(now, steer);
      await _trySendForward(now, forward);
      await _trySendBackward(now, backward);
    } catch (e) {
      _statusMessage = 'Gönderim hatası: $e';
      rebuildUi();
    } finally {
      _txInFlight = false;
    }
  }

  Future<void> _trySendSteer(DateTime now, int steer) async {
    if (steer == _lastSteerValue) return;
    if (_lastSteerSentAt != null && now.difference(_lastSteerSentAt!).inMilliseconds < 35) {
      return;
    }

    _lastSteerSentAt = now;
    _lastSteerValue = steer;

    await _bluetooth.write('S|$steer\n');
  }

  Future<void> _trySendForward(DateTime now, int forward) async {
    if (forward == _lastForwardValue) return;
    if (_lastForwardSentAt != null && now.difference(_lastForwardSentAt!).inMilliseconds < 35) {
      return;
    }

    _lastForwardSentAt = now;
    _lastForwardValue = forward;

    await _bluetooth.write('F$forward\n');
  }

  Future<void> _trySendBackward(DateTime now, int backward) async {
    if (backward == _lastBackwardValue) return;
    if (_lastBackwardSentAt != null && now.difference(_lastBackwardSentAt!).inMilliseconds < 35) {
      return;
    }

    _lastBackwardSentAt = now;
    _lastBackwardValue = backward;

    await _bluetooth.write('B$backward\n');
  }

  void requestSongList() {
    unawaited(_requestSongListAsync());
  }

  Future<void> _requestSongListAsync() async {
    if (!isConnected) {
      _statusMessage = 'Bluetooth bağlantısı yok.';
      rebuildUi();
      return;
    }

    try {
      await _bluetooth.write('LIST\n');
      _statusMessage = 'Müzik listesi isteniyor...';
    } catch (e) {
      _statusMessage = 'Liste isteği hatası: $e';
    }
    rebuildUi();
  }

  void playSelectedSong() {
    if (_selectedSongIndex < 0) {
      _statusMessage = 'Seçili müzik yok.';
      rebuildUi();
      return;
    }
    if (_selectedSongIndex == 0) {
      _statusMessage = 'Korna listede görünmez.';
      rebuildUi();
      return;
    }
    playSongByIndex(_selectedSongIndex);
  }

  void playSongByIndex(int index) {
    unawaited(_playSongByIndexAsync(index));
  }

  Future<void> _playSongByIndexAsync(int index) async {
    if (!isConnected) {
      _statusMessage = 'Bluetooth bağlantısı yok.';
      rebuildUi();
      return;
    }

    try {
      await _bluetooth.write('PLAY|$index\n');
      _statusMessage = index == 0
          ? 'Korna çal komutu gönderildi.'
          : 'Çal komutu gönderildi: #$index';
    } catch (e) {
      _statusMessage = 'Gönderim hatası: $e';
    }
    rebuildUi();
  }

  void stopSong() {
    unawaited(_stopSongAsync());
  }

  Future<void> _stopSongAsync() async {
    if (!isConnected) {
      _statusMessage = 'Bluetooth bağlantısı yok.';
      rebuildUi();
      return;
    }

    try {
      await _bluetooth.write('STOP\n');
      _statusMessage = 'Durdur komutu gönderildi.';
    } catch (e) {
      _statusMessage = 'Gönderim hatası: $e';
    }
    rebuildUi();
  }

  void hornDown() {
    unawaited(_hornDownAsync());
  }

  Future<void> _hornDownAsync() async {
    if (!isConnected) return;
    if (_isHornHolding) return;

    _isHornHolding = true;

    try {
      await _bluetooth.write('PLAY|0\n');
      final String name = _hornName.isNotEmpty ? _hornName : 'Korna';
      _statusMessage = 'Korna: $name';
    } catch (e) {
      _statusMessage = 'Korna hatası: $e';
      _isHornHolding = false;
    }
    rebuildUi();
  }

  void hornUp() {
    unawaited(_hornUpAsync());
  }

  Future<void> _hornUpAsync() async {
    if (!isConnected) return;
    if (!_isHornHolding) return;

    _isHornHolding = false;

    try {
      await _bluetooth.write('STOP\n');
      _statusMessage = 'Korna durduruldu.';
    } catch (e) {
      _statusMessage = 'Korna durdurma hatası: $e';
    }
    rebuildUi();
  }

  void sendCommand(String command) {
    unawaited(_sendCommandAsync(command));
  }

  Future<void> _sendCommandAsync(String command) async {
    if (!isConnected) {
      _statusMessage = 'Bluetooth bağlantısı yok.';
      rebuildUi();
      return;
    }

    try {
      await _bluetooth.write('$command\n');
    } catch (e) {
      _statusMessage = 'Gönderim hatası: $e';
      rebuildUi();
    }
  }

  void sendForwardThrottle(int value) {
    if (!isForwardThrottleEnabled) return;

    final int v = value.clamp(0, 255);
    _desiredForward = v;
    if (v > 0) _desiredBackward = 0;

    if (v > 0) {
      setBackwardThrottleActive(false);
      setForwardThrottleActive(true);
    } else {
      setForwardThrottleActive(false);
    }
  }

  void sendBackwardThrottle(int value) {
    if (!isBackwardThrottleEnabled) return;

    final int v = value.clamp(0, 255);
    _desiredBackward = v;
    if (v > 0) _desiredForward = 0;

    if (v > 0) {
      setForwardThrottleActive(false);
      setBackwardThrottleActive(true);
    } else {
      setBackwardThrottleActive(false);
    }
  }

  void sendSteering(double normalized) {
    if (normalized.isNaN) return;

    double n = normalized;
    if (n > 1.0) n = 1.0;
    if (n < -1.0) n = -1.0;

    int signed = (n * 255).round();
    if (signed > 255) signed = 255;
    if (signed < -255) signed = -255;

    _desiredSteerSigned = signed;
  }

  void refreshBluetoothConnection() {
    final DateTime now = DateTime.now();
    if (_lastReconnectRequestedAt != null && now.difference(_lastReconnectRequestedAt!).inMilliseconds < 900) {
      return;
    }
    _lastReconnectRequestedAt = now;

    if (_isConnecting) return;

    _statusMessage = 'Bluetooth bağlantısı yenileniyor...';
    rebuildUi();

    unawaited(reconnect());
  }

  Future<void> reconnect() async {
    await disconnect();
    await _initPermissionsAndConnect();
  }

  Future<void> disconnect() async {
    _stopTxLoop();

    try {
      await _bluetooth.disconnect();
    } catch (_) {}

    _connectedDevice = null;
    _statusMessage = 'Bluetooth bağlantısı kapatıldı.';
    _songs = const [];
    _selectedSongIndex = -1;
    _isSongPlaying = false;
    _playingSongName = '';
    _hornName = '';
    _isHornHolding = false;

    _lastForwardSentAt = null;
    _lastBackwardSentAt = null;
    _lastForwardValue = -1;
    _lastBackwardValue = -1;

    _lastSteerSentAt = null;
    _lastSteerValue = 999999;

    _isForwardThrottleActive = false;
    _isBackwardThrottleActive = false;

    _desiredForward = 0;
    _desiredBackward = 0;
    _desiredSteerSigned = 0;

    rebuildUi();
  }

  @override
  void dispose() {
    _stopTxLoop();
    _statusSub?.cancel();
    _dataSub?.cancel();
    _bluetooth.disconnect();
    super.dispose();
  }
}
