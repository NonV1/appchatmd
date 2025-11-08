import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/http_client.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key, required this.apiBase});
  final String apiBase;

  @override
  State<LoginRegisterScreen> createState() => _S();
}

class _S extends State<LoginRegisterScreen> {
  final _tab = ValueNotifier<int>(0);
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _name  = TextEditingController();
  final _storage = const FlutterSecureStorage();
  late final Api _api = Api(widget.apiBase, _storage);

  bool _busy = false;
  String? _err;

  Future<void> _login() async {
    setState(()=>_busy=true); _err=null;
    try {
      final data = await _api.post('/auth/login', {
        'email': _email.text.trim(),
        'password': _pass.text,
      });
      final token = data['access_token'] as String?;
      if (token == null) throw Exception('Invalid response');
      await _storage.write(key: 'access_token', value: token);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/wearables');
    } catch (e) { setState(()=>_err=e.toString()); }
    finally { if(mounted) setState(()=>_busy=false); }
  }

  Future<void> _register() async {
    setState(()=>_busy=true); _err=null;
    try {
      final data = await _api.post('/auth/register', {
        'email': _email.text.trim(),
        'password': _pass.text,
        'display_name': _name.text.trim(),
      });
      final token = data['access_token'] as String?;
      if (token == null) throw Exception('Invalid response');
      await _storage.write(key: 'access_token', value: token);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/wearables');
    } catch (e) { setState(()=>_err=e.toString()); }
    finally { if(mounted) setState(()=>_busy=false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChatMD')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Login')),
              ButtonSegment(value: 1, label: Text('Register')),
            ],
            selected: {_tab.value},
            onSelectionChanged: (s) => setState(()=>_tab.value = s.first),
          ),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _pass, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password')),
          if (_tab.value == 1)
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Display name')),
          const SizedBox(height: 12),
          if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : (_tab.value==0 ? _login : _register),
            child: _busy ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                         : Text(_tab.value==0 ? 'Sign in' : 'Create account'),
          ),
        ]),
      ),
    );
  }
}
