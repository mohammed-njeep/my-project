import 'package:supabase_flutter/supabase_flutter.dart';

class Authclass {
  final auth = Supabase.instance.client.auth;
  signup(String email, String pass) async {
    await auth.signUp(password: pass, email: email);
  }

  login(String email, String pass) async {
    await auth.signInWithPassword(password: pass, email: email);
  }

  logout() {}
}
