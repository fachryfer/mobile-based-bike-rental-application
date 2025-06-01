class Bike {
  final String id;
  final String name;
  final int quantity;
  final String? imageUrl;
  final String? description;
  // Optional: imageUrl, description, etc.

  Bike({required this.id, required this.name, required this.quantity, this.imageUrl, this.description});

  factory Bike.fromFirestore(Map<String, dynamic> data, String id) {
    return Bike(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      imageUrl: data['imageUrl'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
} 