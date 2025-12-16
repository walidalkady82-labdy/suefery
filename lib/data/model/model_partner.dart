class ModelPartner {
  final String id;
  final String name;
  final String geohash; 
  final double latitude;
  final double longitude;
  final bool isOpen;
  
  // Transient field: Not stored in DB, but calculated during fetch
  final double? distanceFromUser; 

  ModelPartner({
    required this.id,
    required this.name,
    required this.geohash,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    this.distanceFromUser,
  });

  // Factory to create from Firestore Map
  factory ModelPartner.fromMap(Map<String, dynamic> map, String docId) {
    return ModelPartner(
      id: docId,
      name: map['name'] ?? '',
      geohash: map['geohash'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      isOpen: map['isOpen'] ?? false,
    );
  }

  // Helper to create a copy with the calculated distance
  ModelPartner copyWithDistance(double dist) {
    return ModelPartner(
      id: id, 
      name: name, 
      geohash: geohash, 
      latitude: latitude, 
      longitude: longitude, 
      isOpen: isOpen, 
      distanceFromUser: dist
    );
  }
}