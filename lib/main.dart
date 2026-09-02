import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'constants/app_strings.dart';
import 'constants/app_theme.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/forgot_password/create_new_password_view.dart';
import 'views/forgot_password/forgot_password_view.dart';
import 'views/forgot_password/otp_verification_view.dart';
import 'views/login_view.dart';
import 'views/notification/notification_view.dart';
import 'views/profile/profile_view.dart';
import 'views/register_view.dart';
import 'views/reminder/add_reminder_view.dart';
import 'views/tracking/tracking_view.dart';
import 'views/tracking/vehicle_detail_map_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AirotrackApp());
}

class AirotrackApp extends StatelessWidget {
  const AirotrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const LoginView(),
      ),
      getPages: [
        GetPage(name: '/', page: () => const LoginView()),
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/register', page: () => const RegisterView()),
        GetPage(name: '/forgot-password', page: () => const ForgotPasswordView()),
        GetPage(name: '/ForgotPasswordView', page: () => const ForgotPasswordView()),
        GetPage(name: '/otp-verification', page: () => const OtpVerificationView()),
        GetPage(name: '/OtpVerificationView', page: () => const OtpVerificationView()),
        GetPage(name: '/create-new-password', page: () => const CreateNewPasswordView()),
        GetPage(name: '/CreateNewPasswordView', page: () => const CreateNewPasswordView()),
        GetPage(name: '/dashboard', page: () => const DashboardView()),
        GetPage(name: '/DashboardView', page: () => const DashboardView()),
        GetPage(name: '/tracking', page: () => const TrackingView()),
        GetPage(name: '/TrackingView', page: () => const TrackingView()),
        GetPage(name: '/notification', page: () => const NotificationView()),
        GetPage(name: '/NotificationView', page: () => const NotificationView()),
        GetPage(name: '/vehicle-detail-map', page: () => const VehicleDetailMapView()),
        GetPage(name: '/VehicleDetailMapView', page: () => const VehicleDetailMapView()),
        GetPage(name: '/profile', page: () => const ProfileView()),
        GetPage(name: '/ProfileView', page: () => const ProfileView()),
        GetPage(name: '/add-reminder', page: () => const AddReminderView()),
        GetPage(name: '/AddReminderView', page: () => const AddReminderView()),
      ],
    );
  }
}
