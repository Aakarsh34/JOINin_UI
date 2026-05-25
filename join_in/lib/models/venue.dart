import '_helpers.dart';

class GeoPoint {
  final double longitude;
  final double latitude;

  const GeoPoint({required this.longitude, required this.latitude});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'];
    if (coords is List && coords.length >= 2) {
      return GeoPoint(
        longitude: doubleFromJson(coords[0]),
        latitude: doubleFromJson(coords[1]),
      );
    }
    return const GeoPoint(longitude: 0, latitude: 0);
  }

  Map<String, dynamic> toJson() => {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      };
}

class Venue {
  final String name;
  final String address;
  final GeoPoint coordinates;

  const Venue({
    required this.name,
    required this.address,
    required this.coordinates,
  });

  factory Venue.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Venue(
        name: '',
        address: '',
        coordinates: GeoPoint(longitude: 0, latitude: 0),
      );
    }
    return Venue(
      name: stringFromJson(json['name']),
      address: stringFromJson(json['address']),
      coordinates: json['coordinates'] is Map<String, dynamic>
          ? GeoPoint.fromJson(json['coordinates'] as Map<String, dynamic>)
          : const GeoPoint(longitude: 0, latitude: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'coordinates': coordinates.toJson(),
      };
}
