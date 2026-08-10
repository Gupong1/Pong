// device_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'control_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class DevicePage extends StatefulWidget {
  final String token;
  final String username;
  final String displayName;
  final String baseUrl;
  final String deviceId;

  const DevicePage({
    super.key,
    required this.token,
    required this.username,
    required this.displayName,
    required this.baseUrl,
    required this.deviceId,
  });

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  String? _errorMessage;
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _fetchDevices();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }

  void _connectSocket() {
    try {
      _socket = IO.io(
        widget.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'token': widget.token})
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('Socket connected');
        // 🔥 JOIN CONTROLLER
        _socket!.emit('controller:join', {'token': widget.token});
      });

      // 🔥 TERIMA UPDATE DEVICE DARI SERVER
      _socket!.on('devices:update', (data) {
        if (mounted) {
          setState(() {
            if (data is List) {
              _devices = data;
            }
          });
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('Socket disconnected');
      });

      _socket!.onConnectError((data) {
        debugPrint('Socket error: $data');
      });

    } catch (e) {
      debugPrint('Socket connection error: $e');
    }
  }

  // 🔥 ENDPOINT: GET /api/devices
  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/devices'),
        headers: {'x-auth-token': widget.token},
      );

      if (response.statusCode == 401) {
        if (!mounted) return;
        _showSessionExpired();
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _devices = data is List ? data : [];
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data device';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal terhubung ke server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectDevice(Map<String, dynamic> device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ControlPage(
          token: widget.token,
          deviceId: device['id'],
          deviceName: device['name'] ?? 'Unknown Device',
          baseUrl: widget.baseUrl,
          deviceData: device,
          socket: _socket,
        ),
      ),
    );
  }

  void _logout() async {
    // 🔥 ENDPOINT: POST /api/logout
    try {
      await http.post(
        Uri.parse('${widget.baseUrl}/api/logout'),
        headers: {'x-auth-token': widget.token},
      );
    } catch (e) {
      // Ignore
    }
    _socket?.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pop(context);
    }
  }

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
            Text(
              widget.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4d8fff)),
            onPressed: _fetchDevices,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF4D6D)),
            onPressed: _logout,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1D6FFF),
            ),
            SizedBox(height: 16),
            Text(
              'Memuat device...',
              style: TextStyle(color: Color(0xFF3d6080)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: const Color(0xFFFF4D6D).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFF3d6080)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDevices,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D6FFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android_outlined,
              size: 64,
              color: Color(0xFF1a3050),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada device terhubung',
              style: TextStyle(
                color: Color(0xFF3d6080),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hubungkan device untuk mulai kontrol',
              style: TextStyle(
                color: Color(0xFF1a3050),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDevices,
      color: const Color(0xFF1D6FFF),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index] as Map<String, dynamic>;
          final info = device['info'] ?? {};
          final status = device['status'] ?? {};
          final isOnline = status['online'] != false;
          final ip = info['ip'] ?? 'IP tidak tersedia';
          final battery = info['battery'] ?? -1;
          final androidVersion = info['androidVersion'] ?? '?';
          final sdkVersion = info['sdkVersion'] ?? '?';
          final deviceName = device['name'] ?? 'Unknown Device';

          return _DeviceCard(
            deviceId: device['id'] ?? '',
            deviceName: deviceName,
            isOnline: isOnline,
            battery: battery,
            androidVersion: androidVersion,
            sdkVersion: sdkVersion,
            ip: ip,
            onTap: () => _selectDevice(device),
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String deviceId;
  final String deviceName;
  final bool isOnline;
  final int battery;
  final String androidVersion;
  final String sdkVersion;
  final String ip;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.deviceId,
    required this.deviceName,
    required this.isOnline,
    required this.battery,
    required this.androidVersion,
    required this.sdkVersion,
    required this.ip,
    required this.onTap,
  });

  Color getBatteryColor(int batt) {
    if (batt <= 20) return const Color(0xFFFF4D6D);
    if (batt <= 40) return const Color(0xFFFFC34D);
    return const Color(0xFF00E5A0);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF081428),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOnline ? const Color(0xFF1D6FFF).withOpacity(0.2) : const Color(0xFF1a3050),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF1D6FFF).withOpacity(0.1)
                      : const Color(0xFF1a3050),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline
                        ? const Color(0xFF1D6FFF).withOpacity(0.3)
                        : const Color(0xFF1a3050),
                  ),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: isOnline ? const Color(0xFF4d8fff) : const Color(0xFF3d6080),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deviceName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF00E5A0).withOpacity(0.1)
                                : const Color(0xFFFF4D6D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isOnline
                                  ? const Color(0xFF00E5A0).withOpacity(0.3)
                                  : const Color(0xFFFF4D6D).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isOnline ? const Color(0xFF00E5A0) : const Color(0xFFFF4D6D),
                                  shape: BoxShape.circle,
                                  boxShadow: isOnline
                                      ? [BoxShadow(color: const Color(0xFF00E5A0).withOpacity(0.5), blurRadius: 4)]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOnline ? 'ONLINE' : 'OFFLINE',
                                style: TextStyle(
                                  color: isOnline ? const Color(0xFF00E5A0) : const Color(0xFFFF4D6D),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (battery >= 0) ...[
                          Icon(
                            Icons.battery_std,
                            color: getBatteryColor(battery),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$battery%',
                            style: TextStyle(
                              color: getBatteryColor(battery),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.android,
                          color: const Color(0xFF3d6080),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Android $androidVersion',
                          style: const TextStyle(
                            color: Color(0xFF3d6080),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.code,
                          color: const Color(0xFF3d6080),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SDK $sdkVersion',
                          style: const TextStyle(
                            color: Color(0xFF3d6080),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.wifi,
                          color: isOnline ? const Color(0xFF4d8fff) : const Color(0xFF1a3050),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ip,
                          style: TextStyle(
                            color: isOnline ? const Color(0xFF4d8fff) : const Color(0xFF1a3050),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isOnline ? const Color(0xFF4d8fff) : const Color(0xFF1a3050),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}