import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:stacked/stacked.dart';

class HomeViewModel extends BaseViewModel {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  BluetoothConnection? _connection;
  String _statusMessage = 'Bluetooth bağlantısı hazırlanıyor...';
  bool _isConnecting = false;

  String get statusMessage => _statusMessage;
  bool get isConnected => _connection?.isConnected ?? false;

  Future<void> initialize() async {
    await _connectToFirstBondedDevice();
  }

  Future<void> _connectToFirstBondedDevice() async {
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;
    _statusMessage = 'Eşleşmiş cihazlar aranıyor...';
    rebuildUi();

    try {
      final devices = await _bluetooth.getBondedDevices();
      if (devices.isEmpty) {
        _statusMessage = 'Eşleşmiş Bluetooth cihazı bulunamadı.';
        return;
      }

      final BluetoothDevice device = devices.first;
      _statusMessage = '${device.name ?? device.address} cihazına bağlanılıyor...';
      rebuildUi();

      final connection = await BluetoothConnection.toAddress(device.address);
      _connection = connection;
      _statusMessage = '${device.name ?? device.address} bağlı.';
      connection.input?.listen((data) {}).onDone(() {
        _statusMessage = 'Bluetooth bağlantısı kapandı.';
        rebuildUi();
      });
    } catch (error) {
      _statusMessage = 'Bağlantı hatası: $error';
    } finally {
      _isConnecting = false;
      rebuildUi();
    }
  }

  Future<void> sendCommand(String command) async {
    if (!isConnected) {
      _statusMessage = 'Bluetooth bağlantısı yok.';
      rebuildUi();
      return;
    }

    try {
      final Uint8List data = Uint8List.fromList(utf8.encode(command));
      _connection?.output.add(data);
      await _connection?.output.allSent;
      _statusMessage = 'Gönderildi: $command';
    } catch (error) {
      _statusMessage = 'Gönderim hatası: $error';
    }
    rebuildUi();
  }

  @override
  void dispose() {
    _connection?.finish();
    _connection?.dispose();
    super.dispose();
  }
}
