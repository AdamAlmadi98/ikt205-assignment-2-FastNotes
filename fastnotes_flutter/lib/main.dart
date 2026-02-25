
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'notes_repo.dart';
import 'auth/auth_gate.dart';
import 'pages/jobb_notater_page.dart'; 
import 'widgets/bakgrunn_ny.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
    autoRefreshToken: true,
      
    ),
  );

  runApp(const FastNotesApp());
}

class FastNotesApp extends StatelessWidget {
  const FastNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FastNotes',

      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 0, 0),
          brightness: Brightness.dark,
        ),

        // ✅ Viktig for at bildet skal synes bak alle sider
        scaffoldBackgroundColor: Colors.transparent,
      ),

      // ✅ Bakgrunn rundt ALT i appen
      builder: (context, child) {
        return Bakgrunn(
          child: child ?? const SizedBox.shrink(),
        );
      },

      home: const AuthGate(),
      routes: {
        '/jobb': (_) => const JobbNotaterPage(),
        '/add': (_) => AddPage(repo: NotesRepo()),
      },
    );
  }
}

 


class AddPage extends StatefulWidget {
  final NotesRepo repo;
  const AddPage({super.key, required this.repo});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
  if (saving) return;

  final title = titleCtrl.text.trim();
  final content = contentCtrl.text.trim();

  // Validering for å sikre at tittel og innhold ikke er tomme
  if (title.isEmpty || content.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tittel og innhold kan ikke være tomme')),
    );
    return;
  }

  setState(() => saving = true);

  try {
    await widget.repo.addNote(title, content);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notat lagret!')),
    );
    Navigator.pop(context);

  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kunne ikke lagre: $e')),
    );
  } finally {
    if (mounted) setState(() => saving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nytt notat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Tittel'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(labelText: 'Innhold'),
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Lagrer…' : 'Lagre'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> note;
  final NotesRepo repo;
  const DetailPage({super.key, required this.note, required this.repo});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Map<String, dynamic> note;

  @override
  void initState() {
    super.initState();
    note = Map<String, dynamic>.from(widget.note);
  }

  Future<void> goEdit() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPage(note: note, repo: widget.repo),
      ),
    );

    if (result != null) {
      setState(() => note = result);
    }
  }

  Future<void> deleteNote() async {
    final id = note['id']?.toString();
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slette notat?'),
        content: const Text('Er du sikker? Dette kan ikke angres.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Slett', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await widget.repo.deleteNote(id);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = (note['title'] ?? '').toString();
    final content = (note['content'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detaljer'),
        actions: [
          IconButton(onPressed: goEdit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: deleteNote, icon: const Icon(Icons.delete)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title.isEmpty ? 'Uten tittel' : title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(content.isEmpty ? '— (tomt notat) —' : content),
        ]),
      ),
    );
  }
}

class EditPage extends StatefulWidget {
  final Map<String, dynamic> note;
  final NotesRepo repo;
  const EditPage({super.key, required this.note, required this.repo});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleCtrl.text = (widget.note['title'] ?? '').toString();
    contentCtrl.text = (widget.note['content'] ?? '').toString();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
  if (saving) return;

  final id = widget.note['id']?.toString();
  if (id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mangler id')),
    );
    return;
  }

  final title = titleCtrl.text.trim();
  final content = contentCtrl.text.trim();

  // 
  if (title.isEmpty || content.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tittel og innhold kan ikke være tomme')),
    );
    return;
  }

  setState(() => saving = true);

  try {
    await widget.repo.updateNote(id, title, content);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notat oppdatert!')),
    );

    Navigator.pop(context, {'id': id, 'title': title, 'content': content});

  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kunne ikke lagre: $e')),
    );
  } finally {
    if (mounted) setState(() => saving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rediger notat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Tittel'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'Innhold'),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Lagrer…' : 'Lagre endringer'),
            ),
          ),
        ]),
      ),
    );
  }
}
