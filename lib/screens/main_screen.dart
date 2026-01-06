import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'member/member_home_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAdmin) {
          return const AdminDashboardScreen();
        } else {
          return const MemberHomeScreen();
        }
      },
    );
  }
}
