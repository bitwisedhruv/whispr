class AuthenticatorModel {
  final String? id;
  final String userId;
  final String issuer;
  final String accountName;
  final String encryptedSecret;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthenticatorModel({
    this.id,
    required this.userId,
    required this.issuer,
    required this.accountName,
    required this.encryptedSecret,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthenticatorModel.fromJson(Map<String, dynamic> json) {
    return AuthenticatorModel(
      id: json['id'],
      userId: json['user_id'],
      issuer: json['issuer'],
      accountName: json['account_name'],
      encryptedSecret: json['encrypted_secret'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'issuer': issuer,
      'account_name': accountName,
      'encrypted_secret': encryptedSecret,
    };
  }

  AuthenticatorModel copyWith({
    String? id,
    String? userId,
    String? issuer,
    String? accountName,
    String? encryptedSecret,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthenticatorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      issuer: issuer ?? this.issuer,
      accountName: accountName ?? this.accountName,
      encryptedSecret: encryptedSecret ?? this.encryptedSecret,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
