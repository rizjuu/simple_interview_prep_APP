import 'package:flutter/material.dart';
import 'package:interview_prep/services/ai_service.dart';
import 'package:interview_prep/widgets/product_model.dart';
import 'package:interview_prep/screens/product_detail_page.dart';
import 'package:interview_prep/screens/cart_page.dart';
import 'package:interview_prep/services/cart_service.dart';
import 'package:provider/provider.dart';

class ProductGridPage extends StatefulWidget {
  const ProductGridPage({super.key});

  @override
  State<ProductGridPage> createState() => _ProductGridPageState();
}

class _ProductGridPageState extends State<ProductGridPage> {
  final AIService _aiService = AIService();
  List<String> _recommendations = [];
  bool _isLoading = false;

  // Dummy data using the Product model
  final List<Product> _products = [
    const Product(
      id: '1',
      name: 'Laptop Pro',
      price: 1299.99,
      imageUrl: 'laptopp.png',
      description:
          'High-performance laptop with long battery life and sleek design.',
      category: ProductCategory.accessories,
      rating: 4.8,
    ),
    const Product(
      id: '2',
      name: 'Smartphone X',
      price: 899.99,
      imageUrl: 'phone.png',
      description:
          'Flagship smartphone with excellent camera and fast performance.',
      category: ProductCategory.accessories,
      rating: 4.7,
    ),
    const Product(
      id: '3',
      name: 'Wireless Mouse',
      price: 49.99,
      imageUrl: 'mouse.png',
      description:
          'Ergonomic wireless mouse with adjustable DPI and long battery life.',
      category: ProductCategory.accessories,
      rating: 4.5,
    ),
    const Product(
      id: '4',
      name: 'Mechanical Keyboard',
      price: 149.99,
      imageUrl: 'keyboard.png', // TODO: Add keyboard.jpg
      description:
          'Durable mechanical keyboard with customizable RGB lighting.',
      category: ProductCategory.accessories,
      rating: 4.6,
    ),
    const Product(
      id: '5',
      name: '4K Monitor',
      price: 499.99,
      imageUrl: 'monitor.png', // TODO: Add monitor.jpg
      description: 'Crisp 4K display with wide color gamut and thin bezels.',
      category: ProductCategory.accessories,
      rating: 4.9,
    ),
    const Product(
      id: '6',
      name: 'HD Webcam',
      price: 79.99,
      imageUrl: 'webcam.png', // TODO: Add webcam.jpg
      description:
          'High-definition webcam ideal for streaming and video calls.',
      category: ProductCategory.accessories,
      rating: 4.3,
    ),
    const Product(
      id: '7',
      name: 'Performance T-Shirt',
      price: 29.99,
      imageUrl: 'tshirt.png', // TODO: Add tshirt.jpg
      description: 'Breathable performance tee for training and everyday wear.',
      category: ProductCategory.clothing,
      rating: 4.4,
    ),
    const Product(
      id: '8',
      name: 'Hoodie Tech',
      price: 79.99,
      imageUrl: 'hoodie.png', // TODO: Add hoodie.jpg
      description: 'Comfortable tech hoodie with moisture-wicking fabric.',
      category: ProductCategory.clothing,
      rating: 4.5,
    ),
    const Product(
      id: '9',
      name: 'Running Shoes',
      price: 119.99,
      imageUrl: 'shoes.png', // TODO: Add shoes.jpg
      description: 'Lightweight running shoes with responsive cushioning.',
      category: ProductCategory.footwear,
      rating: 4.6,
    ),
    const Product(
      id: '10',
      name: 'Tennis Racket',
      price: 199.99,
      imageUrl: 'racket.png', // TODO: Add racket.jpg
      description: 'High-performance racket for competitive play.',
      category: ProductCategory.sports,
      rating: 4.7,
    ),
    const Product(
      id: '11',
      name: 'Football',
      price: 24.99,
      imageUrl: 'football.png', // TODO: Add football.jpg
      description: 'Durable match-grade football for outdoor play.',
      category: ProductCategory.sports,
      rating: 4.2,
    ),
    const Product(
      id: '12',
      name: 'Yoga Mat',
      price: 39.99,
      imageUrl: 'yogamat.png', // TODO: Add yogamat.jpg
      description: 'Non-slip yoga mat with extra cushioning.',
      category: ProductCategory.sports,
      rating: 4.8,
    ),
    const Product(
      id: '13',
      name: 'Smartwatch',
      price: 249.99,
      imageUrl: 'smartwatch.png', // TODO: Add smartwatch.jpg
      description: 'Feature-packed smartwatch with health tracking.',
      category: ProductCategory.accessories,
      rating: 4.5,
    ),
    const Product(
      id: '14',
      name: 'Wireless Headphones',
      price: 199.99,
      imageUrl: 'headphones.png', // TODO: Add headphones.jpg
      description:
          'Noise-cancelling wireless headphones with long battery life.',
      category: ProductCategory.accessories,
      rating: 4.9,
    ),
  ];

  final List<String> _userHistory = ['Laptop Pro', '4K Monitor'];

  void _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _recommendations = [];
    });

    final recommendations = await _aiService.getAIProductRecommendations(
      pastInteractions: _userHistory,
    );

    setState(() {
      _recommendations = recommendations;
      _isLoading = false;
    });
  }

  void _fetchRatingBasedRecommendations() async {
    setState(() {
      _isLoading = true;
      _recommendations = [];
    });

    final recommendations = await _aiService.analyzeProductsByRating(
      products: _products,
    );

    setState(() {
      _recommendations = recommendations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          _buildCartIcon(context),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              ),
            ),
          _recommendations.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _recommendations = [];
                    });
                  },
                  tooltip: 'Back to products',
                )
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.recommend),
                  tooltip: 'Get recommendations',
                  onSelected: (value) {
                    if (value == 'history') {
                      _fetchRecommendations();
                    } else if (value == 'rating') {
                      _fetchRatingBasedRecommendations();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 18),
                          SizedBox(width: 8),
                          Text('By History'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'rating',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 18),
                          SizedBox(width: 8),
                          Text('By Star Rating'),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendations.isNotEmpty
          ? _buildRecommendationsView()
          : _buildProductGridView(),
    );
  }

  Widget _buildCartIcon(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              tooltip: 'Shopping Cart',
            ),
            if (cart.items.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    cart.items.length.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: product.imageUrl.isEmpty
                      ? Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : product.imageUrl.startsWith('http')
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  );
                          },
                        )
                      : Image.asset(
                          'assets/${product.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE2E2E2),
                        ),
                      ),
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          color: Color(0xFF00F5D4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildSmallStarRating(product.rating),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallStarRating(double rating) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor()
                ? Icons.star
                : index < rating
                ? Icons.star_half
                : Icons.star_outline,
            color: const Color(0xFF00F5D4),
            size: 12,
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFF00F5D4),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsView() {
    return ListView.builder(
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.star),
          title: Text(_recommendations[index]),
        );
      },
    );
  }
}
