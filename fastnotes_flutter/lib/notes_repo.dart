import 'package:supabase_flutter/supabase_flutter.dart';

class NotesRepo {

  //referanse til Supabase klienten
  final SupabaseClient db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchNotes() async {

    /// Henter alle rader fra notes-tabellen
    final data = await db
        .from('notes')
        .select('id, title, content, created_at')
        .order('created_at', ascending: false);

    /// Konverterer Supabase response til List<Map>
    return List<Map<String, dynamic>>.from(data);
  }


  /// INSERT NOTE
  Future<void> addNote(String title, String content) async {
    final t =title.trim();
    final c =content.trim();
 
  //sjekk for ingen tomme felter
  if (t.isEmpty || c.isEmpty) {
      throw Exception('Tittel og innhold kan ikke være tomme.');
    }

  final userId = db.auth.currentUser?.id;
  if (userId == null) {
    throw Exception('Bruker ikke logget inn.');
  }  


    await db.from('notes').insert({
      'title': t,
      'content': c,
      'user_id': userId,
    });
  }

  //oppdater notater

  Future<void> updateNote(String id, String title, String content) async {
    final t =title.trim();
    final c =content.trim();

    if (t.isEmpty || c.isEmpty) {
      throw Exception('Tittel og innhold kan ikke være tomme.');
    }
    await db.from('notes').update({
      'title': t,
      'content': c,
    }).eq('id', id);
  }

    //slette notater
    Future<void> deleteNote(String id) async {
    await db.from('notes').delete().eq('id', id);

  }
  
}