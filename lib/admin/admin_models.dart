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
