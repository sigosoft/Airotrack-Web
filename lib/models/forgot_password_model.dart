class ForgotPasswordModel {
  String countryCode;
  String phoneNumber;
  String otpCode;
  String newPassword;
  String confirmPassword;

  ForgotPasswordModel({
    this.countryCode = '+ 91',
    this.phoneNumber = '',
    this.otpCode = '',
    this.newPassword = '',
    this.confirmPassword = '',
  });

  String get fullPhoneNumber => '$countryCode$phoneNumber';

  bool get isPhoneValid {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.length >= 10;
  }

  bool get isOtpValid {
    final cleanOtp = otpCode.replaceAll(RegExp(r'\D'), '');
    return cleanOtp.length >= 4;
  }

  bool get isNewPasswordValid => newPassword.length >= 6;

  bool get isConfirmPasswordValid =>
      confirmPassword.isNotEmpty && confirmPassword == newPassword;
}
