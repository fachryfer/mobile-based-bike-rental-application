class Bike {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String? description;
  // Optional: imageUrl, description, etc.

  Bike({required this.id, required this.name, required this.quantity, required this.price, this.imageUrl, this.description});

  factory Bike.fromFirestore(Map<String, dynamic> data, String id) {
    return Bike(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
} 