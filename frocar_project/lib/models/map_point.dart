class MapPoint {
  final int? id;
  final double latitude;
  final double longitude;
  final int userId;

  MapPoint({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.userId,
  });

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
    };
  }
}