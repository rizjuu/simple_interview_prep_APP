/// Enum for product categories to ensure type safety.
enum ProductCategory { clothing, footwear, sports, accessories }

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final ProductCategory category;
  final double rating; // Star rating from 0 to 5

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    this.rating = 0.0,
  });

  // Helper to format the price as a currency string.
  String get formattedPrice {
    return '₱${price.toStringAsFixed(2)}';
  }

  /// Converts a [Product] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'category': category.name,
      'rating': rating,
    };
  }

  /// Creates a [Product] instance from a JSON map.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      rating: json['rating'] ?? 0.0,
      category: ProductCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ProductCategory.accessories, // Default if not found
      ),
    );
  }
}
