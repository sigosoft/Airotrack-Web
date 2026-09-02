class LoginModel {
  String countryCode;
  String phoneNumber;
  String password;
  bool rememberMe;

  LoginModel({
    this.countryCode = '+ 91',
    this.phoneNumber = '',
    this.password = '',
    this.rememberMe = false,
  });

  /// Full phone number getter
  String get fullPhoneNumber => '$countryCode$phoneNumber';

  /// Validates if phone number meets 10 digit requirement
  bool get isPhoneValid {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.length >= 10;
  }

  /// Validates password length requirement
  bool get isPasswordValid => password.length >= 6;

  /// Validates overall form submission
  bool get isValid => isPhoneValid && isPasswordValid;

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'password': password,
        'rememberMe': rememberMe,
      };

  factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
        countryCode: json['countryCode'] ?? '+ 91',
        phoneNumber: json['phoneNumber'] ?? '',
        password: json['password'] ?? '',
        rememberMe: json['rememberMe'] ?? false,
      );
}
