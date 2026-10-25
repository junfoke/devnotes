import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/workspace/presentation/workspace_screen.dart';
import '../features/editor/presentation/editor_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/manage_collections_screen.dart';
import '../features/git_sync/presentation/git_setup_screen.dart';
import '../features/git_sync/presentation/conflict_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/onboarding_git_screen.dart';
import '../features/onboarding/presentation/onboarding_first_note_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarding_complete') ?? false;
      if (!onboarded && !state.matchedLocation.startsWith('/onboarding')) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const WorkspaceScreen(),
      ),
      GoRoute(
        path: '/editor/:filePath',
        builder: (_, state) => EditorScreen(
          filePath: Uri.decodeComponent(state.pathParameters['filePath']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/git',
        builder: (_, __) => const GitSetupScreen(),
      ),
      GoRoute(
        path: '/settings/collections',
        builder: (_, __) => const ManageCollectionsScreen(),
      ),
      GoRoute(
        path: '/conflict/:filePath',
        builder: (_, state) => ConflictScreen(
          filePath: Uri.decodeComponent(state.pathParameters['filePath']!),
          oursName: state.uri.queryParameters['ours'] ?? 'máy này',
          theirsName: state.uri.queryParameters['theirs'] ?? 'remote',
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/git',
        builder: (_, __) => const OnboardingGitScreen(),
      ),
      GoRoute(
        path: '/onboarding/first-note',
        builder: (_, __) => const OnboardingFirstNoteScreen(),
      ),
    ],
  );
});
