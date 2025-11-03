import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';
import '../../data/enums/message_sender.dart';
import '../../data/models/chat_message.dart';
// import '../history/customer_order_history.txt';
import 'home_cubit.dart';

// Customer App Screen (S1 Focus)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
    
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return BlocProvider(
      create: (context) => HomeCubit()..loadChat(12345),
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.customerTitle),
          backgroundColor: Colors.teal.shade800,
          actions: [
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),  
            IconButton(icon: const Icon(Icons.logout),onPressed: () => context.read<AuthCubit>().logOut()),
          ],
        ),
        backgroundColor: Colors.teal.shade50,
        body: DefaultTabController(
          length: 3, // Added History Tab
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.request_page), text: 'AI Order (S1)'),
                  Tab(icon: Icon(Icons.restaurant_menu), text: 'AI Chef'),
                  Tab(icon: Icon(Icons.history), text: 'History'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // --- TAB 1: Conversational Ordering (S1) ---
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                            // --- 1. THE CONVERSATION AREA ---
                            // This expands to fill all available space
                            Expanded(child: ChatMessageList(),),
                            // --- 2. THE TEXTING & VOICE AREA ---
                            ChatInputBar(),
                        ],
                      ),
                    ),
                    // --- TAB 2: AI Chef (Recipe Suggestion) ---
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) {
                          return Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => context.read<HomeCubit>().suggestRecipe(),
                                icon: const Icon(Icons.restaurant_menu),
                                label: Text(strings.suggestionButton),
                              ),
                              const SizedBox(height: 20),
                              if (state.geminiIsSuccessful)
                                Card(
                                  child: ListTile(
                                    title: Text(state.recipeName),
                                    subtitle: Text(state.ingredients.join(', ')),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    // --- TAB 3: Order History ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.orderHistoryTitle, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          // In a real app, this list would come from a BLoC
                          Expanded(
                            child: ListView(
                              children: [
                                _buildMetricCard(strings.orderHistoryTitle, strings.noOrders),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMetricCard(String title, String value) {
  return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
      ),
    );
  }
}

// --- TAB 1: AI Conversational Ordering (S1 USP) ---

  // --- WIDGET 1: THE CHAT LIST ---
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    // Connect to the cubit's state
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.isLoading && state.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final message = state.messages[index];
            final bool isFromUser = message.senderType == MessageSender.user;
  

            // Align chat bubbles
            return Align(
              alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
              child: ChatBubble(message: message, isFromUser: isFromUser),
            );
          },
        );
      },
    );
  }
}

  // --- WIDGET 2: THE CHAT BUBBLE ---
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isFromUser,
  });

  final ChatMessage message;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isFromUser ? Colors.green.shade100 : Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Text(
          message.text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

  // --- WIDGET 3: THE CHAT INPUT BAR ---
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      // Get the HomeCubit
      final cubit = context.read<HomeCubit>();
      
      // Call the Cubit's new "sendMessage" method
      // cubit.sendMessage(_controller.text.trim());
      
      // Or, call the Gemini prompt method
      cubit.submitOrderPrompt(_controller.text.trim());
      
      _controller.clear();
    }
  }

  void _sendVoiceOrder() {
    // TODO: Implement voice recording logic
    print("Voice recording started...");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white,
      child: Row(
        children: [
          // "Attach" icon
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: Show recipe suggestion, etc.
              context.read<HomeCubit>().suggestRecipe();
            },
          ),
          
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your order...',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          
          const SizedBox(width: 4),

          // Send or Voice button
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.teal.shade700,
            onPressed: _isTyping ? _sendMessage : _sendVoiceOrder,
            child: Icon(_isTyping ? Icons.send : Icons.mic),
          ),
        ],
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