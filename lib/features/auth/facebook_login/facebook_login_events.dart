import 'package:equatable/equatable.dart';

abstract class FacebookLoginEvents extends Equatable {
  const FacebookLoginEvents();

  @override
  List<Object> get props => [];
}

class FacebookLoginRequest extends FacebookLoginEvents {}
