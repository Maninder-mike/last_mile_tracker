import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/ble_constants.dart';
import '../../core/utils/file_logger.dart';
import 'ble_service.dart';

/// OTA update status for UI
enum OtaStatus {
  idle,
  checking,
  available,
  downloading,
  uploading,
  applying,
  success,
  error,
  upToDate,
}

/// Firmware release info from GitHub
class FirmwareRelease {
  final String version; // Semver e.g. "0.0.2"
  final String tagName;
  final String downloadUrl;
  final String fileName;
  final int fileSize;
  final String releaseNotes;
  final DateTime publishedAt;

  const FirmwareRelease({
    required this.version,
    required this.tagName,
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
    required this.releaseNotes,
    required this.publishedAt,
  });
}

/// OTA state for UI consumption
class OtaState {
  final OtaStatus status;
  final double progress; // 0.0 - 1.0
  final String message;
  final FirmwareRelease? release;
  final String? errorMessage;

  const OtaState({
    this.status = OtaStatus.idle,
    this.progress = 0.0,
    this.message = '',
    this.release,
    this.errorMessage,
    this.isAutoCheckEnabled = true,
  });

  final bool isAutoCheckEnabled;

  OtaState copyWith({
    OtaStatus? status,
    double? progress,
    String? message,
    FirmwareRelease? release,
    String? errorMessage,
    bool? isAutoCheckEnabled,
  }) {
    return OtaState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      release: release ?? this.release,
      errorMessage: errorMessage ?? this.errorMessage,
      isAutoCheckEnabled: isAutoCheckEnabled ?? this.isAutoCheckEnabled,
    );
  }
}

class OtaService {
  // MicroPython BLE default GATTS receive buffer is 20 bytes.
  // Each OTA data packet has a 1-byte command prefix, so the maximum
  // payload chunk is 19 bytes. This is slow but reliable until the
  // ESP32 firmware is updated to expand the buffer via gatts_set_buffer().
  static const int _chunkSize = 19;
  static const int _cmdStart = 0x01;
  static const int _cmdData = 0x02;
  static const int _cmdEnd = 0x03;

  final _stateController = StreamController<OtaState>.broadcast();
  Stream<OtaState> get stateStream => _stateController.stream;

  final _storage = const FlutterSecureStorage();
  static const _kAutoCheckKey = 'ota_auto_check';

  OtaState _state = const OtaState();
  OtaState get currentState => _state;

