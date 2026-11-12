class AdminIdentity {
  const AdminIdentity({required this.uid, required this.isAdmin, this.email});
  final String uid;
  final String? email;
  final bool isAdmin;
}

class AdminUser {
  const AdminUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.disabled = false,
    this.emailVerified = false,
    this.isAdmin = false,
    this.createdAt,
    this.lastSignInAt,
  });

  factory AdminUser.fromMap(Map<String, dynamic> data) => AdminUser(
    uid: data['uid'] as String,
    email: data['email'] as String?,
    displayName: data['displayName'] as String?,
    photoUrl: data['photoUrl'] as String?,
    disabled: data['disabled'] == true,
    emailVerified: data['emailVerified'] == true,
    isAdmin: data['isAdmin'] == true,
    createdAt: data['createdAt'] as String?,
    lastSignInAt: data['lastSignInAt'] as String?,
  );

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool disabled;
  final bool emailVerified;
  final bool isAdmin;
  final String? createdAt;
  final String? lastSignInAt;

  String get label =>
      displayName?.trim().isNotEmpty == true ? displayName! : email ?? uid;
}

class AdminUserPage {
  const AdminUserPage({required this.users, this.nextPageToken});
  final List<AdminUser> users;
  final String? nextPageToken;
}

class AdminUserDetails {
  const AdminUserDetails({
    required this.user,
    required this.mealCount,
    required this.readLessonCount,
    this.profile,
  });
  final AdminUser user;
  final Map<String, dynamic>? profile;
  final int mealCount;
  final int readLessonCount;
}

class AdminActionResult {
  const AdminActionResult({this.auditWarning = false});
  final bool auditWarning;
}

class AdminAuditEntry {
  const AdminAuditEntry({
    required this.id,
    required this.actorUid,
    required this.targetUid,
    required this.action,
    required this.status,
    this.createdAt,
    this.completedAt,
  });

  factory AdminAuditEntry.fromMap(Map<String, dynamic> data) => AdminAuditEntry(
    id: data['id'] as String,
    actorUid: data['actorUid'] as String,
    targetUid: data['targetUid'] as String,
    action: data['action'] as String,
    status: data['status'] as String,
    createdAt: data['createdAt'] as String?,
    completedAt: data['completedAt'] as String?,
  );

  final String id;
  final String actorUid;
  final String targetUid;
  final String action;
  final String status;
  final String? createdAt;
  final String? completedAt;
}

class AdminAuditPage {
  const AdminAuditPage({
    required this.logs,
    this.nextPageToken,
    this.order = 'newest',
  });
  final List<AdminAuditEntry> logs;
  final String? nextPageToken;
  final String order;
}

class AdminJournalMeal {
  const AdminJournalMeal({
    required this.id,
    required this.name,
    required this.mealType,
    required this.eatenAt,
    required this.notes,
    required this.ingredientCount,
  });
  factory AdminJournalMeal.fromMap(Map<String, dynamic> data) =>
      AdminJournalMeal(
        id: data['id'] as String,
        name: data['name'] as String,
        mealType: data['mealType'] as String,
        eatenAt: data['eatenAt'] as String,
        notes: data['notes'] as String,
        ingredientCount: (data['ingredientCount'] as num).toInt(),
      );
  final String id;
  final String name;
  final String mealType;
  final String eatenAt;
  final String notes;
  final int ingredientCount;
}

class AdminJournalPage {
  const AdminJournalPage({required this.meals, this.nextPageToken});
  final List<AdminJournalMeal> meals;
  final String? nextPageToken;
}

class AdminStatistics {
  const AdminStatistics({
    required this.scannedUsers,
    required this.isComplete,
    required this.active,
    required this.disabled,
    required this.admins,
    required this.verified,
    required this.newUsers7d,
    required this.newUsers30d,
    required this.signedIn7d,
    required this.signedIn30d,
    required this.generatedAt,
  });
  factory AdminStatistics.fromMap(Map<String, dynamic> data) => AdminStatistics(
    scannedUsers: (data['scannedUsers'] as num).toInt(),
    isComplete: data['isComplete'] == true,
    active: (data['active'] as num).toInt(),
    disabled: (data['disabled'] as num).toInt(),
    admins: (data['admins'] as num).toInt(),
    verified: (data['verified'] as num).toInt(),
    newUsers7d: (data['newUsers7d'] as num).toInt(),
    newUsers30d: (data['newUsers30d'] as num).toInt(),
    signedIn7d: (data['signedIn7d'] as num).toInt(),
    signedIn30d: (data['signedIn30d'] as num).toInt(),
    generatedAt: data['generatedAt'] as String,
  );
  final int scannedUsers;
  final bool isComplete;
  final int active;
  final int disabled;
  final int admins;
  final int verified;
  final int newUsers7d;
  final int newUsers30d;
  final int signedIn7d;
  final int signedIn30d;
  final String generatedAt;
}

class AdminApiException implements Exception {
  const AdminApiException(this.code);
  final String code;

  bool get isForbidden =>
      code == 'permission-denied' || code == 'unauthenticated';

  String get message => switch (code) {
    'permission-denied' =>
      'Quyền quản trị không còn hiệu lực. Vui lòng kiểm tra lại quyền.',
    'unauthenticated' =>
      'Phiên đăng nhập hết hiệu lực. Vui lòng đăng nhập lại.',
    'not-found' =>
      'Không tìm thấy người dùng hoặc API quản trị chưa được triển khai.',
    'invalid-argument' => 'Thông tin tìm kiếm hoặc yêu cầu chưa hợp lệ.',
    'failed-precondition' =>
      'Không thể thao tác với tài khoản này ở trạng thái hiện tại.',
    'resource-exhausted' => 'Quá nhiều yêu cầu. Vui lòng thử lại sau.',
    _ => 'Chưa kết nối được dịch vụ quản trị. Kiểm tra mạng và thử lại.',
  };
}
