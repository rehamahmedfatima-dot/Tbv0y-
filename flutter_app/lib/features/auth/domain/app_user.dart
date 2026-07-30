class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final bool onboardingCompleted;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.onboardingCompleted = false,
  });

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    bool? onboardingCompleted,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
