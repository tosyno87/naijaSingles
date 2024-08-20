import 'package:equatable/equatable.dart';

class ReverseGeocode extends Equatable {
  final String placeId;
  final String formattedAddress;

  const ReverseGeocode({required this.formattedAddress, required this.placeId});

  @override
  List<Object> get props => [formattedAddress];

  factory ReverseGeocode.fromJson(Map<String, dynamic> json) {
    return ReverseGeocode(
        placeId: json["place_id"], formattedAddress: json["formatted_address"]);
  }
}
