class RegisterModel {
  String name;
  String countryCode;
  String phoneNumber;
  String password;
  String confirmPassword;

  RegisterModel({
    this.name = '',
    this.countryCode = '+ 91',
    this.phoneNumber = '',
    this.password = '',
    this.confirmPassword = '',
  });

  /// Full phone number getter
  String get fullPhoneNumber => '$countryCode$phoneNumber';

  /// Validates name presence
  bool get isNameValid => name.trim().isNotEmpty;

  /// Validates phone length
  bool get isPhoneValid {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.length >= 10;
  }

  /// Validates password length
  bool get isPasswordValid => password.length >= 6;

  /// Validates password confirmation match
  bool get isConfirmPasswordValid =>
      confirmPassword.isNotEmpty && confirmPassword == password;

  /// Validates overall form completion
  bool get isValid =>
      isNameValid && isPhoneValid && isPasswordValid && isConfirmPasswordValid;

  Map<String, dynamic> toJson() => {
        'name': name,
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
      };

  factory RegisterModel.fromJson(Map<String, dynamic> json) => RegisterModel(
        name: json['name'] ?? '',
        countryCode: json['countryCode'] ?? '+ 91',
        phoneNumber: json['phoneNumber'] ?? '',
        password: json['password'] ?? '',
        confirmPassword: json['confirmPassword'] ?? '',
      );
}
