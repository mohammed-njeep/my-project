import 'package:my_project/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Services {
  final sub = Supabase.instance.client;
  final url = "https://idmnixyfokzaadeqdcly.supabase.co";
  final publishableKey = "sb_publishable_oEUmHuBPInJQNZEPZWVuYA__gD9Ggib";

  createprofiles(String full_name, String role) async {
    await sub.from("profiles").insert({"full_name": full_name, "role": role});
  }

  createneighborhoods(
    String name,
    String code,
    String? area_name,
    bool is_active,
  ) async {
    await sub.from("neighborhoods").insert({
      "name": name,
      "code": code,
      "area_name": area_name,
      "is_active": is_active,
    });
  }

  create_households(
    String householdNumber,
    String neighborhoodId,
    String headName,
    String? spouseName,
    String? phone,
    String? occupation,
    String? employer,
    String? housingType,
    int maleCount,
    int femaleCount,
    String note,
  ) async {
    await sub.from("households").insert({
      "householdNumber": householdNumber,
      "neighborhoodId": neighborhoodId,
      "headName": headName,
      "spouseName": spouseName,
      "phone": phone,
      "occupation": occupation,
      "maleCount": maleCount,
      "femaleCount": femaleCount,
      "notes": note,
    });
  }
}
