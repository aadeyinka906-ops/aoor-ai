import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
}

class ChatSession {
  String title;
  List<Message> messages;
  ChatSession({required this.title, required this.messages});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatSession> _savedChats = [];
  List<Message> _msgs = [];
  bool _loading = false;

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    _startNewChat(initial: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _startNewChat({bool initial = false}) {
    if (_msgs.isNotEmpty && !initial) {
      _savedChats.add(ChatSession(title: _msgs.first.text, messages: List.from(_msgs)));
    }
    setState(() {
      _msgs = [
        Message(
          text: "Ni Hao! Welcome to AOOR AI.\n\n"
                "I am your dedicated expert assistant strictly designed to guide you through:\n"
                "• Chinese Government & University Scholarships\n"
                "• University Admissions & Application Procedures\n"
                "• Student Visa Processing\n"
                "• Nigerian Document Authentication, Legalization & Notarization\n\n"
                "How can I assist with your study-abroad journey today?",
          isUser: false,
        )
      ];
    });
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _msgs = List.from(session.messages);
    });
    Navigator.pop(context);
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
        if (custom == null) { _ctrl.clear(); }
      }
      _loading = true;
    });

    _scrollDown();

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
        systemInstruction: Content.system(
          "You are AOOR AI, an expert consultant guiding students strictly through Chinese scholarships, university admissions, student visa processing, and Nigerian document authentication, legalization, and notarization. Never use markdown asterisks."
        ),
      );

      final content = [Content.text(text)];
      final response = await model.generateContent(content);

      String reply = response.text?.replaceAll('*', '') ?? "No response generated from AI.";

      if (!mounted) return;
      setState(() {
        _msgs.add(Message(text: reply, isUser: false));
        _loading = false;
      });
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _msgs.add(Message(text: "Error: ${e.toString()}", isUser: false));
      });
    }
  }

  void _edit(int idx) {
    _ctrl.text = _msgs[idx].text;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: _ctrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _send(editIdx: idx); }, child: const Text('Update')),
        ],
      ),
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AOOR AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('China Admissions & Legalization Assistant', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
              child: Text('Chat History', style: TextStyle(color: Colors.white, fontSize: 20)),
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
            ..._savedChats.map((s) => ListTile(
              title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _loadSession(s),
            )),
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
                  onPressed: () => _send(custom: 'I need information about Chinese Government and university scholarships for undergraduate and master degrees.'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Admissions'),
                  onPressed: () => _send(custom: 'What are the university admission requirements and procedures for studying in China?'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Visa Processing'),
                  onPressed: () => _send(custom: 'Guide me through Chinese student visa X1 and X2 processing requirements.'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Legalization'),
                  onPressed: () => _send(custom: 'Explain Nigerian document authentication, legalization, and notarization steps for China.'),
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
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: m.isUser ? const Color(0xFF11172A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.text,
                          style: TextStyle(color: m.isUser ? Colors.white : Colors.black87),
                        ),
                        if (m.isUser) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _edit(idx),
                            child: const Align(
                              alignment: Alignment.bottomRight,
                              child: Text('Edit', style: TextStyle(color: Colors.white70, fontSize: 10)),
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
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('AI is thinking... '),
                  const SizedBox(width: 8),
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 16),
                  TextButton(onPressed: _stop, child: const Text('Stop', style: TextStyle(color: Colors.red)))
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything about China admissions & legalization...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: const Color(0xFF11172A),
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _send(),
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
