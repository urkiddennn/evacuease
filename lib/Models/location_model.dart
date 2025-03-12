class LocationModel {
  final String id;
  final String name;
  final String description;
  final List<String> contacts;
  final String? contactPersonName;
  int capacity; // Dynamic, real-time capacity
  final int actualCapacity; // Original, fixed capacity
  final String hazardType;
  final double lat;
  final double lng;
  final String locationName;
  final String visibility;
  final List<String> images;
  final DateTime? createdAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.contacts,
    this.contactPersonName,
    required this.capacity,
    required this.actualCapacity,
    required this.hazardType,
    required this.lat,
    required this.lng,
    required this.locationName,
    required this.visibility,
    required this.images,
    this.createdAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Name',
      description: json['description'] ?? 'No description available',
      contacts:
          (json['contacts'] as List?)?.map((e) => e.toString()).toList() ?? [],
      contactPersonName: json['contactPersonName'] as String?,
      capacity: json['capacity'] ?? 0,
      actualCapacity: json['actualCapacity'] ?? json['capacity'] ?? 0, // Fallback to capacity if not provided
      hazardType: json['hazardType']?.toString() ?? 'Unknown',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      locationName: json['locationName']?.toString() ?? 'Unknown Location',
      visibility: json['visibility']?.toString() ?? 'public',
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
