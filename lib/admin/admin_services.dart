import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_models.dart';

abstract interface class AdminSessionService {
  Stream<AdminIdentity?> get sessions;
  Future<void> signIn();
  Future<AdminIdentity?> refresh();
  Future<void> signOut();
}

class FirebaseAdminSessionService implements AdminSessionService {
  FirebaseAdminSessionService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  Future<AdminIdentity?> _identity(User? user, {bool force = false}) async {
    if (user == null) return null;
    final result = await user.getIdTokenResult(force);
    return AdminIdentity(
      uid: user.uid,
      email: user.email,
      isAdmin: result.claims?['admin'] == true,
    );
  }

  // Do not force-refresh in this listener: refreshing emits idTokenChanges.
  @override
  Stream<AdminIdentity?> get sessions =>
      _auth.idTokenChanges().asyncMap(_identity);
  @override
  Future<void> signIn() async {
    await _auth.signInWithPopup(GoogleAuthProvider());
  }

  @override
  Future<AdminIdentity?> refresh() => _identity(_auth.currentUser, force: true);
  @override
  Future<void> signOut() => _auth.signOut();
}

abstract interface class AdminUserService {
  Future<AdminUserPage> list({String? pageToken, String? query});
  Future<AdminUserDetails> details(String uid);
  Future<AdminActionResult> setDisabled(String uid, bool disabled);
  Future<AdminActionResult> revokeSessions(String uid);
  Future<AdminActionResult> updateDisplayName(String uid, String displayName);
  Future<AdminAuditPage> auditLogs({String? pageToken, String? targetUid});
  Future<AdminJournalPage> journal(String uid, {String? pageToken});
  Future<AdminStatistics> statistics();
}

class FirebaseAdminUserService implements AdminUserService {
  FirebaseAdminUserService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  final FirebaseFunctions _functions;

  @override
  Future<AdminJournalPage> journal(String uid, {String? pageToken}) async {
    final data = await _call('adminGetUserJournal', {
      'uid': uid,
      'pageSize': 20,
      'pageToken': ?pageToken,
    });
    return AdminJournalPage(
      meals: (data['meals'] as List)
          .map(
            (item) => AdminJournalMeal.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  @override
  Future<AdminStatistics> statistics() async =>
      AdminStatistics.fromMap(await _call('adminGetStatistics', {}));

  @override
  Future<AdminActionResult> updateDisplayName(
    String uid,
    String displayName,
  ) async {
    final data = await _call('adminUpdateDisplayName', {
      'uid': uid,
      'displayName': displayName,
    });
    return AdminActionResult(auditWarning: data['auditWarning'] == true);
  }

  @override
  Future<AdminAuditPage> auditLogs({
    String? pageToken,
    String? targetUid,
  }) async {
    final data = await _call('adminListAuditLogs', {
      'pageSize': 25,
      'pageToken': ?pageToken,
      'targetUid': ?targetUid,
    });
    return AdminAuditPage(
      order: data['order'] as String? ?? 'newest',
      logs: (data['logs'] as List)
          .map(
            (item) =>
                AdminAuditEntry.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object> data,
  ) async {
    try {
      final response = await _functions.httpsCallable(name).call<Object?>(data);
      return Map<String, dynamic>.from(response.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw AdminApiException(error.code);
    }
  }

  @override
  Future<AdminUserPage> list({String? pageToken, String? query}) async {
    final data = await _call('adminListUsers', {
      'pageSize': 25,
      'pageToken': ?pageToken,
      if (query?.isNotEmpty == true) 'query': query!,
    });
    return AdminUserPage(
      users: (data['users'] as List)
          .map(
            (item) => AdminUser.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  @override
  Future<AdminUserDetails> details(String uid) async {
    final data = await _call('adminGetUser', {'uid': uid});
    final activity = Map<String, dynamic>.from(data['activity'] as Map);
    return AdminUserDetails(
      user: AdminUser.fromMap(Map<String, dynamic>.from(data['user'] as Map)),
      profile: data['profile'] == null
          ? null
          : Map<String, dynamic>.from(data['profile'] as Map),
      mealCount: (activity['mealCount'] as num).toInt(),
      readLessonCount: (activity['readLessonCount'] as num).toInt(),
    );
  }

  @override
  Future<AdminActionResult> setDisabled(String uid, bool disabled) async {
    final data = await _call('adminSetUserDisabled', {
      'uid': uid,
      'disabled': disabled,
    });
    return AdminActionResult(auditWarning: data['auditWarning'] == true);
  }

  @override
  Future<AdminActionResult> revokeSessions(String uid) async {
    final data = await _call('adminRevokeUserSessions', {'uid': uid});
    return AdminActionResult(auditWarning: data['auditWarning'] == true);
  }
}
