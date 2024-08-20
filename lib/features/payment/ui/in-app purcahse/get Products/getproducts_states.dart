// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class GetInAppProductsStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetInAppProductsInitialState extends GetInAppProductsStates {}

class GetInAppProductsLoadingState extends GetInAppProductsStates {}

class GetInAppProductsSuccessState extends GetInAppProductsStates {
  final List<ProductDetails> result;
  GetInAppProductsSuccessState({required this.result});
}

class GetInAppProductsFailedState extends GetInAppProductsStates {
  final msg;
  GetInAppProductsFailedState({this.msg});
}
