


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;


@override
void dispose() {
  emailCtrl.dispose();
  passwordCtrl.dispose();
  super.dispose();
}

Future<void> login() async {
  if (loading) return;

  setState(() => loading = true);

  try {
    final res = await Supabase.instance.client.auth.signInWithPassword(
      email: emailCtrl.text.trim(),
      password: passwordCtrl.text,
    );

    if (!mounted) return;

    // Dette kjører hvis login funket
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Innlogget: ${res.user?.email ?? "ok"}')),
    );

  } on AuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login feilet: ${e.message}')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ukjent feil: $e')),
    );
  } finally {
    if (mounted) setState(() => loading = false);
  }
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title:const Text('Login')),
    body:Padding(padding: const EdgeInsets.all(16),
    child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'E-post'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(labelText: 'Passord'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: Text(loading ? 'Logger inn…' : 'Logg inn'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
              child: const Text('Lag ny konto'),
            ),
          ],
        ),
      ),
    );
  }
}