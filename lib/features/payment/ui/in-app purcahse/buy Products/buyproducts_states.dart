// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:equatable/equatable.dart';

abstract class BuyConsumableStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class BuyConsumableInitialState extends BuyConsumableStates {}

class BuyConsumableLoadingState extends BuyConsumableStates {}

class BuyConsumableSuccessState extends BuyConsumableStates {
  final result;
  BuyConsumableSuccessState({required this.result});
}

class BuyConsumableFailedState extends BuyConsumableStates {
  final msg;
  BuyConsumableFailedState({this.msg});
}
