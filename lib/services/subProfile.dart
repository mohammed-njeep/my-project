import 'package:my_project/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class subProfile {
  final sub = Supabase.instance.client;

  String get _uid => sub.auth.currentUser!.id;

  Future<void> createProfile(
    String fullName,
    String role, // admin | supervisor | researcher | viewer
    bool isActive,
  ) async {
    await sub.from("profiles").insert({
      "user_id": _uid,
      "full_name": fullName,
      "role": role,
      "is_active": isActive,
    });
  }

  Future<void> updateProfile(String fullName, bool isActive) async {
    await sub
        .from("profiles")
        .update({
          "full_name": fullName,

          "is_active": isActive,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("user_id", _uid);
  }
}
