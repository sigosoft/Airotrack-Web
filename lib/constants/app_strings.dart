class AppStrings {
  AppStrings._();

  static const String appName = 'Airotrack';
  static const String hello = 'Hello!';
  
  // Login strings
  static const String pleaseSignIn = 'Please Sign In To Your Account';
  static const String enterPhoneNumber = 'Enter your phone number';
  static const String enterPassword = 'Enter your password';
  static const String forgotPassword = 'Forgot Password?';
  static const String signIn = 'Sign In';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String signUp = 'Sign Up';
  static const String defaultCountryCode = '+ 91';

  // Register strings
  static const String pleaseRegister = 'Please Register Your Account';
  static const String enterName = 'Enter your name';
  static const String enterConfirmPassword = 'Enter your confirm password';
  static const String register = 'Register';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String login = 'Login';
  
  // Forgot Password Step 1
  static const String forgotPasswordTitle = 'Forgot Password?';
  static const String forgotPasswordSubtitle = 'No worries! Enter your mobile number below.';
  static const String sendVerificationCode = 'Send Verification Code';

  // Forgot Password Step 2 (OTP)
  static const String otpTitle = 'OTP Verification';
  static const String otpSubtitle = 'Enter the verification code we just sent to your phone number.';
  static const String enterVerificationCode = 'Enter the verification code';
  static const String verify = 'Verify';

  // Forgot Password Step 3 (New Password)
  static const String createNewPasswordTitle = 'Create New Password';
  static const String createNewPasswordSubtitle = 'Enter a strong new password to secure your account.';
  static const String enterNewPassword = 'Enter your new password';
  static const String resetPassword = 'Reset Password';

  // Validation strings
  static const String emptyNameError = 'Please enter your name';
  static const String emptyPhoneError = 'Please enter your phone number';
  static const String invalidPhoneError = 'Please enter a valid 10-digit phone number';
  static const String emptyPasswordError = 'Please enter your password';
  static const String shortPasswordError = 'Password must be at least 6 characters';
  static const String emptyConfirmPasswordError = 'Please confirm your password';
  static const String passwordMismatchError = 'Passwords do not match';
  static const String emptyOtpError = 'Please enter the verification code';
  static const String invalidOtpError = 'Verification code must be 6 digits';
}
