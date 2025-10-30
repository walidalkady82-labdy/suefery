import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import '../../data/services/firebase_service.dart';
// import '../history/customer_order_history.txt';
import 'home_cubit.dart';

// Customer App Screen (S1 Focus)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock language state for demonstration (In real app, this comes from a global LocaleCubit)
    
    final strings = AppLocalizations.of(context);
    // Use MultiBlocProvider to ensure GeminiCubit is available only here or globally
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text(strings!.customerTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                ConversationalTab(),
                StoreBrowseTab(),
              ],
            ),
          ),
      );
  }
}

// --- TAB 1: AI Conversational Ordering (S1 USP) ---

class ConversationalTab extends StatelessWidget {
  const ConversationalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state.geminiIsSuccessful) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("structuredOutputLabel")),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<HomeCubit>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "welcomeMessage",
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
                      onPressed: state.geminiIsLoading ? null : () => cubit.submitOrder("strings.itemPlaceholder"),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: state.geminiIsLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.mic, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "strings.promptPlaceholder",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),

              // Structured Output Area
              if (state.geminiIsSuccessful) ...[
                const SizedBox(height: 40),
                Text(
                  "strings.structuredOutputLabel",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Theme.of(context).colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildStructuredOrder(context, {"state" : "structuredOrder"}),
                const SizedBox(height: 24),
                
                // Checkout Button
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to checkout screen with state.structuredOrder
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text("strings.orderNow"),
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
    final strings = AppLocalizations.of(context);
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
              subtitle: Text(strings!.partnerStore),
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
  const StoreBrowseTab({super.key});

  // Mock list of local partner stores (W2 Mitigation Focus)
  final List<String> _stores = const [
    'University Mini-Mart (0.5km)',
    'Campus Pharmacy (0.8km)',
    'Main Street Cafe (1.2km)',
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "browseStoreList",
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
                subtitle: Text(strings!.fastestDeliveryZone),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to the store's inventory browsing screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      //strings.translate('Navigating to $store inventory...', 'الانتقال إلى مخزون $store...')
                      "Navigating to $store inventory..."
                      )),
                  );
                },
              ),
            ),
          )).toList(),
          const SizedBox(height: 24),
          const Divider(),
          // Text(
          //   strings.translate('Why order from a store?', 'لماذا تطلب من متجر؟'),
          //   style: Theme.of(context).textTheme.titleLarge,
          // ),
          // const SizedBox(height: 8),
          // Text(
          //   strings.translate('Guarantees stock availability and gives you full control over product selection, mitigating inventory errors (W2).', 'يضمن توافر المخزون ويمنحك السيطرة الكاملة على اختيار المنتج، مما يقلل من أخطاء المخزون.'),
          //   style: Theme.of(context).textTheme.bodyMedium,
          // ),
        ],
      ),
    );
  }
}