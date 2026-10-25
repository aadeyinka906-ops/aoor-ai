import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AOOR AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Message {
  String text;
  bool isUser;

  Message({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'] as String,
        isUser: json['isUser'] as bool,
      );
}

class ChatSession {
  String title;
  List<Message> messages;

  ChatSession({required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        title: json['title'] as String,
        messages: (json['messages'] as List)
            .map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<ChatSession> _savedChats = [];
  List<Message> _msgs = [];
  bool _loading = false;
  bool _isLoadingChats = true;

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _storageKey = 'aoor_ai_chats';

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------- Persistence ----------
  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _savedChats = decoded
            .map((item) => ChatSession.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // If data is corrupted, start fresh
        _savedChats = [];
      }
    }

    // Start with a new chat if none exist
    if (_savedChats.isEmpty) {
      _startNewChat(initial: true);
    } else {
      // Load the most recent chat
      setState(() {
        _msgs = List.from(_savedChats.last.messages);
      });
    }

    setState(() {
      _isLoadingChats = false;
    });
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_savedChats.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // ---------- Chat management ----------
  void _startNewChat({bool initial = false}) {
    // Save current chat before starting a new one
    if (_msgs.isNotEmpty && !initial) {
      final title = _msgs
          .firstWhere((m) => m.isUser, orElse: () => _msgs.first)
          .text;

      // Avoid saving empty or duplicate sessions
      if (title.trim().isNotEmpty) {
        _savedChats.add(ChatSession(
          title: title.length > 40 ? '${title.substring(0, 40)}...' : title,
          messages: List.from(_msgs),
        ));
        _saveChats();
      }
    }

    setState(() {
      _msgs = [
        Message(
          text: "Ni Hao! Welcome to AOOR AI.\n\n"
              "I am your dedicated expert assistant for:\n"
              "• Chinese Government & University Scholarships\n"
              "• University Admissions & Application Procedures\n"
              "• Student Visa Processing (X1 & X2)\n"
              "• Nigerian Document Authentication, Legalization & Notarization\n\n"
              "How can I assist with your study-abroad journey today?",
          isUser: false,
        )
      ];
    });
  }

  void _loadSession(ChatSession session) {
    // Save current chat first
    if (_msgs.isNotEmpty) {
      final title = _msgs
          .firstWhere((m) => m.isUser, orElse: () => _msgs.first)
          .text;
      if (title.trim().isNotEmpty) {
        // Update existing or add new
        final existingIndex = _savedChats.indexWhere((c) => c.title == session.title);
        if (existingIndex != -1) {
          _savedChats[existingIndex] = ChatSession(
            title: session.title,
            messages: List.from(_msgs),
          );
        }
        _saveChats();
      }
    }

    setState(() {
      _msgs = List.from(session.messages);
    });
    Navigator.pop(context);
  }

  void _deleteSession(int index) {
    setState(() {
      _savedChats.removeAt(index);
    });
    _saveChats();
  }

  void _stop() {
    setState(() => _loading = false);
  }

  Future<void> _send({String? custom, int? editIdx}) async {
    final text = custom ?? _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (editIdx != null) {
        _msgs[editIdx].text = text;
      } else {
        _msgs.add(Message(text: text, isUser: true));
        if (custom == null) _ctrl.clear();
      }
      _loading = true;
    });

    _scrollDown();

    final aiMsg = Message(text: '', isUser: false);
    setState(() {
      _msgs.add(aiMsg);
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-3.5-flash-lite',
        apiKey: _apiKey,
        systemInstruction: Content.system(
          '''
You are AOOR AI — a professional, friendly, and highly knowledgeable consultant specializing in studying in China.

Your expertise covers:
- Chinese Government Scholarship (CSC) and university scholarships
- University admissions (Bachelor, Master, PhD)
- Student visa (X1 and X2) application process
- Nigerian document authentication, legalization, and notarization for China

IMPORTANT BEHAVIOR RULES:
1. Do NOT introduce yourself in every response. Only greet once at the beginning of a new conversation.
2. Answer the user's actual question thoroughly and clearly. Do not force the conversation back to document legalization unless the user asks about it.
3. Give detailed, structured answers. Break complex topics into clear steps or sections.
4. When mentioning phone numbers, emails, or websites, write them cleanly and correctly (example: +86 10 6609 6933 or studyinchina.edu.cn).
5. Be helpful, professional, and direct. Avoid unnecessary fluff.
6. Never use markdown asterisks (*) in your responses.
7. If the user asks a specific question, stay focused on that question.
''',
        ),
      );

      const maxRetries = 4;
      int attempt = 0;
      String finalReply = '';

      while (attempt < maxRetries) {
        try {
          final content = [Content.text(text)];
          final responseStream = model.generateContentStream(content);

          final buffer = StringBuffer();

          await for (final chunk in responseStream) {
            if (!mounted || !_loading) break;

            final chunkText = chunk.text ?? '';
            buffer.write(chunkText);

            setState(() {
              aiMsg.text = buffer.toString().replaceAll('*', '');
            });
            _scrollDown();
          }

          finalReply = buffer.toString().replaceAll('*', '');
          break;
        } catch (e) {
          attempt++;
          final errorStr = e.toString().toLowerCase();

          final isRetryable = errorStr.contains('503') ||
              errorStr.contains('high demand') ||
              errorStr.contains('unavailable') ||
              errorStr.contains('overloaded');

          if (!isRetryable || attempt >= maxRetries) {
            rethrow;
          }

          final waitSeconds = 1 << (attempt - 1);
          await Future.delayed(Duration(seconds: waitSeconds));
        }
      }

      if (!mounted) return;

      setState(() {
        aiMsg.text = finalReply.isNotEmpty
            ? finalReply
            : "Sorry, I couldn't generate a response. Please try again.";
        _loading = false;
      });
      _scrollDown();

      // Auto-save after every successful reply
      _autoSaveCurrentChat();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_msgs.isNotEmpty && !_msgs.last.isUser) {
          _msgs.last.text = "Error: ${e.toString()}";
        } else {
          _msgs.add(Message(text: "Error: ${e.toString()}", isUser: false));
        }
      });
    }
  }

  void _autoSaveCurrentChat() {
    if (_msgs.length <= 1) return; // only welcome message

    final title = _msgs
        .firstWhere((m) => m.isUser, orElse: () => _msgs.first)
        .text;

    final shortTitle =
        title.length > 40 ? '${title.substring(0, 40)}...' : title;

    // Check if this chat already exists in history
    final existingIndex = _savedChats.indexWhere((c) => c.title == shortTitle);

    if (existingIndex != -1) {
      _savedChats[existingIndex] = ChatSession(
        title: shortTitle,
        messages: List.from(_msgs),
      );
    } else {
      _savedChats.add(ChatSession(
        title: shortTitle,
        messages: List.from(_msgs),
      ));
    }

    _saveChats();
  }

  void _edit(int idx) {
    _ctrl.text = _msgs[idx].text;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: _ctrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _send(editIdx: idx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingChats) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AOOR AI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('China Admissions & Legalization Assistant',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _startNewChat(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Chat History',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                _startNewChat();
              },
            ),
            const Divider(),
            if (_savedChats.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No saved chats yet',
                    style: TextStyle(color: Colors.grey)),
              ),
            ..._savedChats.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;
              return ListTile(
                title: Text(s.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteSession(index),
                ),
                onTap: () => _loadSession(s),
              );
            }),
          ],
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Scholarships'),
                  onPressed: () => _send(
                      custom:
                          'I need detailed information about Chinese Government and university scholarships for undergraduate and master degrees.'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Admissions'),
                  onPressed: () => _send(
                      custom:
                          'What are the university admission requirements and step-by-step procedures for studying in China?'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Visa Processing'),
                  onPressed: () => _send(
                      custom:
                          'Please guide me through the Chinese student visa X1 and X2 processing requirements and steps.'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Legalization'),
                  onPressed: () => _send(
                      custom:
                          'Explain the full process of Nigerian document authentication, legalization, and notarization for use in China.'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _msgs.length,
              itemBuilder: (context, idx) {
                final m = _msgs[idx];
                return Align(
                  alignment:
                      m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? const Color(0xFF11172A)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.text,
                          style: TextStyle(
                            color: m.isUser ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        if (m.isUser) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _edit(idx),
                            child: const Align(
                              alignment: Alignment.bottomRight,
                              child: Text('Edit',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('AI is thinking... ',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _stop,
                    child: const Text('Stop',
                        style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText:
                          'Ask anything about China admissions & legalization...',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF11172A),
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _loading ? null : () => _send(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
