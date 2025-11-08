import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/wearables/health_service.dart';

class WearablesScreen extends StatefulWidget {
  const WearablesScreen({super.key});
  @override
  State<WearablesScreen> createState() => _S();
}

class _S extends State<WearablesScreen> {
  final _svc = HealthService();

  bool _healthConnectAvailable = true;
  bool _diagnosticsLoading = true;
  HealthDiagnostics? _diagnostics;

  WearableSnapshot? _snap;
  StreamSubscription<WearableSnapshot?>? _sub;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
    _sub = _svc.snapshots.listen((s) {
      if (!mounted) return;
      setState(() => _snap = s);
    });
    _svc.startAutoPolling();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _svc.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _diagnosticsLoading = true);
    final diag = await _svc.diagnostics();
    if (!mounted) return;
    setState(() {
      _diagnostics = diag;
      _healthConnectAvailable = diag.isHealthConnectAvailable;
      _diagnosticsLoading = false;
    });
  }

  Future<void> _installOrUpdateHealthConnect() async {
    final ready = await _svc.ensureHealthConnectInstalled();
    if (!mounted) return;
    if (!ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กำลังเปิดหน้าติดตั้ง Health Connect • ติดตั้ง/อัปเดตให้เสร็จแล้วกลับมาเชื่อมต่ออีกครั้ง',
          ),
        ),
      );
    }
    await _loadDiagnostics();
  }

  Future<void> _openHealthConnectApp() async {
    final ok = await _svc.openHealthConnectApp();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่พบแอป Health Connect ในเครื่องนี้')),
      );
    }
    await _loadDiagnostics();
  }

  Future<void> _connectHealth() async {
    if (!_healthConnectAvailable) {
      await _installOrUpdateHealthConnect();
      return;
    }
    final ok = await _svc.requestPermissions();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ยังไม่ได้อนุญาตใน Health Connect • เปิด Health Connect > App permissions > อนุญาต Steps / Heart rate / Sleep / SpO₂ ให้แอปนี้',
          ),
        ),
      );
    }
    await _loadDiagnostics();
  }

  Future<void> _manualRefresh() async {
    final s = await _svc.fetchToday();
    if (!mounted) return;
    setState(() => _snap = s);
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final loading = _diagnosticsLoading && _snap == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: _logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBody(context),
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_snap == null) {
      return _ConnectPrompt(
        diagnostics: _diagnostics,
        healthConnectAvailable: _healthConnectAvailable,
        onConnect: _connectHealth,
        onInstall: _installOrUpdateHealthConnect,
        onOpenApp: _openHealthConnectApp,
        onRefreshDiag: _loadDiagnostics,
      );
    }

    if (!_snap!.hasMetrics) {
      return _NoDataMessage(
        diagnostics: _diagnostics,
        onDiagnose: _loadDiagnostics,
        onRefresh: _manualRefresh,
        onOpenApp: _openHealthConnectApp,
      );
    }

    return RefreshIndicator(
      onRefresh: _manualRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'ข้อมูลจาก Health Connect (อัปเดตอัตโนมัติทุก 10 นาที)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          for (final metric in _snap!.metrics) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _MetricTile(metric: metric),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FilledButton.icon(
              onPressed: _manualRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('รีเฟรชทันที'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OutlinedButton.icon(
              onPressed: _openHealthConnectApp,
              icon: const Icon(Icons.open_in_new),
              label: const Text('เปิด Health Connect'),
            ),
          ),
          if (_diagnostics != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _DiagCard(diag: _diagnostics!, onRefresh: _loadDiagnostics),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagCard extends StatelessWidget {
  const _DiagCard({required this.diag, required this.onRefresh});
  final HealthDiagnostics diag;
  final VoidCallback onRefresh;

  String _statusText(String label, bool granted) =>
      '$label: ${granted ? 'อนุญาตแล้ว' : 'ยังไม่อนุญาต'}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สถานะ Health Connect',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('ติดตั้งแล้ว: ${diag.isInstalled ? '✔' : '✗'}'),
          Text('พร้อมใช้งาน: ${diag.isHealthConnectAvailable ? '✔' : '✗'}'),
          Text('ต้องอัปเดต: ${diag.requiresUpdate ? '✔' : '✗'}'),
          const Divider(height: 16),
          for (final e in diag.permissionStatus.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(_statusText(e.key.name, e.value)),
            ),
          Text('ทั้งหมดอนุญาตแล้ว: ${diag.hasAllPermissions ? '✔' : '✗'}'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('รีเฟรชสถานะ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});
  final WearableMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(metric.value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          if (metric.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              metric.subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectPrompt extends StatelessWidget {
  const _ConnectPrompt({
    required this.diagnostics,
    required this.healthConnectAvailable,
    required this.onConnect,
    required this.onInstall,
    required this.onOpenApp,
    required this.onRefreshDiag,
  });

  final HealthDiagnostics? diagnostics;
  final bool healthConnectAvailable;
  final VoidCallback onConnect;
  final VoidCallback onInstall;
  final VoidCallback onOpenApp;
  final VoidCallback onRefreshDiag;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            healthConnectAvailable
                ? 'ยังไม่ได้เชื่อมต่อ Health Connect'
                : 'ยังไม่พบแอป Health Connect ในเครื่อง',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            healthConnectAvailable
                ? 'ขั้นตอน: เปิด Health Connect > App permissions > อนุญาต Steps / Heart rate / Sleep / SpO₂ ให้แอปนี้'
                : 'กด “ติดตั้ง/อัปเดต Health Connect” เพื่อไปยัง Store จากนั้นกลับมาเชื่อมต่ออีกครั้ง',
          ),
          const SizedBox(height: 16),
          if (diagnostics != null) ...[
            _DiagCard(diag: diagnostics!, onRefresh: onRefreshDiag),
            const SizedBox(height: 12),
          ],
          if (!healthConnectAvailable) ...[
            FilledButton.icon(
              onPressed: onInstall,
              icon: const Icon(Icons.download),
              label: const Text('ติดตั้ง/อัปเดต Health Connect'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('เชื่อมต่อ Health Connect'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenApp,
            icon: const Icon(Icons.open_in_new),
            label: const Text('เปิดแอป Health Connect'),
          ),
        ],
      ),
    );
  }
}

class _NoDataMessage extends StatelessWidget {
  const _NoDataMessage({
    required this.diagnostics,
    required this.onDiagnose,
    required this.onRefresh,
    required this.onOpenApp,
  });

  final HealthDiagnostics? diagnostics;
  final VoidCallback onDiagnose;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ยังไม่มีข้อมูลจาก Health Connect ในวันนี้',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'ข้อมูลบางประเภทขึ้นกับอุปกรณ์/บริการที่คุณซิงก์ • เมื่อมีข้อมูลใหม่ระบบจะอัปเดตอัตโนมัติทุก 10 นาที',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              onRefresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('รีเฟรชทันที'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenApp,
            icon: const Icon(Icons.open_in_new),
            label: const Text('เปิด Health Connect'),
          ),
          const SizedBox(height: 16),
          if (diagnostics != null)
            _DiagCard(diag: diagnostics!, onRefresh: onDiagnose),
        ],
      ),
    );
  }
}
