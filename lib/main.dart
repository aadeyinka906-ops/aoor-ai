import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() => runApp(const AOORApp());

class AOORApp extends StatelessWidget {
  const AOORApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A), secondary: const Color(0xFFD97706)),
      ),
      home: const ChatScreen(),
    );
  }
}

class Message {
  String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

class ChatSession {
  final String title;
  final List<Message> messages;
  ChatSession({required this.title, required this.messages});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatSession> _savedChats = [];
  List<Message> _msgs = [];
  bool _loading = false;
  StreamSubscription? _sub;

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    _startNewChat(initial: true);
  }  void _startNewChat({bool initial = false}) {
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
    _sub?.cancel();
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
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');
      final req = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          "contents": [{
            "parts": [{
              "text": "You are AOOR AI, an expert consultant guiding students through Chinese scholarships, university admissions, student visa processing, and Nigerian document authentication, legalization, and notarization. No markdown asterisks (**). Query: $text"
            }]
          }]
        });

      final streamed = await req.send();
      _sub = streamed.stream.listen((_) {});
      final res = await http.Response.fromStream(streamed);

      String reply = "Error connecting to AI.";
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          reply = data['candidates'][0]['content']['parts'][0]['text'].replaceAll('**', '');
        } else {
          reply = "No response generated from AI.";
        }
      } else {
        reply = "API Error (${res.statusCode}): Check your API key configuration.";
      }
      if (!mounted) return;
      setState(() { _msgs.add(Message(text: reply, isUser: false)); _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _msgs.add(Message(text: "Request stopped or network error.", isUser: false)); _loading = false; });
    }
    _scrollDown();
  }

  void _edit(int idx) {
    _ctrl.text = _msgs[idx].text;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message', style: TextStyle(fontSize: 14)),
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
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 1,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AOOR AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text('China Admissions & Legalization Assistant', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Color(0xFFD97706)), tooltip: 'New Chat', onPressed: () => _startNewChat()),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0F172A)),
              accountName: Text('AOOR AI Assistant'),
              accountEmail: Text('Expert Guidance for Students'),
              currentAccountPicture: CircleAvatar(backgroundColor: Color(0xFFD97706), child: Text('AO', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold))),
            ),
            ListTile(
              leading: const Icon(Icons.add_comment_rounded, color: Color(0xFFD97706)),
              title: const Text('Start New Chat'),
              onTap: () { _startNewChat(); Navigator.pop(context); },
            ),
            const Divider(),
            const Padding(padding: EdgeInsets.all(12), child: Text('Saved Chats History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            if (_savedChats.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('No saved chats yet.', style: TextStyle(fontSize: 11, color: Colors.grey))),
            for (var session in _savedChats)
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, size: 18),
                title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                onTap: () => _loadSession(session),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal, 
              padding: const EdgeInsets.symmetric(horizontal: 8), 
              children: [
                ActionChip(label: const Text('Scholarships', style: TextStyle(fontSize: 11)), onPressed: () => _send(custom: 'Tell me about Chinese government and university scholarships.')),
                const SizedBox(width: 6),
                ActionChip(label: const Text('Admissions', style: TextStyle(fontSize: 11)), onPressed: () => _send(custom: 'What are the steps for Chinese university admissions?')),
                const SizedBox(width: 6),
                ActionChip(label: const Text('Visa Processing', style: TextStyle(fontSize: 11)), onPressed: () => _send(custom: 'Guide me through Chinese student visa processing.')),
                const SizedBox(width: 6),
                ActionChip(label: const Text('Legalization', style: TextStyle(fontSize: 11)), onPressed: () => _send(custom: 'Explain document authentication, legalization, and notarization for China.')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.all(12), itemCount: _msgs.length, itemBuilder: (_, i) => _bubble(_msgs[i], i))),
          if (_loading)
            Padding(padding: const EdgeInsets.all(8), child: Row(children: [
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              const Text('Thinking...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              const Spacer(),
              TextButton(onPressed: _stop, child: const Text('Stop', style: TextStyle(color: Colors.red, fontSize: 11)))
            ])),
          Container(
            padding: const EdgeInsets.all(8), color: Colors.white,
            child: Row(children: [
              Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Ask anything about China admissions & legalization...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8)))),
              CircleAvatar(radius: 18, backgroundColor: const Color(0xFF0F172A), child: IconButton(icon: const Icon(Icons.send_rounded, color: Color(0xFFD97706), size: 16), onPressed: () => _send()))
            ]),
          )
        ],
      ),
    );
  }

  Widget _bubble(Message msg, int i) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.text, style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87, fontSize: 13)),
          if (msg.isUser) GestureDetector(onTap: () => _edit(i), child: const Align(alignment: Alignment.centerRight, child: Text('Edit', style: TextStyle(color: Color(0xFFD97706), fontSize: 9, decoration: TextDecoration.underline)))),
        ]),
      ),
    );
  }
}
