import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'book_detail_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  int? _currentConversationId;
  String _currentTitle = 'Percakapan Baru';
  bool _isLoading = false;
  bool _isSending = false;
  bool _isLoadingConversations = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Data Methods ────────────────────────────────────

  Future<void> _loadConversations() async {
    setState(() => _isLoadingConversations = true);
    final res = await ApiService.getConversations();
    if (res['status'] == 200 && mounted) {
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(res['data']['data'] ?? []);
        _isLoadingConversations = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingConversations = false);
    }
  }

  Future<void> _createNewConversation() async {
    final res = await ApiService.createConversation();
    if (res['status'] == 201 && mounted) {
      final conv = res['data']['data'];
      setState(() {
        _currentConversationId = conv['id'];
        _currentTitle = conv['title'];
        _messages = [];
      });
      await _loadConversations();
      if (Navigator.canPop(context)) Navigator.pop(context); // close drawer
    }
  }

  Future<void> _loadMessages(int conversationId) async {
    setState(() {
      _isLoading = true;
      _currentConversationId = conversationId;
    });

    final res = await ApiService.getMessages(conversationId);
    if (res['status'] == 200 && mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(res['data']['data'] ?? []);
        _currentTitle = res['data']['conversation']?['title'] ?? 'Percakapan';
        _isLoading = false;
      });
      _scrollToBottom();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Jika belum ada conversation, buat dulu
    if (_currentConversationId == null) {
      final res = await ApiService.createConversation();
      if (res['status'] == 201) {
        final conv = res['data']['data'];
        setState(() {
          _currentConversationId = conv['id'];
          _currentTitle = conv['title'];
        });
      } else {
        return;
      }
    }

    _messageController.clear();
    setState(() {
      _isSending = true;
      _messages.add({
        'role': 'user',
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    final res = await ApiService.sendChatMessage(_currentConversationId!, text);
    if (res['status'] == 200 && mounted) {
      final data = res['data'];
      setState(() {
        _messages.add({
          'role': 'assistant',
          'message': data['reply'],
          'books': data['books'],
          'created_at': DateTime.now().toIso8601String(),
        });
        _currentTitle = data['conversation']?['title'] ?? _currentTitle;
        _isSending = false;
      });
      _scrollToBottom();
      _loadConversations(); // refresh sidebar
    } else if (mounted) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'message': 'Maaf, terjadi kesalahan. Silakan coba lagi.',
          'created_at': DateTime.now().toIso8601String(),
        });
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _deleteConversation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Percakapan?'),
        content: const Text('Semua pesan dalam percakapan ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteConversation(id);
      if (mounted) {
        if (_currentConversationId == id) {
          setState(() {
            _currentConversationId = null;
            _messages = [];
            _currentTitle = 'Percakapan Baru';
          });
        }
        _loadConversations();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── UI Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _currentConversationId == null && _messages.isEmpty
                ? _buildWelcomeView()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF2B5A41)),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B5A41), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Devora AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(
                  _currentTitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_rounded, color: Color(0xFF2B5A41)),
          tooltip: 'Chat Baru',
          onPressed: () {
            setState(() {
              _currentConversationId = null;
              _messages = [];
              _currentTitle = 'Percakapan Baru';
            });
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2B5A41), Color(0xFF4CAF50)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Devora AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // New Chat Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentConversationId = null;
                          _messages = [];
                          _currentTitle = 'Percakapan Baru';
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Chat Baru'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2B5A41),
                        side: const BorderSide(color: Color(0xFF2B5A41)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade200, height: 1),
            // Conversations List
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Riwayat Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
            ),
            Expanded(
              child: _isLoadingConversations
                  ? const Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('Belum ada percakapan', style: TextStyle(color: Colors.grey.shade400)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conv = _conversations[index];
                            final isActive = conv['id'] == _currentConversationId;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF2B5A41).withOpacity(0.08) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 18,
                                  color: isActive ? const Color(0xFF2B5A41) : Colors.grey.shade400,
                                ),
                                title: Text(
                                  conv['title'] ?? 'Percakapan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                    color: isActive ? const Color(0xFF2B5A41) : const Color(0xFF1E293B),
                                  ),
                                ),
                                subtitle: conv['last_message'] != null
                                    ? Text(
                                        conv['last_message'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.grey.shade400),
                                  onPressed: () => _deleteConversation(conv['id']),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _loadMessages(conv['id']);
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B5A41), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2B5A41).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Devora AI',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Asisten Pustakawan Cerdas',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            // Suggestion Cards
            _buildSuggestionCard(
              icon: Icons.search,
              title: 'Cari Buku',
              subtitle: '"Carikan buku tentang sejarah Indonesia"',
            ),
            const SizedBox(height: 12),
            _buildSuggestionCard(
              icon: Icons.star_rounded,
              title: 'Rekomendasi',
              subtitle: '"Buku apa yang paling populer?"',
            ),
            const SizedBox(height: 12),
            _buildSuggestionCard(
              icon: Icons.category_rounded,
              title: 'Kategori',
              subtitle: '"Tampilkan buku kategori fiksi"',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard({required IconData icon, required String title, required String subtitle}) {
    return GestureDetector(
      onTap: () {
        // Remove quotes from subtitle for the query
        final query = subtitle.replaceAll('"', '');
        _messageController.text = query;
        _sendMessage();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2B5A41).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF2B5A41), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _buildMessageBubble(msg, isUser);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B5A41), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF2B5A41) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF2B5A41).withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildFormattedText(msg['message'] ?? '', isUser),
                ),
                // Book recommendations
                if (!isUser && msg['books'] != null && (msg['books'] as List).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (msg['books'] as List).length,
                      itemBuilder: (context, i) {
                        final book = (msg['books'] as List)[i];
                        return _buildBookCard(book);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 != 0 && i < parts.length - 1) {
        spans.add(TextSpan(
          text: parts[i],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else {
        String content = parts[i];
        if (i % 2 != 0 && i == parts.length - 1) {
          content = '**$content';
        }
        spans.add(TextSpan(text: content));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUser ? Colors.white : const Color(0xFF1E293B),
          fontSize: 14,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final title = book['title']?.toString() ?? 'Tanpa Judul';
    final initials = title.length > 1 ? title.substring(0, 2).toUpperCase() : title.toUpperCase();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: 75,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2B5A41).withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: book['cover_image'] != null
                    ? DecorationImage(image: NetworkImage(book['cover_image']), fit: BoxFit.cover)
                    : null,
              ),
              child: book['cover_image'] == null
                  ? Center(
                      child: Text(initials, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2B5A41).withOpacity(0.3))),
                    )
                  : null,
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book['author'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B5A41), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF2B5A41).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Tanyakan tentang buku...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSending
                      ? [Colors.grey.shade300, Colors.grey.shade400]
                      : [const Color(0xFF2B5A41), const Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isSending
                    ? []
                    : [BoxShadow(color: const Color(0xFF2B5A41).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(
                _isSending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
