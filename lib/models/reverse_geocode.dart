import 'package:equatable/equatable.dart';

class ReverseGeocode extends Equatable {
  const ReverseGeocode({required this.formattedAddress, required this.placeId});

  factory ReverseGeocode.fromJson(Map<String, dynamic> json) => ReverseGeocode(
        placeId: json['place_id']?.toString() ?? '',
        formattedAddress: json['formatted_address']?.toString() ?? '',
      );
  final String placeId;
  final String formattedAddress;

  @override
  List<Object> get props => [formattedAddress];
}
