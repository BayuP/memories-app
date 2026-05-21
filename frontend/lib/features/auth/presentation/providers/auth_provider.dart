import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_app/core/demo/demo_flag.dart' show demoModeProvider;
import 'package:memories_app/core/network/api_client.dart';
import 'package:memories_app/core/network/secure_storage.dart';
import 'package:memories_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:memories_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:memories_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:memories_app/features/auth/domain/usecases/sign_up_usecase.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService.instance;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.error,
  });

  final AuthStatus status;
  final String? error;

  AuthState copyWith({AuthStatus? status, String? error}) {
    return AuthState(
      status: status ?? this.status,
      error: error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // DEMO: skip token check, return authenticated with mock user
    if (ref.watch(demoModeProvider)) {
      return const AuthState(status: AuthStatus.authenticated);
    }
    // DEMO: real token check below
    final storage = ref.watch(secureStorageProvider);
    final hasTokens = await storage.hasTokens();
    return AuthState(
      status:
          hasTokens ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // DEMO: skip API call, mark authenticated immediately
    if (ref.read(demoModeProvider)) {
      await Future.delayed(const Duration(milliseconds: 400));
      state = const AsyncData(AuthState(status: AuthStatus.authenticated));
      return;
    }
    // DEMO: real sign-in below
    state = const AsyncLoading();

    final useCase = ref.read(signInUseCaseProvider);
    final storage = ref.read(secureStorageProvider);

    state = await AsyncValue.guard(() async {
      final tokens = await useCase(email: email, password: password);
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return const AuthState(status: AuthStatus.authenticated);
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) async {
    // DEMO: skip API call, mark authenticated immediately
    if (ref.read(demoModeProvider)) {
      await Future.delayed(const Duration(milliseconds: 400));
      state = const AsyncData(AuthState(status: AuthStatus.authenticated));
      return;
    }
    // DEMO: real sign-up below
    state = const AsyncLoading();

    final useCase = ref.read(signUpUseCaseProvider);
    final storage = ref.read(secureStorageProvider);

    state = await AsyncValue.guard(() async {
      final tokens = await useCase(
        email: email,
        password: password,
        handle: handle,
        displayName: displayName,
      );
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return const AuthState(status: AuthStatus.authenticated);
    });
  }

  Future<void> signOut() async {
    // DEMO: skip token clear, just mark unauthenticated
    if (ref.read(demoModeProvider)) {
      state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    // DEMO: real sign-out below
    final storage = ref.read(secureStorageProvider);
    await storage.clearTokens();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// Convenience provider: true if authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authAsync = ref.watch(authProvider);
  return authAsync.maybeWhen(
    data: (s) => s.status == AuthStatus.authenticated,
    orElse: () => false,
  );
});
