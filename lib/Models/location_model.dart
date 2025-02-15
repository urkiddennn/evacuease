class LocationModel {
  final String id;
  final String name;
  final String description;
  final List<String> contacts;
  final int capacity;
  final double lat;
  final double lng;
  final List<String> images;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.contacts,
    required this.capacity,
    required this.lat,
    required this.lng,
    required this.images,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
  return LocationModel(
    id: json['_id'] ?? '', // Ensure id is a string, default to empty string
    name: json['name'] ?? 'Unknown Name', // Default name if null
    description: json['description'] ?? 'No description available', // Default description
    contacts: (json['contacts'] as List?)?.map((e) => e.toString()).toList() ?? [], // Handle null contacts
    capacity: json['capacity'] ?? 0, // Default capacity to 0
    lat: (json['lat'] as num?)?.toDouble() ?? 0.0, // Ensure lat is a valid double
    lng: (json['lng'] as num?)?.toDouble() ?? 0.0, // Ensure lng is a valid double
    images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [], // Handle null images
  );
}

}
