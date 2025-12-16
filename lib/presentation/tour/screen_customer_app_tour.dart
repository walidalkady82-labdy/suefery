import 'package:flutter/material.dart';

class ScreenCustomerAppTour extends StatefulWidget {
  const ScreenCustomerAppTour({super.key});

  @override
  State<ScreenCustomerAppTour> createState() => _ScreenCustomerAppTourState();
}

class _ScreenCustomerAppTourState extends State<ScreenCustomerAppTour> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Using your app's peach/orange palette
    final bgColor = theme.scaffoldBackgroundColor; 
    final accentColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        actions: [
          if (_currentPage < 4)
            TextButton(
              onPressed: () => Navigator.pop(context),
            child: const Text("Skip", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildTitleSlide(theme),
                _buildFeatureSlide(
                  theme,
                  title: "1. Smart Request",
                  subtitle: "\"Ask for Anything\"",
                  description: "Customers simply type what they need (e.g., 'Pepsi'). S1 Integration sends this request to all nearby partners instantly.",
                  imageUrl: "https://placehold.co/400x800/fff3e0/ff823a?text=Search%3A+Pepsi%0A%0AFinding+nearby%0Astores...",
                ),
                _buildFeatureSlide(
                  theme,
                  title: "2. Live Comparison",
                  subtitle: "The Best Offer Wins",
                  description: "Partners respond with their price. The customer picks the best value based on price, speed, and rating.",
                  imageUrl: "https://placehold.co/450x800/ffe0b2/5d4037?text=OFFERS%0A%0AStore+A%3A+10+EGP%0A(5+mins)%0A%0AStore+B%3A+12+EGP%0A(2+mins)",
                ),
                _buildFullscreenSlide(
                  theme,
                  title: "3. S3 Dispatch",
                  description: "Once accepted, our S3 Dispatch System automatically assigns the nearest driver based on your GeoHash.",
                  imageUrl: "https://placehold.co/600x900/37474f/cfd8dc?text=Map+Navigation+View",
                ),
                _buildSummarySlide(theme),
              ],
            ),
          ),
          _buildBottomControls(theme),
        ],
      ),
    );
  }

  // SLIDE 1: Title
  Widget _buildTitleSlide(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative blobs
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: theme.primaryColor.withAlpha(128),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phonelink_ring, size: 80, color: theme.primaryColor),
          ),
          const SizedBox(height: 40),
          Text(
            "SUEFERY",
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "The Customer Experience",
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "See how customers find you using our S3 Hyper-Local Technology.",
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // SLIDE 2 & 3: Standard Feature (Text Top, Image Bottom)
  Widget _buildFeatureSlide(ThemeData theme, {
    required String title,
    required String subtitle,
    required String description,
    required String imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor)),
          const SizedBox(height: 20),
          Text(subtitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            description, 
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          // Phone Mockup Frame
          Container(
            height: 400,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 8),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // SLIDE 4: Fullscreen Background
  Widget _buildFullscreenSlide(ThemeData theme, {
    required String title,
    required String description,
    required String imageUrl,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(imageUrl, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black..withAlpha(128)],
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        )
      ],
    );
  }

  // SLIDE 5: Summary Tiles
  Widget _buildSummarySlide(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Why Customers Love It",
            style: theme.textTheme.headlineMedium?.copyWith(color: theme.primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildSummaryTile(theme, Icons.bolt, "Speed", "No warehouses. Inventory comes from you, the neighbor."),
          const SizedBox(height: 16),
          _buildSummaryTile(theme, Icons.attach_money, "Best Prices", "Competitive bidding ensures fair value."),
          const SizedBox(height: 16),
          _buildSummaryTile(theme, Icons.store_mall_directory, "Availability", "Access to local inventory not found elsewhere."),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(ThemeData theme, IconData icon, String title, String sub) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor..withAlpha(128),
          child: Icon(icon, color: theme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
      ),
    );
  }

  // Bottom Navigation Dots
  Widget _buildBottomControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots
          Row(
            children: List.generate(5, (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? theme.primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          // Button
          ElevatedButton(
            onPressed: () {
              if (_currentPage < 4) {
                _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(), 
              padding: const EdgeInsets.all(16)
            ),
            child: Icon(_currentPage == 4 ? Icons.check : Icons.arrow_forward),
          )
        ],
      ),
    );
  }
}