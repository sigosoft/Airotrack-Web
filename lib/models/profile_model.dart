class UserProfile {
  final String name;
  final String phoneNumber;
  final String avatarUrl;
  final String companyName;

  UserProfile({
    this.name = '',
    this.phoneNumber = '',
    this.avatarUrl = '',
    this.companyName = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final nameVal =
        json['name']?.toString() ??
        json['username']?.toString() ??
        json['user_name']?.toString() ??
        json['full_name']?.toString() ??
        json['first_name']?.toString() ??
        '';

    final phoneVal =
        json['phoneNumber']?.toString() ??
        json['phone_number']?.toString() ??
        json['phone']?.toString() ??
        json['mobile']?.toString() ??
        json['mobile_number']?.toString() ??
        '';

    final avatarVal =
        json['avatarUrl']?.toString() ??
        json['avatar_url']?.toString() ??
        json['avatar']?.toString() ??
        json['image']?.toString() ??
        json['profile_image']?.toString() ??
        '';

    final companyVal =
        json['company_name']?.toString() ??
        json['companyName']?.toString() ??
        json['company']?.toString() ??
        '';

    return UserProfile(
      name: nameVal.isNotEmpty ? nameVal : 'User',
      phoneNumber: phoneVal.isNotEmpty ? phoneVal : 'N/A',
      avatarUrl: avatarVal,
      companyName: companyVal,
    );
  }
}

class GeneralSettingItem {
  final String title;
  final String iconType;
  final String selectedValue;

  GeneralSettingItem({
    required this.title,
    required this.iconType,
    required this.selectedValue,
  });
}

class ProfileModel {
  final UserProfile user;
  final List<GeneralSettingItem> generalSettings;

  ProfileModel({required this.user, required this.generalSettings});
}
