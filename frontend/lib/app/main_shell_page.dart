import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/budget/data/repositories/budget_repository.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/expenses/data/mock_expense_repository.dart';
import '../features/expenses/presentation/screens/history_screen.dart';
import '../features/expenses/presentation/widgets/voice_assistant_bottom_sheet.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'app_root.dart';
import 'theme/app_colors.dart';

class MainShellPage extends StatefulWidget {
  final int initialIndex;
  const MainShellPage({super.key, this.initialIndex = 0});

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainShellPageState>();
    if (state != null) {
      state.onTabChanged(index);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainShellPage(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    MockExpenseRepository.instance.fetchBackendExpenses();
    BudgetRepository.instance.fetchCurrentBudget();
  }

  List<Widget> get pages => const [
        DashboardScreen(),
        HistoryScreen(),
        ReportsScreen(),
        SettingsScreen(),
      ];

  void onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AppRoot()),
              (route) => false,
            );
          }
        },
        child: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
        onVoiceTap: () => VoiceAssistantBottomSheet.show(context),
      ),
    );
  }
}

typedef MainShellScreen = MainShellPage;
