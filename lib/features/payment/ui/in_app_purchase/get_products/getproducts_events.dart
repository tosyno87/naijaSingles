import 'package:equatable/equatable.dart';

abstract class GetInAppProductsEvents extends Equatable {
  @override
  List<Object?> get props => [];
}

class RequestInAppProducts extends GetInAppProductsEvents {
  RequestInAppProducts();
}
