import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/localizations/app_localizations.txt';
import 'package:flutter/material.dart';
import '../../core/localizations/app_localizations.txt';
import '../../data/services/firebase_service.dart';
import '../history/customer_order_history.dart';

// // Customer App Screen (S1 Focus)
// class HomeScreen1 extends StatelessWidget {
//   const HomeScreen1({super.key});
//       // : super(
//       //     titleKey: 'customer_title',
//       //     welcomeKey: 'welcome_customer',
//       //     color: const Color(0xFFE5002D), // Red for customer focus/urgency
//       //     icon: Icons.shopping_cart,
//       //   );

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         ElevatedButton.icon(
//           onPressed: () {
//             // This button would lead to the Gemini API integration next!
//             ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Navigating to Gemini Voice Order...')));
//           },
//           icon: const Icon(Icons.voice_chat),
//           label: const Text('Start Conversational Order (S1)'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF00308F),
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//           ),
//         ),
//         const SizedBox(height: 10),
//         const Text(
//           'Target: Achieve >= 70% Digital Payment Rate (W4 Mitigation)',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 12, color: Colors.grey),
//         ),
//       ],
//     );
//   }
// }

// /// A simple screen to host the HistoryScreen for demonstration.
// class HomeScreen2 extends StatelessWidget {
//   const HomeScreen2({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // The AppLocalizations class must be initialized here
//     final loc = AppLocalizations.of(context)!;
    
//     // Display the current user ID to confirm successful authentication
//     final userId = FirebaseService.instance.userId;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(loc.translate('home_title')),
//         backgroundColor: Theme.of(context).primaryColor,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Welcome to SUEFERY!', style: Theme.of(context).textTheme.headlineMedium),
//             const SizedBox(height: 10),
//             // MANDATORY: Display the full user ID for multi-user collaboration
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: SelectableText(
//                 'Current User ID (Firestore Path): $userId',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).push(MaterialPageRoute(
//                   builder: (_) => const OrderHistoryScreen(),
//                 ));
//               },
//               icon: const Icon(Icons.history),
//               label: Text(loc.historyTitle),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Theme.of(context).colorScheme.secondary,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                 textStyle: const TextStyle(fontSize: 18),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// Customer App Screen (S1 Focus)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock language state for demonstration (In real app, this comes from a global LocaleCubit)
    
    final strings = AppLocalizations.of(context)!;
    final TextDirection direction = currentLang == Language.ar ? TextDirection.rtl : TextDirection.ltr;
    // Use MultiBlocProvider to ensure GeminiCubit is available only here or globally
    return BlocProvider(
      create: (context) => GeminiCubit(),
      child: DefaultTabController(
        length: 2,
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            appBar: AppBar(
              title: Text(strings.customerTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              centerTitle: false,
              bottom: TabBar(
                indicatorColor: Theme.of(context).colorScheme.secondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: [
                  Tab(text: strings.tabAIOrder, icon: const Icon(Icons.mic)),
                  Tab(text: strings.tabBrowse, icon: const Icon(Icons.storefront)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ConversationalTab(strings: strings),
                StoreBrowseTab(strings: strings),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- TAB 1: AI Conversational Ordering (S1 USP) ---

class ConversationalTab extends StatelessWidget {
  final AppStrings strings;
  const ConversationalTab({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GeminiCubit, GeminiState>(
      listener: (context, state) {
        if (state is GeminiSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.structuredOutputLabel)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<GeminiCubit>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.welcomeMessage,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Microphone/Input Area
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    FloatingActionButton.large(
                      onPressed: state is GeminiLoading ? null : () => cubit.submitOrder(strings.itemPlaceholder),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: state is GeminiLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.mic, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      strings.promptPlaceholder,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),

              // Structured Output Area
              if (state is GeminiSuccess) ...[
                const SizedBox(height: 40),
                Text(
                  strings.structuredOutputLabel,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Theme.of(context).colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildStructuredOrder(context, state.structuredOrder),
                const SizedBox(height: 24),
                
                // Checkout Button
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to checkout screen with state.structuredOrder
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(strings.orderNow),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStructuredOrder(BuildContext context, Map<String, dynamic> order) {
    final List<Map<String, dynamic>> items = (order['items'] as List).cast<Map<String, dynamic>>();

    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.store, color: Colors.blueAccent),
              title: Text(order['partner'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(strings.translate('Partner Store', 'متجر شريك')),
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(child: Text('${item['qty']}x ${item['name']}')),
                  Text('EGP ${item['price'] * item['qty']}'),
                ],
              ),
            )).toList(),
            const Divider(),
            Text(
              '${strings.total}: EGP ${order['total']}',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TAB 2: Store Browse/Selection ---

class StoreBrowseTab extends StatelessWidget {
  final AppStrings strings;
  const StoreBrowseTab({super.key, required this.strings});

  // Mock list of local partner stores (W2 Mitigation Focus)
  final List<String> _stores = const [
    'University Mini-Mart (0.5km)',
    'Campus Pharmacy (0.8km)',
    'Main Street Cafe (1.2km)',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.browseStoreList,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ..._stores.map((store) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.local_mall, color: Colors.green),
                title: Text(store, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(strings.translate('Fastest delivery zone', 'أسرع منطقة توصيل')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to the store's inventory browsing screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.translate('Navigating to $store inventory...', 'الانتقال إلى مخزون $store...'))),
                  );
                },
              ),
            ),
          )).toList(),
          const SizedBox(height: 24),
          const Divider(),
          Text(
            strings.translate('Why order from a store?', 'لماذا تطلب من متجر؟'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            strings.translate('Guarantees stock availability and gives you full control over product selection, mitigating inventory errors (W2).', 'يضمن توافر المخزون ويمنحك السيطرة الكاملة على اختيار المنتج، مما يقلل من أخطاء المخزون.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}