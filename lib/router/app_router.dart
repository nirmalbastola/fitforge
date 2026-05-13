import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/exercises/add_exercise_screen.dart';
import '../features/exercises/exercise_picker_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/workout_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/checkin/checkin_screen.dart';
import '../features/plans/plan_editor_screen.dart';
import '../features/plans/plans_list_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/workout/workout_session_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/workout/:id',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return WorkoutSessionScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/exercises/picker',
        builder: (ctx, state) => const ExercisePickerScreen(),
      ),
      GoRoute(
        path: '/exercises/new',
        builder: (ctx, state) => const AddExerciseScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (ctx, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return WorkoutDetailScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/progress',
        builder: (ctx, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (ctx, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/checkin',
        builder: (ctx, state) => const CheckInScreen(),
      ),
      GoRoute(
        path: '/plans',
        builder: (ctx, state) => const PlansListScreen(),
      ),
      GoRoute(
        path: '/plans/:id',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PlanEditorScreen(planId: id);
        },
      ),
    ],
  );
});
