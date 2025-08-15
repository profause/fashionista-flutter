import 'package:fashionista/data/repository/auth/auth_repository_impl.dart';
import 'package:fashionista/data/repository/profile/user_repository_impl.dart';
import 'package:fashionista/data/services/firebase_auth_service.dart';
import 'package:fashionista/data/services/firebase_user_service.dart';
import 'package:fashionista/domain/repository/auth/auth_repository.dart';
import 'package:fashionista/domain/repository/profile/user_repository.dart';
import 'package:fashionista/domain/usecases/auth/signin_usecase.dart';
import 'package:fashionista/domain/usecases/profile/fetch_user_profile_usecase.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initialiseDependencies() async {
  sl.registerSingleton<FirebaseAuthService>(FirebaseAuthServiceImpl());
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());
  sl.registerSingleton<SignInUsecase>(SignInUsecase());

  sl.registerSingleton<FirebaseUserService>(FirebaseUserServiceImpl());
  sl.registerSingleton<UserRepository>(UserRepositoryImpl());
  sl.registerSingleton<FetchUserProfileUsecase>(FetchUserProfileUsecase());
}
