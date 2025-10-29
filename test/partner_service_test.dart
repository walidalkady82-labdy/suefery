
// --- 1. USER MODELS & ROLES ---

// Defines the three strategic roles required by the Unified Multi-Role Codebase (S2)
enum UserRole {
  customer,
  rider,
  partner,
}

// Core User Model: Represents any user type on the SUEFERY platform
class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String specificPersonaGoal; // Directly links model to the Persona's motivation

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.specificPersonaGoal,
  });

  String get roleTitle {
    switch (role) {
      case UserRole.customer:
        return 'Customer (Aya)';
      case UserRole.rider:
        return 'Rider (Tarek)';
      case UserRole.partner:
        return 'Partner (Hassan)';
    }
  }

  String get welcomeMessage {
    switch (role) {
      case UserRole.customer:
        // Focus on S1 (Conversational AI) and S3 (Speed)
        return 'Welcome Customer! Start your **Conversational Order (S1)**. Your goal: **$specificPersonaGoal**';
      case UserRole.rider:
        // Focus on S3 (Logistics Moat) and T2 (Cost Mitigation)
        return 'Welcome Rider! Check your **Optimized Routes (S3)**. Your goal: **$specificPersonaGoal**';
      case UserRole.partner:
        // Focus on W2/T3 Mitigation (Easy Onboarding) and O1 (Sales Volume)
        return 'Welcome Partner! Manage **Hyper-Local Orders (W2)** easily. Your goal: **$specificPersonaGoal**';
    }
  }
}

// --- 2. AUTH SERVICE SIMULATION ---

class AuthService {
  static AppUser getCustomerPersona() {
    return AppUser(
      id: 'USER_A123',
      name: 'Aya',
      role: UserRole.customer,
      specificPersonaGoal: 'Speed and convenience (get essentials quickly).',
    );
  }

  static AppUser getRiderPersona() {
    return AppUser(
      id: 'USER_R456',
      name: 'Tarek',
      role: UserRole.rider,
      specificPersonaGoal: 'Maximize earnings per hour (low T2 risk).',
    );
  }

  static AppUser getPartnerPersona() {
    return AppUser(
      id: 'USER_P789',
      name: 'Hassan',
      role: UserRole.partner,
      specificPersonaGoal: 'Increase sales volume without overhead (W2 mitigation).',
    );
  }
}

// --- 3. PARTNER INVENTORY DATA MODELS (NEW FOR W2 MITIGATION) ---

class InventoryItem {
  final String id;
  final String name;
  double price;
  bool isInStock;
  String category;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isInStock,
    required this.category,
  });

  // Simple copyWith method for state management
  InventoryItem copyWith({
    String? name,
    double? price,
    bool? isInStock,
    String? category,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      isInStock: isInStock ?? this.isInStock,
      category: category ?? this.category,
    );
  }
}

// --- 4. DATA/MOCK SERVICE ---

class PartnerService {
  // Mock Inventory data for the Partner Persona (Hassan)
  static final List<InventoryItem> _mockInventory = [
    InventoryItem(id: 'I001', name: 'Water Bottle (1.5L)', price: 8.0, isInStock: true, category: 'Drinks'),
    InventoryItem(id: 'I002', name: 'Small Chips (Spicy)', price: 5.0, isInStock: true, category: 'Snacks'),
    InventoryItem(id: 'I003', name: 'Lab Notebook (A4)', price: 25.0, isInStock: true, category: 'Stationery'),
    InventoryItem(id: 'I004', name: 'Black Coffee (Hot)', price: 12.0, isInStock: true, category: 'Drinks'),
    InventoryItem(id: 'I005', name: 'Pain Relief Pills (Box)', price: 55.0, isInStock: false, category: 'Medicine'),
    InventoryItem(id: 'I006', name: 'Charging Cable (Type-C)', price: 45.0, isInStock: true, category: 'Electronics'),
    InventoryItem(id: 'I007', name: 'Sodas (Can)', price: 7.0, isInStock: false, category: 'Drinks'),
    InventoryItem(id: 'I008', name: 'Pack of Biscuits', price: 10.0, isInStock: true, category: 'Snacks'),
  ];

  Future<List<InventoryItem>> getPartnerInventory() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockInventory;
  }

  // Simple state update simulation
  Future<void> updateItemStock(String itemId, bool newStockStatus) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final itemIndex = _mockInventory.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      _mockInventory[itemIndex] = _mockInventory[itemIndex].copyWith(isInStock: newStockStatus);
    }
  }

  Future<void> updateItemPrice(String itemId, double newPrice) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final itemIndex = _mockInventory.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      _mockInventory[itemIndex] = _mockInventory[itemIndex].copyWith(price: newPrice);
    }
  }
}