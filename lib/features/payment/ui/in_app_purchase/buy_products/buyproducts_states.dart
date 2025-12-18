import 'package:equatable/equatable.dart';

abstract class BuyConsumableStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class BuyConsumableInitialState extends BuyConsumableStates {}

class BuyConsumableLoadingState extends BuyConsumableStates {}

class BuyConsumableSuccessState extends BuyConsumableStates {
  BuyConsumableSuccessState({required this.result});
  final dynamic result;
}

class BuyConsumableFailedState extends BuyConsumableStates {
  BuyConsumableFailedState({this.msg});
  final String? msg;
}
