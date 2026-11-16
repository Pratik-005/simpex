class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String currency;
  final String locale;
  final String authProvider;
  final String? avatarUrl;
  final String? phone;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.currency = 'INR',
    this.locale = 'en_IN',
    this.authProvider = 'email',
    this.avatarUrl,
    this.phone,
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      currency: json['currency'] as String? ?? 'INR',
      locale: json['locale'] as String? ?? 'en_IN',
      authProvider: json['authProvider'] as String? ?? 'email',
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'currency': currency,
    'locale': locale,
    'authProvider': authProvider,
    'avatarUrl': avatarUrl,
    'phone': phone,
    'onboardingCompleted': onboardingCompleted,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  AuthUser copyWith({
    String? name,
    String? currency,
    String? locale,
    String? avatarUrl,
    String? phone,
    bool? onboardingCompleted,
  }) {
    return AuthUser(
      id: id,
      email: email,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      authProvider: authProvider,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AuthResult {
  final AuthUser user;
  final AuthTokens tokens;

  const AuthResult({required this.user, required this.tokens});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      tokens: AuthTokens.fromJson(
        json['tokens'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
