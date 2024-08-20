import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../../common/data/repo/in_app_purchase_repo.dart';
import 'getproducts_events.dart';
import 'getproducts_states.dart';

class GetInAppProductsBloc
    extends Bloc<GetInAppProductsEvents, GetInAppProductsStates> {
  final inAppPurchaseRepository = InAppPurchaseRepoImpl();
  GetInAppProductsBloc() : super(GetInAppProductsInitialState()) {
    on<RequestInAppProducts>((event, emit) async {
      emit(GetInAppProductsLoadingState());
      try {
        final List<ProductDetails> products =
            await inAppPurchaseRepository.getProductsDetailsById();
        emit(GetInAppProductsSuccessState(result: products));
      } on SocketException {
        emit(GetInAppProductsFailedState(msg: 'No Internet Connection'));
      } catch (e) {
        emit(GetInAppProductsFailedState(msg: e.toString()));
      }
    });
  }
}
