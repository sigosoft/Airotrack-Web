class UserProfile {
  final String name;
  final String phoneNumber;
  final String avatarUrl;

  UserProfile({
    this.name = 'John Doe',
    this.phoneNumber = '+91 91234 56789',
    this.avatarUrl = '',
  });
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

  ProfileModel({
    required this.user,
    required this.generalSettings,
  });
}
