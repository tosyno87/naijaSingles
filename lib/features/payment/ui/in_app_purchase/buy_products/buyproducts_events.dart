import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class BuyInAppProductsEvents extends Equatable {
  @override
  List<Object?> get props => [];
}

class RequestBuyConsumableProducts extends BuyInAppProductsEvents {
  final ProductDetails productDetails;
  RequestBuyConsumableProducts({required this.productDetails});
}
