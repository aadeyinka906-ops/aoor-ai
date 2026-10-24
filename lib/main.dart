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
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loggedIn = false;
  String _userEmail = '';

  void _loginWithEmail() {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() {
      _userEmail = _emailCtrl.text.trim();
      _loggedIn = true;
    });
  }

  void _showGoogleAccountPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text('G', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 12),
                const Text('Sign in with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Choose an account to continue to AOOR AI', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF0F172A), child: Text('A', style: TextStyle(color: Color(0xFFD97706)))),
              title: const Text('Adeniyi Adeyinka'),
              subtitle: const Text('adeniyi.adeyinka@gmail.com'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _userEmail = 'adeniyi.adeyinka@gmail.com';
                  _loggedIn = true;
                });
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFD97706), child: Text('AO', style: TextStyle(color: Color(0xFF0F172A)))),
              title: const Text('AOOR AI Scholar'),
              subtitle: const Text('aoor.ai.official@gmail.com'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _userEmail = 'aoor.ai.official@gmail.com';
                  _loggedIn = true;
                });
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person_add, color: Colors.white, size: 18)),
              title: const Text('Use another account'),
              onTap: () {
                Navigator.pop(context);
                // Fallback or prompt for custom email
                setState(() {
                  _userEmail = 'custom.user@gmail.com';
                  _loggedIn = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 65, height: 65, decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('AO', style: TextStyle(color: Color(0xFF0F172A), fontSize: 26, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 20),
                const Text('AOOR AI', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Sign in to save your chat sessions & records', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(controller: _emailCtrl, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Email address', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Password', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 45, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: const Color(0xFF0F172A)), onPressed: _loginWithEmail, child: const Text('Sign In with Email', style: TextStyle(fontWeight: FontWeight.bold)))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 45, child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30), foregroundColor: Colors.white),
                  onPressed: _showGoogleAccountPicker,
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFFD97706)),
                  label: const Text('Continue with Google'),
                )),
              ],
            ),
          ),
        ),
      );
    }
    return ChatScreen(userEmail: _userEmail, onLogout: () => setState(() => _loggedIn = false));
  }
}

class Message {
  String text;
  final bool isUser;
  String? attachment;
  Message({required this.text, required this.isUser, this.attachment});
}

class ChatSession {
  final String title;
  final List<Message> messages;
  ChatSession({required this.title, required this.messages});
}

class ChatScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback onLogout;
  const ChatScreen({super.key, required this.userEmail, required this.onLogout});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatSession> _savedChats = [];
  List<Message> _msgs = [];
  bool _loading = false;
  String? _file;
  StreamSubscription? _sub;

  static const String _apiKey = 'AQ.Ab8RN6JyQ8p_6JaCyIMR8Q-J8wbOiBLdLPPQdcvXgVb1Sp8eLA';

  @override
  void initState() {
    super.initState();
    _startNewChat(initial: true);
  }

  void _startNewChat({bool initial = false}) {
    if (_msgs.isNotEmpty && !initial) {
      _savedChats.add(ChatSession(title: _msgs.first.text, messages: List.from(_msgs)));
    }
    setState(() {
      _msgs = [Message(text: "Ni Hao! I am AOOR AI, your assistant for Chinese admissions and Nigerian document legalizations.", isUser: false)];
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
    if (text.isEmpty && _file == null) return;
    final att = _file;

    setState(() {
      if (editIdx != null) {
        _msgs[editIdx].text = text;
      } else {
        _msgs.add(Message(text: text.isEmpty ? "Uploaded file: $att" : text, isUser: true, attachment: att));
        if (custom == null) { _ctrl.clear(); _file = null; }
      }
      _loading = true;
    });

    _scrollDown();

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$_apiKey');
      final req = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({"contents": [{"parts": [{"text": "You are AOOR AI, consultant for Chinese admissions and Nigerian document legalizations. No markdown asterisks (**). Query: $text"}]}]});

      final streamed = await req.send();
      _sub = streamed.stream.listen((_) {});
      final res = await http.Response.fromStream(streamed);

      String reply = "Error connecting to AI.";
      if (res.statusCode == 200) {
        reply = jsonDecode(res.body)['candidates'][0]['content']['parts'][0]['text'].replaceAll('**', '');
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

  void _pickFile() {
    final fileCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Connect Device File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: fileCtrl,
                decoration: const InputDecoration(hintText: 'Enter file name (e.g. WAEC_Result.pdf)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                onPressed: () {
                  if (fileCtrl.text.isNotEmpty) {
                    setState(() => _file = fileCtrl.text.trim());
                    Navigator.pop(context);
                  }
                },
                child: const Text('Attach File'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AOOR AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(widget.userEmail, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Color(0xFFD97706)), tooltip: 'New Chat', onPressed: () => _startNewChat()),
          IconButton(icon: const Icon(Icons.logout, size: 18, color: Colors.grey), onPressed: widget.onLogout),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0F172A)),
              accountName: const Text('AOOR AI Assistant'),
              accountEmail: Text(widget.userEmail),
              currentAccountPicture: CircleAvatar(backgroundColor: const Color(0xFFD97706), child: const Text('AO', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold))),
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
                ActionChip(label: const Text('Belt & Road', style: TextStyle(fontSize: 11)), onPressed: () => _send(custom: 'Tell me about Belt and Road scholarship.')),
                const SizedBox(width: 6),
                ActionChip(label: const Text('Legalization', style: TextStyle(fontSize: 11)), onPressed: () => _send(custom: 'What are Nigerian document authentication steps?')),
                const SizedBox(width: 6),
                ActionChip(label: const Text('Robotics', style: TextStyle(fontSize: 11)), onPressed: () => _send(custom: 'List top robotics engineering schools in China.')),
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
          if (_file != null)
            Container(color: Colors.amber.shade50, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Row(children: [
              const Icon(Icons.attach_file, size: 14, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Expanded(child: Text('Attached File: $_file', style: const TextStyle(fontSize: 11))),
              IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () => setState(() => _file = null))
            ])),
          Container(
            padding: const EdgeInsets.all(8), color: Colors.white,
            child: Row(children: [
              IconButton(icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF0F172A)), onPressed: _pickFile),
              Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Ask anything...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8)))),
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
          if (msg.attachment != null) Text('File: ${msg.attachment}', style: const TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
          Text(msg.text, style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87, fontSize: 13)),
          if (msg.isUser) GestureDetector(onTap: () => _edit(i), child: const Align(alignment: Alignment.centerRight, child: Text('Edit', style: TextStyle(color: Color(0xFFD97706), fontSize: 9, decoration: TextDecoration.underline)))),
        ]),
      ),
    );
  }
}
