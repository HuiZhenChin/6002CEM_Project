import 'package:bloc/bloc.dart';

class LoadingCubit extends Cubit<bool> {
  LoadingCubit() : super(false);

  void setLoading(bool isLoading) => emit(isLoading);
}
