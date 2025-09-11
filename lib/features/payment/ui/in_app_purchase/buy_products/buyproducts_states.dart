import 'package:equatable/equatable.dart';

abstract class BuyConsumableStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class BuyConsumableInitialState extends BuyConsumableStates {}

class BuyConsumableLoadingState extends BuyConsumableStates {}

class BuyConsumableSuccessState extends BuyConsumableStates {
  final dynamic result;
  BuyConsumableSuccessState({required this.result});
}

class BuyConsumableFailedState extends BuyConsumableStates {
  final String? msg;
  BuyConsumableFailedState({this.msg});
}
