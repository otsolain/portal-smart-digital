import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/parent_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/student_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/teacher_dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/students/pages/students_list_page.dart';
import '../../features/subjects/presentation/pages/subjects_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/assignments/presentation/pages/assignments_page.dart';
import '../../features/exams/presentation/pages/exams_page.dart';
import '../../features/religious/presentation/pages/religious_activities_page.dart';
import '../../features/announcements/presentation/pages/announcements_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/attendance/presentation/pages/teacher_attendance_page.dart';
import '../../features/grades/presentation/pages/grade_management_page.dart';
import '../../shared/widgets/main_scaffold.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final path = state.uri.path;
      final isAuth = authState.status == AuthStatus.authenticated;
      final isInitial = authState.status == AuthStatus.initial;
      final isLoading = authState.status == AuthStatus.loading;

      if (isInitial || (isLoading && path == '/splash')) return null;
      if (!isAuth && path != '/login') return '/login';
      if (isAuth && (path == '/login' || path == '/splash')) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) {
              final role = ref.watch(currentUserRoleProvider);
              switch (role) {
                case UserRole.murid:
                  return const StudentDashboardPage();
                case UserRole.orangtua:
                  return const ParentDashboardPage();
                case UserRole.guru:
                  return const TeacherDashboardPage();
                default:
                  return const StudentDashboardPage();
              }
            },
          ),
          GoRoute(path: '/students', builder: (_, __) => const StudentsListPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(path: '/subjects', builder: (_, __) => const SubjectsPage()),
          GoRoute(path: '/attendance', builder: (_, __) => const AttendancePage()),
          GoRoute(path: '/assignments', builder: (_, __) => const AssignmentsPage()),
          GoRoute(path: '/exams', builder: (_, __) => const ExamsPage()),
          GoRoute(path: '/religious', builder: (_, __) => const ReligiousActivitiesPage()),
          GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsPage()),
          GoRoute(path: '/library', builder: (_, __) => const LibraryPage()),
          GoRoute(path: '/teacher-attendance', builder: (_, __) => const TeacherAttendancePage()),
          GoRoute(path: '/grades', builder: (_, __) => const GradeManagementPage()),
        ],
      ),
    ],
  );
});
