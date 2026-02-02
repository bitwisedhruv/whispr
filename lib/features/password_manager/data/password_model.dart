class PasswordModel {
  final String? id;
  final String userId;
  final String title;
  final String? websiteUrl;
  final String usernameEncrypted;
  final String passwordEncrypted;
  final String? notesEncrypted;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PasswordModel({
    this.id,
    required this.userId,
    required this.title,
    this.websiteUrl,
    required this.usernameEncrypted,
    required this.passwordEncrypted,
    this.notesEncrypted,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory PasswordModel.fromJson(Map<String, dynamic> json) {
    return PasswordModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      websiteUrl: json['website_url'],
      usernameEncrypted: json['username_encrypted'],
      passwordEncrypted: json['password_encrypted'],
      notesEncrypted: json['notes_encrypted'],
      category: json['category'],
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
      'title': title,
      'website_url': websiteUrl,
      'username_encrypted': usernameEncrypted,
      'password_encrypted': passwordEncrypted,
      'notes_encrypted': notesEncrypted,
      'category': category,
    };
  }

  PasswordModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? websiteUrl,
    String? usernameEncrypted,
    String? passwordEncrypted,
    String? notesEncrypted,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      usernameEncrypted: usernameEncrypted ?? this.usernameEncrypted,
      passwordEncrypted: passwordEncrypted ?? this.passwordEncrypted,
      notesEncrypted: notesEncrypted ?? this.notesEncrypted,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
