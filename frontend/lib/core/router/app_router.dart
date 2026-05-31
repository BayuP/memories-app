import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/demo/demo_flag.dart';
import 'package:memories_app/features/auth/presentation/pages/auth_page.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/checkin/presentation/pages/checkin_page.dart';
import 'package:memories_app/features/profile/presentation/pages/profile_page.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';
import 'package:memories_app/features/trips/presentation/pages/create_trip_page.dart';
import 'package:memories_app/features/trips/presentation/pages/home_page.dart';
import 'package:memories_app/features/trips/presentation/pages/itinerary_review_page.dart';
import 'package:memories_app/features/trips/presentation/pages/itinerary_summary_page.dart';
import 'package:memories_app/features/trips/presentation/pages/public_trip_page.dart';
import 'package:memories_app/features/trips/presentation/pages/trip_timeline_page.dart';

// Route name constants
abstract final class AppRoutes {
  static const String root = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String createTrip = '/trips/create';
  static const String tripDetail = '/trips/:id';
  static const String tripTimeline = '/trips/:id/timeline';
  static const String tripItineraryReview = '/trips/:id/itinerary-review';
  static const String checkinCreate = '/trips/:tripId/checkin/create';
  static const String checkinView = '/checkins/:id';
  static const String publicTrip = '/public/trips/:id';
  static const String profile = '/profile';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthStateListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.root,
    refreshListenable: authListenable,
    redirect: (context, state) async {
      // DEMO: immediately resolve to home when at root
      if (ref.read(demoModeProvider) && state.matchedLocation == AppRoutes.root) {
        return AppRoutes.home;
      }

      final authAsync = ref.read(authProvider);

      // Still loading — no redirect, let the loader show
      if (authAsync.isLoading || authAsync.hasError) return null;

      final authState = authAsync.value;
      if (authState == null) return null;

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isUnknown = authState.status == AuthStatus.unknown;

      // While status is unknown keep current location
      if (isUnknown) return null;

      // Always redirect away from root splash
      if (state.matchedLocation == AppRoutes.root) {
        return isAuthenticated ? AppRoutes.home : AppRoutes.auth;
      }

      final goingToAuth = state.matchedLocation == AppRoutes.auth;

      // Public routes — no auth required
      final isPublicRoute =
          state.matchedLocation.startsWith('/public/trips/');

      if (!isAuthenticated && !goingToAuth && !isPublicRoute) {
        return AppRoutes.auth;
      }
      if (isAuthenticated && goingToAuth) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const _SplashRedirectPage(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.createTrip,
        builder: (context, state) => const CreateTripPage(),
      ),
      GoRoute(
        path: '/trips/:id/itinerary-review',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          final items = extra?['items'] as List<ItineraryItemEntity>? ?? [];
          final aiEnabled = extra?['aiEnabled'] as bool? ?? true;
          return ItineraryReviewPage(
            tripId: tripId,
            initialItems: items,
            aiEnabled: aiEnabled,
          );
        },
      ),
      GoRoute(
        path: '/trips/:id/itinerary-summary',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          return ItinerarySummaryPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.tripTimeline,
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          return TripTimelinePage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.tripDetail,
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          return TripTimelinePage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.checkinCreate,
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final queryParams = state.uri.queryParameters;
          final itemId = queryParams['itemId'];
          final kind = queryParams['kind'] ?? 'planned';
          return CheckinPage(
            tripId: tripId,
            itemId: itemId,
            kind: kind,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.checkinView,
        builder: (context, state) {
          final checkinId = state.pathParameters['id']!;
          // checkin view/edit — tripId is passed via extra or query param
          final queryParams = state.uri.queryParameters;
          final tripId = queryParams['tripId'] ?? '';
          return CheckinPage(
            tripId: tripId,
            checkinId: checkinId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.publicTrip,
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          return PublicTripPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
});

/// Minimal splash shown momentarily during the initial auth check.
class _SplashRedirectPage extends StatelessWidget {
  const _SplashRedirectPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// A [Listenable] that notifies GoRouter whenever auth state changes.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.value?.status != next.value?.status) {
        notifyListeners();
      }
    });
  }
}
