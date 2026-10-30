import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AOOR AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0A2540),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A2540)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// ==================== MODELS ====================
class Message {
  String text;
  bool isUser;
  String id;

  Message({required this.text, required this.isUser, String? id})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'id': id,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'],
        isUser: json['isUser'],
        id: json['id'],
      );
}

class ChatSession {
  String id;
  String title;
  List<Message> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        title: json['title'],
        messages: (json['messages'] as List)
            .map((m) => Message.fromJson(m))
            .toList(),
      );
}

// ==================== AUTH WRAPPER ====================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    setState(() {
      _isLoggedIn = name != null && name.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn ? const ChatScreen() : const LandingPage();
  }
}

// ==================== LANDING PAGE ====================
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('logo.png', width: 130, height: 130),
              const SizedBox(height: 20),
              const Text(
                'AOOR AI',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2540),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Guide to Studying in China',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 36),
              const Text(
                'Helping Nigerian students with:\n\n'
                '• University Admissions\n'
                '• Scholarships (CSC & others)\n'
                '• Student Visa Guidance\n'
                '• Document Legalization\n'
                '• Maths solutions & Exam prep',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2540),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(color: Color(0xFF0A2540)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SIGN UP PAGE ====================
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  bool loading = false;

  Future<void> _signUp() async {
    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', nameCtrl.text.trim());
    await prefs.setString('user_email', emailCtrl.text.trim());

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2540),
                  foregroundColor: Colors.white,
                ),
                onPressed: loading ? null : _signUp,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LOGIN PAGE ====================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    if (emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email')),
      );
      return;
    }

    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', 'User');
    await prefs.setString('user_email', emailCtrl.text.trim());

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2540),
                  foregroundColor: Colors.white,
                ),
                onPressed: loading ? null : _login,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SETTINGS PAGE ====================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Account?'),
                  content: const Text('This will permanently delete your data.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteAccount(context);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==================== CHAT SCREEN ====================
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
  String _userName = 'User';

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'User';

    final data = prefs.getString('chats');
    if (data != null) {
      final list = jsonDecode(data) as List;
      _savedChats = list.map((e) => ChatSession.fromJson(e)).toList();
    }

    if (_savedChats.isNotEmpty) {
      _msgs = List.from(_savedChats.last.messages);
    } else {
      _startNewChat(initial: true);
    }
    setState(() {});
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'chats',
      jsonEncode(_savedChats.map((e) => e.toJson()).toList()),
    );
  }

  void _startNewChat({bool initial = false}) {
    if (!initial && _msgs.length > 1) {
      final title = _msgs.firstWhere((m) => m.isUser, orElse: () => _msgs.first).text;
      _savedChats.add(ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.length > 40 ? '${title.substring(0, 40)}...' : title,
        messages: List.from(_msgs),
      ));
      _saveChats();
    }

    setState(() {
      _msgs = [
        Message(
          text: "Ni Hao $_userName! 👋\n\nI'm AOOR AI — your guide for studying in China.\n\nI can help you with admissions, scholarships, visa, document legalization, maths problems, and exam preparation.\n\nHow can I assist you today?",
          isUser: false,
        )
      ];
    });
  }

  Future<void> _send({String? custom, int? editIndex}) async {
    final text = custom ?? _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (editIndex != null) {
        _msgs[editIndex].text = text;
      } else {
        _msgs.add(Message(text: text, isUser: true));
      }
      _ctrl.clear();
      _loading = true;
    });
    _scrollDown();

    final aiMsg = Message(text: '', isUser: false);
    setState(() => _msgs.add(aiMsg));

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(
          '''
You are AOOR AI, a helpful expert assistant for Nigerian students who want to study in China.

You help with:
- Chinese university admissions
- Scholarships (CSC, university, Belt & Road)
- Student visa (X1 & X2)
- Nigerian document legalization
- Solving mathematics equations step-by-step
- CSSA / scholarship exam preparation questions

Rules:
- Be clear, structured and helpful
- Do not introduce yourself in every message
- When solving maths, show step-by-step working
- Never use markdown asterisks (*)
''',
        ),
      );

      final response = await model.generateContent([Content.text(text)]);
      final reply = response.text?.replaceAll('*', '') ?? 'No response generated.';

      setState(() {
        aiMsg.text = reply;
        _loading = false;
      });
      _scrollDown();
      _autoSave();
    } catch (e) {
      setState(() {
        aiMsg.text = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _autoSave() {
    if (_msgs.length <= 1) return;
    final title = _msgs.firstWhere((m) => m.isUser).text;
    final shortTitle = title.length > 40 ? '${title.substring(0, 40)}...' : title;

    final existing = _savedChats.indexWhere((c) => c.title == shortTitle);
    if (existing >= 0) {
      _savedChats[existing].messages = List.from(_msgs);
    } else {
      _savedChats.add(ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: shortTitle,
        messages: List.from(_msgs),
      ));
    }
    _saveChats();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('logo.png', height: 32),
            const SizedBox(width: 10),
            const Text('AOOR AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _startNewChat(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0A2540)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chat History',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(_userName, style: const TextStyle(color: Colors.white70)),
                ],
              ),
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
            ..._savedChats.map((chat) {
              return ListTile(
                title: Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    setState(() {
                      _savedChats.removeWhere((c) => c.id == chat.id);
                    });
                    _saveChats();
                  },
                ),
                onTap: () {
                  setState(() => _msgs = List.from(chat.messages));
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length,
              itemBuilder: (context, index) {
                final m = _msgs[index];
                return Align(
                  alignment: m.isUser return Align(
                    alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      decoration: BoxDecoration(
                        color: m.isUser ? const Color(0xFF0A2540) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
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
                          if (!m.isUser) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () => _copyText(m.text),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 18),
                                  onPressed: () {
                                    final lastUser = _msgs.lastWhere((e) => e.isUser);
                                    _send(custom: lastUser.text);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Thanks for the feedback!')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Thanks, we will improve')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                          if (m.isUser)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _ctrl.text = m.text;
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Edit Message'),
                                      content: TextField(
                                        controller: _ctrl,
                                        maxLines: 3,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _send(editIndex: index);
                                          },
                                          child: const Text('Update'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Edit', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('AOOR AI is thinking...'),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Ask anything...',
                        border: InputBorder.none,
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF0A2540)),
                    onPressed: _loading ? null : () => _send(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
              }