  OtaService() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final val = await _storage.read(key: _kAutoCheckKey);
    final isEnabled = val == null ? true : val == 'true';
    _emit(_state.copyWith(isAutoCheckEnabled: isEnabled));
  }

  Future<void> toggleAutoCheck(bool enabled) async {
    await _storage.write(key: _kAutoCheckKey, value: enabled.toString());
    _emit(_state.copyWith(isAutoCheckEnabled: enabled));
  }

  void _emit(OtaState state) {
    _state = state;
    _stateController.add(state);
  }

  /// Check GitHub Releases for a newer firmware version.
  /// [isAutoCheck] - if true, respects the user's preference.
  /// [deviceFirmwareVersion] - the version reported by the connected device.
  Future<FirmwareRelease?> checkForUpdate({
    bool isAutoCheck = false,
    String? deviceFirmwareVersion,
  }) async {
    if (isAutoCheck && !_state.isAutoCheckEnabled) {
      FileLogger.log('OTA: Auto-check disabled by user.');
      return null;
    }

    // Skip auto-check if we don't know the device version yet —
    // without it we'd default to 0.0.0 and falsely report every
    // release as "newer".
    if (isAutoCheck &&
        (deviceFirmwareVersion == null || deviceFirmwareVersion.isEmpty)) {
      FileLogger.log(
        'OTA: Skipping auto-check — device firmware version unknown.',
      );
      return null;
    }

    final localVersion = deviceFirmwareVersion ?? '0.0.0';

    _emit(
      _state.copyWith(
        status: OtaStatus.checking,
        message: 'Checking for updates...',
      ),
    );

    try {
      final url = Uri.parse(
        'https://api.github.com/repos/'
        '${BleConstants.githubOwner}/${BleConstants.githubRepo}'
        '/releases/latest',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent':
              'last-mile-tracker-app', // Required by some GitHub API endpoints
        },
      );

      if (response.statusCode == 404) {
        _emit(
          _state.copyWith(
            status: OtaStatus.upToDate,
            message: 'No releases found.',
          ),
        );
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception('GitHub API error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? 'v0';
      final body = json['body'] as String? ?? '';
      final publishedAt = DateTime.parse(
        json['published_at'] as String? ?? DateTime.now().toIso8601String(),
      );

      // Parse semver from tag (e.g. "fw-v0.0.2" -> "0.0.2")
      final remoteVersion = tagName.startsWith('fw-v')
          ? tagName.substring(4)
          : tagName.replaceAll(RegExp(r'^v'), '');

      // Find firmware asset (.py or .bin file)
      final assets = json['assets'] as List<dynamic>? ?? [];
      Map<String, dynamic>? firmwareAsset;

      for (final asset in assets) {
        final name = (asset['name'] as String).toLowerCase();
        if (name.endsWith('.py') ||
            name.endsWith('.bin') ||
            name.contains('firmware')) {
          firmwareAsset = asset as Map<String, dynamic>;
          break;
        }
      }

      if (firmwareAsset == null) {
        _emit(
          _state.copyWith(
            status: OtaStatus.upToDate,
            message: 'No firmware file in latest release.',
          ),
        );
        return null;
      }

      final release = FirmwareRelease(
        version: remoteVersion,
        tagName: tagName,
        downloadUrl: firmwareAsset['browser_download_url'] as String,
        fileName: firmwareAsset['name'] as String,
        fileSize: firmwareAsset['size'] as int,
        releaseNotes: body,
        publishedAt: publishedAt,
      );

      if (!_isNewerVersion(remoteVersion, localVersion)) {
        _emit(
          _state.copyWith(
            status: OtaStatus.upToDate,
            message: 'Firmware is up to date (v$localVersion).',
          ),
        );
        return null;
      }

      _emit(
        _state.copyWith(
          status: OtaStatus.available,
          message: 'Update available: ${release.tagName}',
          release: release,
        ),
      );

      return release;
    } catch (e, stack) {
      FileLogger.log('OTA: Check failed: $e\n$stack');
      _emit(
        _state.copyWith(
          status: OtaStatus.error,
          message: 'Update check failed.',
          errorMessage: e.toString(),
        ),
      );
      return null;
    }
  }

  /// Compare two semver strings. Returns true if remote > local.
  static bool _isNewerVersion(String remote, String local) {
    try {
      final rParts = remote
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final lParts = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
      return false;
    } catch (e) {
      FileLogger.log('OTA: Version compare error: $e');
      return false;
    }
  }

  /// Download firmware from GitHub and upload to ESP32 via BLE
  Future<void> performUpdate(BleService bleService) async {
    final release = _state.release;
    if (release == null) return;

    try {
      // Phase 1: Download
      _emit(
        _state.copyWith(
          status: OtaStatus.downloading,
          progress: 0.0,
          message: 'Downloading ${release.fileName}...',
        ),
      );

      final response = await http.get(Uri.parse(release.downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      final firmwareBytes = response.bodyBytes;
      FileLogger.log('OTA: Downloaded ${firmwareBytes.length} bytes.');

      _emit(
        _state.copyWith(
          status: OtaStatus.downloading,
          progress: 1.0,
          message: 'Download complete.',
        ),
      );

      // Phase 2: Upload via BLE
      await _uploadViaBle(firmwareBytes, release.fileName, bleService);
    } catch (e) {
      FileLogger.log('OTA: Update failed: $e');
      _emit(
        _state.copyWith(
          status: OtaStatus.error,
          progress: 0.0,
          message: 'Update failed.',
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _uploadViaBle(
    Uint8List firmware,
    String fileName,
    BleService bleService,
  ) async {
    _emit(
      _state.copyWith(
        status: OtaStatus.uploading,
        progress: 0.0,
        message: 'Connecting to device...',
      ),
    );

    // CMD_START: [cmd(1), size(4), name_len(1), name(...)]
    final nameBytes = utf8.encode(fileName);
    final startPacket = ByteData(6 + nameBytes.length);
    startPacket.setUint8(0, _cmdStart);
    startPacket.setUint32(1, firmware.length, Endian.little);
    startPacket.setUint8(5, nameBytes.length);
    for (int i = 0; i < nameBytes.length; i++) {
      startPacket.setUint8(6 + i, nameBytes[i]);
    }

    await bleService.writeOtaControl(startPacket.buffer.asUint8List());
    await Future.delayed(const Duration(milliseconds: 200));

    // CMD_DATA: chunked transfer
    // Use smaller chunks + per-chunk delay because the OTA Data characteristic
    // uses FLAG_WRITE_NO_RESPONSE (fire-and-forget). Without delays, the ESP32's
    // GATTS buffer overflows and silently drops packets.
    final totalChunks = (firmware.length / _chunkSize).ceil();
    FileLogger.log(
      'OTA: Starting upload — ${firmware.length} bytes, '
      '$totalChunks chunks of $_chunkSize bytes',
    );

    for (int i = 0; i < totalChunks; i++) {
      final start = i * _chunkSize;
      final end = (start + _chunkSize).clamp(0, firmware.length);
      final chunk = firmware.sublist(start, end);

      // Prepend command byte
      final packet = Uint8List(1 + chunk.length);
      packet[0] = _cmdData;
      packet.setRange(1, packet.length, chunk);

      await bleService.writeOtaData(packet);

      final progress = (i + 1) / totalChunks;
      _emit(
        _state.copyWith(
          status: OtaStatus.uploading,
          progress: progress,
          message: 'Uploading... ${(progress * 100).toInt()}%',
        ),
      );

      // Delay after every chunk to prevent GATTS buffer overflow
      await Future.delayed(const Duration(milliseconds: 30));

      // Extra pause every 8 chunks for ESP32 to flush to flash
      if (i % 8 == 7) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    FileLogger.log('OTA: All $totalChunks chunks sent.');

    // CMD_END: [cmd(1), sha256(32)]
    final digest = sha256.convert(firmware).bytes;
    final endPacket = Uint8List(1 + digest.length);
    endPacket[0] = _cmdEnd;
    endPacket.setRange(1, endPacket.length, digest);
    FileLogger.log(
      'OTA: Sending CMD_END with SHA-256 (${digest.length} bytes)',
    );
    await bleService.writeOtaControl(endPacket);

    _emit(
      _state.copyWith(
        status: OtaStatus.applying,
        progress: 1.0,
        message: 'Applying update... Device will restart.',
      ),
    );

    // Device will reset itself. After ~5s, show success.
    await Future.delayed(const Duration(seconds: 5));

    _emit(
      _state.copyWith(
        status: OtaStatus.success,
        progress: 1.0,
        message: 'Firmware updated to ${_state.release?.tagName ?? "latest"}!',
      ),
    );
  }

  void reset() {
    _emit(const OtaState());
  }

  void dispose() {
    _stateController.close();
  }
}
