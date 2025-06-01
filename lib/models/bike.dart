class Bike {
  final String id;
  final String name;
  final int quantity;
  // Optional: imageUrl, description, etc.

  Bike({required this.id, required this.name, required this.quantity});

  factory Bike.fromFirestore(Map<String, dynamic> data, String id) {
    return Bike(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }
} 