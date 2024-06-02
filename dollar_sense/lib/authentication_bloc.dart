import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(AuthenticationInitial());

  @override
  Stream<AuthenticationState> mapEventToState(
      AuthenticationEvent event,
      ) async* {
    if (event is AppStarted) {
      // Add logic here to check if the user is authenticated
      // For example, you can check if the user is logged in
      // and emit the corresponding state
      yield* _mapAppStartedToState();
    } else if (event is LoggedIn) {
      // Handle the event when the user logs in
      // For example, update the authentication state
      yield AuthenticationAuthenticated();
    } else if (event is LoggedOut) {
      // Handle the event when the user logs out
      // For example, clear any user session data
      yield AuthenticationUnauthenticated();
    }
  }

  Stream<AuthenticationState> _mapAppStartedToState() async* {
    // Add logic here to check if the user is already logged in
    // For example, you can check if the user has an active session
    // and emit the appropriate state
    yield AuthenticationLoading(); // Placeholder loading state
    await Future.delayed(Duration(seconds: 2)); // Simulating a delay
    yield AuthenticationUnauthenticated(); // Placeholder unauthenticated state
  }
}