import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class GetInAppProductsStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetInAppProductsInitialState extends GetInAppProductsStates {}

class GetInAppProductsLoadingState extends GetInAppProductsStates {}

class GetInAppProductsSuccessState extends GetInAppProductsStates {
  GetInAppProductsSuccessState({required this.result});
  final List<ProductDetails> result;
}

class GetInAppProductsFailedState extends GetInAppProductsStates {
  GetInAppProductsFailedState({this.msg});
  final String? msg;
}
