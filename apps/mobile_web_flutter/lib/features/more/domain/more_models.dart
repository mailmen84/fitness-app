import '../../../core/serialization/json_parsing.dart';

String _formatAmount(double amount) {
  if (amount.truncateToDouble() == amount) {
    return amount.toStringAsFixed(0);
  }

  return amount
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _titleize(String value) {
  final normalized = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (normalized.isEmpty) {
    return value;
  }

  return normalized
      .split(RegExp(r'\s+'))
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _goalCodeLabel(String code) {
  return switch (code) {
    'cut' => 'Cut',
    'maintain' => 'Maintain',
    'gain' => 'Gain',
    'performance' => 'Performance',
    _ => _titleize(code),
  };
}

String _unitSystemLabel(String value) {
  return switch (value) {
    'metric' => 'Metric',
    'imperial' => 'Imperial',
    _ => _titleize(value),
  };
}

String _weekStartsOnLabel(String value) {
  return switch (value) {
    'monday' => 'Monday',
    'sunday' => 'Sunday',
    _ => _titleize(value),
  };
}

class MoreUserProfile {
  const MoreUserProfile({
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.heightCm,
    required this.bio,
  });

  final String? displayName;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final double? heightCm;
  final String? bio;

  bool get isEmpty =>
      (displayName == null || displayName!.trim().isEmpty) &&
      (firstName == null || firstName!.trim().isEmpty) &&
      (lastName == null || lastName!.trim().isEmpty) &&
      birthDate == null &&
      heightCm == null &&
      (bio == null || bio!.trim().isEmpty);

  String? get fullName {
    final parts = [
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' ');
  }

  String? get heightLabel {
    if (heightCm == null) {
      return null;
    }
    return '${_formatAmount(heightCm!)} cm';
  }

  factory MoreUserProfile.fromJson(Map<String, dynamic> json) {
    return MoreUserProfile(
      displayName: json['display_name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      heightCm: json['height_cm'] == null
          ? null
          : jsonToDouble(json['height_cm']),
      bio: json['bio'] as String?,
    );
  }
}

class CurrentUserData {
  const CurrentUserData({
    required this.id,
    required this.email,
    required this.isActive,
    required this.profile,
  });

  final String id;
  final String email;
  final bool isActive;
  final MoreUserProfile? profile;

  String get displayName {
    final profileName = profile?.displayName?.trim();
    if (profileName != null && profileName.isNotEmpty) {
      return profileName;
    }

    final localPart = email.split('@').first.trim();
    return localPart.isEmpty ? 'Preview User' : _titleize(localPart);
  }

  String get initials {
    final source = profile?.fullName ?? displayName;
    final parts = source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final letters = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return letters.isEmpty ? 'PU' : letters;
  }

  factory CurrentUserData.fromJson(Map<String, dynamic> json) {
    return CurrentUserData(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      profile: json['profile'] == null
          ? null
          : MoreUserProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }
}

class CurrentGoalData {
  const CurrentGoalData({
    required this.id,
    required this.code,
    required this.title,
    required this.targetValue,
    required this.targetUnit,
    required this.startsOn,
    required this.endsOn,
    required this.notes,
  });

  final String id;
  final String code;
  final String title;
  final double? targetValue;
  final String? targetUnit;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final String? notes;

  String get codeLabel => _goalCodeLabel(code);

  String? get targetLabel {
    if (targetValue == null || targetUnit == null || targetUnit!.isEmpty) {
      return null;
    }
    return '${_formatAmount(targetValue!)} $targetUnit';
  }

  factory CurrentGoalData.fromJson(Map<String, dynamic> json) {
    return CurrentGoalData(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? 'Goal',
      targetValue: json['target_value'] == null
          ? null
          : jsonToDouble(json['target_value']),
      targetUnit: json['target_unit'] as String?,
      startsOn: json['starts_on'] == null
          ? null
          : DateTime.parse(json['starts_on'] as String),
      endsOn: json['ends_on'] == null
          ? null
          : DateTime.parse(json['ends_on'] as String),
      notes: json['notes'] as String?,
    );
  }
}

class PreferenceData {
  const PreferenceData({
    required this.id,
    required this.userId,
    required this.unitSystem,
    required this.timezone,
    required this.weekStartsOn,
    required this.dailyCalorieTarget,
    required this.dailyProteinTarget,
    required this.dailyCarbsTarget,
    required this.dailyFatTarget,
    required this.onboardingCompleted,
  });

  final String id;
  final String userId;
  final String unitSystem;
  final String timezone;
  final String weekStartsOn;
  final double? dailyCalorieTarget;
  final double? dailyProteinTarget;
  final double? dailyCarbsTarget;
  final double? dailyFatTarget;
  final bool onboardingCompleted;

  String get unitSystemLabel => _unitSystemLabel(unitSystem);
  String get weekStartsOnLabel => _weekStartsOnLabel(weekStartsOn);

  String? get dailyCalorieTargetLabel {
    if (dailyCalorieTarget == null) {
      return null;
    }
    return '${_formatAmount(dailyCalorieTarget!)} kcal';
  }

  String? get dailyProteinTargetLabel {
    if (dailyProteinTarget == null) {
      return null;
    }
    return '${_formatAmount(dailyProteinTarget!)} g';
  }

  String? get dailyCarbsTargetLabel {
    if (dailyCarbsTarget == null) {
      return null;
    }
    return '${_formatAmount(dailyCarbsTarget!)} g';
  }

  String? get dailyFatTargetLabel {
    if (dailyFatTarget == null) {
      return null;
    }
    return '${_formatAmount(dailyFatTarget!)} g';
  }

  factory PreferenceData.fromJson(Map<String, dynamic> json) {
    return PreferenceData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      unitSystem: json['unit_system'] as String? ?? 'metric',
      timezone: json['timezone'] as String? ?? 'UTC',
      weekStartsOn: json['week_starts_on'] as String? ?? 'monday',
      dailyCalorieTarget: json['daily_calorie_target'] == null
          ? null
          : jsonToDouble(json['daily_calorie_target']),
      dailyProteinTarget: json['daily_protein_target'] == null
          ? null
          : jsonToDouble(json['daily_protein_target']),
      dailyCarbsTarget: json['daily_carbs_target'] == null
          ? null
          : jsonToDouble(json['daily_carbs_target']),
      dailyFatTarget: json['daily_fat_target'] == null
          ? null
          : jsonToDouble(json['daily_fat_target']),
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }
}