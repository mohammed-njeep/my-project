import 'package:my_project/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Services {
  final url = "https://idmnixyfokzaadeqdcly.supabase.co";
  final publishableKey = "sb_publishable_oEUmHuBPInJQNZEPZWVuYA__gD9Ggib";
}

class Backend {
  final sub = Supabase.instance.client;
  String get _uid => sub.auth.currentUser!.id;
  // createprofiles(String full_name, String role) async {
  //   await sub.from("profiles").insert({"full_name": full_name, "role": role});
  // }

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

  Future<void> createNeighborhood({
    String? name,
    String? code,
    String? areaName,
  }) async {
    await sub.from("neighborhoods").insert({
      "name": name,
      "code": code,
      "area_name": areaName,
      "is_active": true,
    });
  }

  Future<List<Map<String, dynamic>>> getNeighborhoods({
    bool onlyActive = false,
  }) async {
    var q = sub.from("neighborhoods").select();
    if (onlyActive) q = q.eq("is_active", true);
    return await q.order("name");
  }

  Future<void> updateNeighborhood(
    String name,
    String? code,
    String? areaName,
    bool isActive,
  ) async {
    await sub
        .from("neighborhoods")
        .update({
          "name": name,
          "code": code,
          "area_name": areaName,
          "is_active": isActive,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("id", _uid);
  }

  Future<void> assignNeighborhood(
    String researcherId,
    String neighborhoodId,
    DateTime? assignedFrom,
    DateTime? assignedTo,
  ) async {
    await sub.from("researcher_neighborhoods").insert({
      "researcher_id": researcherId,
      "neighborhood_id": neighborhoodId,
      // if (assignedFrom != null) "assigned_from": _d(assignedFrom),
      // "assigned_to": _uid(assignedTo),
    });
  }

  Future<void> createHousehold({
    required String neighborhoodId,
    required String headName,
    int? malesCount,
    int? femalesCount,
    String? notes,
    String? householdNumber,
    String? spouseName,
    String? phone,
    String? occupation,
    String? employer,
    String? housingType,
    required int maleCount,
    required int femaleCount,
  }) async {
    await sub.from("households").insert({
      "household_number": householdNumber,
      "neighborhood_id": neighborhoodId,
      "head_name": headName,
      "spouse_name": spouseName,
      "phone": phone,
      "occupation": occupation,
      "employer": employer,
      "housing_type": housingType,
      "males_count": malesCount,
      "females_count": femalesCount,
      "notes": notes,
      "created_by": _uid,
    });
  }

  Future<List<Map<String, dynamic>>> getHouseholds({
    String? neighborhoodId,
    int from = 0,
    int to = 49,
  }) async {
    var q = sub.from("households").select().isFilter("deleted_at", null);
    if (neighborhoodId != null) q = q.eq("neighborhood_id", neighborhoodId);
    return await q.order("created_at", ascending: false).range(from, to);
  }

  Future<Map<String, dynamic>?> getHouseholdById(String id) async {
    return await sub
        .from("households")
        .select("*, family_members(*), household_residency(*)")
        .eq("id", id)
        .isFilter("deleted_at", null)
        .maybeSingle();
  }

  Future<void> createFamilyMember(
    String householdId,
    String fullName,
    String relationship,
    String gender,
    DateTime? birthDate,
    String? occupation,
    String? phone,
  ) async {
    await sub.from("family_members").insert({
      "household_id": householdId,
      "full_name": fullName,
      "relationship": relationship,
      "gender": gender,
      // "birth_date": _d(birthDate),
      "occupation": occupation,
      "phone": phone,
    });
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(
    String householdId,
  ) async {
    return await sub
        .from("family_members")
        .select()
        .eq("household_id", householdId)
        .isFilter("deleted_at", null)
        .order("created_at");
  }

  Future<void> updateFamilyMember(
    String id,
    String fullName,
    String relationship,
    String gender,
    DateTime? birthDate,
    String? occupation,
    String? phone,
  ) async {
    await sub
        .from("family_members")
        .update({
          "full_name": fullName,
          "relationship": relationship,
          "gender": gender,
          // "birth_date": _d(birthDate),
          "occupation": occupation,
          "phone": phone,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("id", id);
  }

  // حذف ناعم
  Future<void> deleteFamilyMember(String id) async {
    await sub
        .from("family_members")
        .update({"deleted_at": DateTime.now().toIso8601String()})
        .eq("id", id);
  }

  Future<void> createIdentityDocument(
    String? householdId,
    String? familyMemberId,
    String documentType,
    String? documentNumber,
    String? storagePath,
  ) async {
    if ((householdId == null) == (familyMemberId == null)) {
      throw Exception("حدد أسرة أو فرد واحد فقط");
    }
    await sub.from("identity_documents").insert({
      "household_id": householdId,
      "family_member_id": familyMemberId,
      "document_type": documentType,
      "document_number": documentNumber,
      "storage_path": storagePath,
      "uploaded_by": _uid,
    });
  }

  Future<List<Map<String, dynamic>>> getIdentityDocuments({
    String? householdId,
    String? familyMemberId,
  }) async {
    var q = sub.from("identity_documents").select();
    if (householdId != null) q = q.eq("household_id", householdId);
    if (familyMemberId != null) q = q.eq("family_member_id", familyMemberId);
    return await q.order("created_at", ascending: false);
  }

  Future<void> updateIdentityDocument(
    String id,
    String documentType,
    String? documentNumber,
    String? storagePath,
  ) async {
    await sub
        .from("identity_documents")
        .update({
          "document_type": documentType,
          "document_number": documentNumber,
          "storage_path": storagePath,
        })
        .eq("id", id);
  }

  Future<void> deleteIdentityDocument(String id) async {
    await sub.from("identity_documents").delete().eq("id", id);
  }

  Future<void> createHouseholdResidency(
    String householdId,
    String residencyType,
    String? displacementSource,
    DateTime? moveDate,
    String? notes,
  ) async {
    await sub.from("household_residency").insert({
      "household_id": householdId,
      "residency_type": residencyType,
      "displacement_source": displacementSource,
      // "move_date": _d(moveDate),
      "notes": notes,
    });
  }

  Future<List<Map<String, dynamic>>> getHouseholdResidency(
    String householdId,
  ) async {
    return await sub
        .from("household_residency")
        .select()
        .eq("household_id", householdId)
        .order("created_at", ascending: false);
  }

  Future<void> updateHouseholdResidency(
    String id,
    String residencyType,
    String? displacementSource,
    DateTime? moveDate,
    String? notes,
  ) async {
    await sub
        .from("household_residency")
        .update({
          "residency_type": residencyType,
          "displacement_source": displacementSource,
          // "move_date": _d(moveDate),
          "notes": notes,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("id", id);
  }

  Future<void> deleteHouseholdResidency(String id) async {
    await sub.from("household_residency").delete().eq("id", id);
  }

  // =====================================================
  // 8) attachments
  // scan_status: pending | clean | rejected | error
  // =====================================================

  Future<void> createAttachment(
    String? householdId,
    String? familyMemberId,
    String storagePath,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
  ) async {
    if (householdId == null && familyMemberId == null) {
      throw Exception("حدد أسرة أو فرد للمرفق");
    }
    await sub.from("attachments").insert({
      "household_id": householdId,
      "family_member_id": familyMemberId,
      "storage_path": storagePath,
      "file_name": fileName,
      "mime_type": mimeType,
      "file_size_bytes": fileSizeBytes,
      "uploaded_by": _uid,
    });
  }

  Future<List<Map<String, dynamic>>> getAttachments({
    String? householdId,
    String? familyMemberId,
  }) async {
    var q = sub.from("attachments").select();
    if (householdId != null) q = q.eq("household_id", householdId);
    if (familyMemberId != null) q = q.eq("family_member_id", familyMemberId);
    return await q.order("created_at", ascending: false);
  }

  Future<void> updateAttachmentScanStatus(String id, String scanStatus) async {
    await sub
        .from("attachments")
        .update({"scan_status": scanStatus})
        .eq("id", id);
  }

  Future<void> deleteAttachment(String id) async {
    await sub.from("attachments").delete().eq("id", id);
  }

  // =====================================================
  // 9) audit_logs
  // =====================================================

  Future<void> createAuditLog(
    String action,
    String tableName,
    String? recordId,
    Map<String, dynamic> changeSummary,
  ) async {
    await sub.from("audit_logs").insert({
      "user_id": _uid,
      "action": action,
      "table_name": tableName,
      "record_id": recordId,
      "change_summary": changeSummary,
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? tableName,
    String? recordId,
    String? userId,
    int from = 0,
    int to = 49,
  }) async {
    var q = sub.from("audit_logs").select();
    if (tableName != null) q = q.eq("table_name", tableName);
    if (recordId != null) q = q.eq("record_id", recordId);
    if (userId != null) q = q.eq("user_id", userId);
    return await q.order("created_at", ascending: false).range(from, to);
  }
}





// String? _d(DateTime? d) => d?.toIso8601String().substring(0, 10);



// Future<List<Map<String, dynamic>>> getProfiles() async {
//   return await sub.from("profiles").select().order("created_at");
// }

// Future<Map<String, dynamic>?> getProfileById(String userId) async {
//   return await sub.from("profiles").select().eq("user_id", userId).maybeSingle();
// }

// Future<Map<String, dynamic>?> getMyProfile() async => getProfileById(_uid);

// Future<void> updateProfile(
//   String userId,
//   String fullName,
//   String role,
//   bool isActive,
// ) async {
//   await sub.from("profiles").update({
//     "full_name": fullName,
//     "role": role,
//     "is_active": isActive,
//     "updated_at": DateTime.now().toIso8601String(),
//   }).eq("user_id", userId);
// }

// // =====================================================
// // 2) neighborhoods
// // =====================================================







// // =====================================================
// // 3) researcher_neighborhoods
// // =====================================================



// Future<List<Map<String, dynamic>>> getResearcherNeighborhoods(
//     String researcherId) async {
//   return await sub
//       .from("researcher_neighborhoods")
//       .select("*, neighborhoods(*)")
//       .eq("researcher_id", researcherId)
//       .order("assigned_from", ascending: false);
// }

// Future<void> endAssignment(String id) async {
//   await sub
//       .from("researcher_neighborhoods")
//       .update({"assigned_to": _d(DateTime.now())}).eq("id", id);
// }

// Future<void> deleteAssignment(String id) async {
//   await sub.from("researcher_neighborhoods").delete().eq("id", id);
// }

// // =====================================================
// // 4) households  (total_count محسوب تلقائيا، لا يتم إدخاله)
// // =====================================================



// Future<List<Map<String, dynamic>>> searchHouseholdsByHeadName(String text) async {
//   return await sub
//       .from("households")
//       .select()
//       .isFilter("deleted_at", null)
//       .ilike("head_name", "%$text%")
//       .limit(50);
// }

// // currentVersion = رقم النسخة التي قرأتها (لمنع تعارض التعديل)
// Future<void> updateHousehold(
//   String id,
//   int currentVersion,
//   String neighborhoodId,
//   String headName,
//   String? householdNumber,
//   String? spouseName,
//   String? phone,
//   String? occupation,
//   String? employer,
//   String? housingType,
//   int malesCount,
//   int femalesCount,
//   String? notes,
// ) async {
//   final res = await sub
//       .from("households")
//       .update({
//         "household_number": householdNumber,
//         "neighborhood_id": neighborhoodId,
//         "head_name": headName,
//         "spouse_name": spouseName,
//         "phone": phone,
//         "occupation": occupation,
//         "employer": employer,
//         "housing_type": housingType,
//         "males_count": malesCount,
//         "females_count": femalesCount,
//         "notes": notes,
//         "updated_by": _uid,
//         "version": currentVersion + 1,
//         "updated_at": DateTime.now().toIso8601String(),
//       })
//       .eq("id", id)
//       .eq("version", currentVersion)
//       .select();
//   if (res.isEmpty) {
//     throw Exception("تم تعديل السجل من مستخدم آخر، أعد تحميل البيانات");
//   }
// }

// // حذف ناعم
// Future<void> deleteHousehold(String id) async {
//   await sub.from("households").update({
//     "deleted_at": DateTime.now().toIso8601String(),
//     "updated_by": _uid,
//   }).eq("id", id);
// }

// // =====================================================
// // 5) family_members
// // relationship: head | spouse | son | daughter | father | mother | brother | sister | other
// // gender: male | female
// // =====================================================



// // =====================================================
// // 6) identity_documents
// // مالك واحد فقط: householdId أو familyMemberId
// // document_type: national_id | passport | birth_certificate | other
// // =====================================================


