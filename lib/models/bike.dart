class Bike {
  final String id;
  final String name;
  final int quantity;
  final double pricePerDay;
  final String? imageUrl;
  final String? description;
  // Optional: imageUrl, description, etc.

  Bike({required this.id, required this.name, required this.quantity, required this.pricePerDay, this.imageUrl, this.description});

  factory Bike.fromFirestore(Map<String, dynamic> data, String id) {
    return Bike(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      pricePerDay: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'price': pricePerDay,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
} 