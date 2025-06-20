import 'package:equatable/equatable.dart';

abstract class GoogleLoginEvents extends Equatable {
  const GoogleLoginEvents();

  @override
  List<Object?> get props => [];
}

class GoogleLoginRequested extends GoogleLoginEvents {
  const GoogleLoginRequested();
}

class GoogleLoginCancelled extends GoogleLoginEvents {
  const GoogleLoginCancelled();
}
