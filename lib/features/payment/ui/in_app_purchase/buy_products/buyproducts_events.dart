import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class BuyInAppProductsEvents extends Equatable {
  @override
  List<Object?> get props => [];
}

class RequestBuyConsumableProducts extends BuyInAppProductsEvents {
  RequestBuyConsumableProducts({required this.productDetails});
  final ProductDetails productDetails;
}
