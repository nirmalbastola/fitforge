import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'core/services/widget_service.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'router/app_router.dart';

class FitForgeApp extends ConsumerStatefulWidget {
  const FitForgeApp({super.key});

  @override
  ConsumerState<FitForgeApp> createState() => _FitForgeAppState();
}

class _FitForgeAppState extends ConsumerState<FitForgeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wireWidgetLaunch();
    _initialRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetService.refresh(ref.read(dbProvider));
    }
  }

  Future<void> _initialRefresh() async {
    final db = ref.read(dbProvider);
    await WidgetService.refresh(db);
  }

  Future<void> _wireWidgetLaunch() async {
    if (!_isAndroid) return;
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _handleUri(initialUri);
    HomeWidget.widgetClicked.listen(_handleUri);
  }

  void _handleUri(Uri? uri) async {
    if (uri == null) return;
    final router = ref.read(routerProvider);
    if (uri.host == 'start-workout') {
      final db = ref.read(dbProvider);
      final id = await db.workoutDao.startWorkout();
      router.push('/workout/$id');
    } else if (uri.host == 'history') {
      router.push('/history');
    }
  }

  bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android && !kIsWeb;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FitForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
