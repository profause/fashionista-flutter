import 'package:fashionista/data/repository/auth/auth_repository_impl.dart';
import 'package:fashionista/data/repository/clients/clients_repository_impl.dart';
import 'package:fashionista/data/repository/designers/designers_repository_impl.dart';
import 'package:fashionista/data/repository/profile/user_repository_impl.dart';
import 'package:fashionista/data/services/firebase_auth_service.dart';
import 'package:fashionista/data/services/firebase_clients_service.dart';
import 'package:fashionista/data/services/firebase_designers_service.dart';
import 'package:fashionista/data/services/firebase_user_service.dart';
import 'package:fashionista/domain/repository/auth/auth_repository.dart';
import 'package:fashionista/domain/repository/clients/clients_repository.dart';
import 'package:fashionista/domain/repository/designers/designers_repository.dart';
import 'package:fashionista/domain/repository/profile/user_repository.dart';
import 'package:fashionista/domain/usecases/auth/signin_usecase.dart';
import 'package:fashionista/domain/usecases/auth/signout_usecase.dart';
import 'package:fashionista/domain/usecases/auth/verify_otp_usecase.dart';
import 'package:fashionista/domain/usecases/clients/add_client_usecase.dart';
import 'package:fashionista/domain/usecases/clients/delete_client_usecase.dart';
import 'package:fashionista/domain/usecases/clients/fetch_clients_usecase.dart';
import 'package:fashionista/domain/usecases/clients/find_client_by_id_usecase.dart';
import 'package:fashionista/domain/usecases/clients/update_client_usecase.dart';
import 'package:fashionista/domain/usecases/designers/add_designer_usecase.dart';
import 'package:fashionista/domain/usecases/designers/add_or_remove_favourite_usecase.dart';
import 'package:fashionista/domain/usecases/designers/delete_designer_usecase.dart';
import 'package:fashionista/domain/usecases/designers/find_designer_by_id_usecase.dart';
import 'package:fashionista/domain/usecases/designers/find_designers_usecase.dart';
import 'package:fashionista/domain/usecases/designers/is_favourite_usecase.dart';
import 'package:fashionista/domain/usecases/designers/update_designer_usecase.dart';
import 'package:fashionista/domain/usecases/profile/fetch_user_profile_usecase.dart';
import 'package:fashionista/domain/usecases/profile/update_user_profile_usecase.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initialiseDependencies() async {
  sl.registerSingleton<FirebaseAuthService>(FirebaseAuthServiceImpl());
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());
  sl.registerSingleton<SignInUsecase>(SignInUsecase());
  sl.registerSingleton<SignOutUsecase>(SignOutUsecase());
  sl.registerSingleton<VerifyOtpUsecase>(VerifyOtpUsecase());

  sl.registerSingleton<FirebaseUserService>(FirebaseUserServiceImpl());
  sl.registerSingleton<UserRepository>(UserRepositoryImpl());
  sl.registerSingleton<FetchUserProfileUsecase>(FetchUserProfileUsecase());
  sl.registerSingleton<UpdateUserProfileUsecase>(UpdateUserProfileUsecase());

  sl.registerSingleton<FetchClientsUsecase>(FetchClientsUsecase());
  sl.registerSingleton<AddClientUsecase>(AddClientUsecase());
  sl.registerSingleton<UpdateClientUsecase>(UpdateClientUsecase());
  sl.registerSingleton<DeleteClientUsecase>(DeleteClientUsecase());
  sl.registerSingleton<FindClientByIdUsecase>(FindClientByIdUsecase());
  sl.registerSingleton<ClientsRepository>(ClientsRepositoryImpl());
  sl.registerSingleton<FirebaseClientsService>(FirebaseClientsServiceImpl());

  sl.registerSingleton<DesignersRepository>(DesignersRepositoryImpl());
  sl.registerSingleton<FirebaseDesignersService>(
    FirebaseDesignersServiceImpl(),
  );

  sl.registerSingleton<AddDesignerUsecase>(AddDesignerUsecase());
  sl.registerSingleton<FindDesignerByIdUsecase>(FindDesignerByIdUsecase());
  sl.registerSingleton<UpdateDesignerUsecase>(UpdateDesignerUsecase());
  sl.registerSingleton<DeleteDesignerUsecase>(DeleteDesignerUsecase());
  sl.registerSingleton<FindDesignersUsecase>(FindDesignersUsecase());
  sl.registerSingleton<AddOrRemoveFavouriteUsecase>(
    AddOrRemoveFavouriteUsecase(),
  );
  sl.registerSingleton<IsFavouriteUsecase>(IsFavouriteUsecase());
}
