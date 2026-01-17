import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


class Post {
  String text;
  String? imagePath;
  int likes;

  Post({required this.text, this.imagePath, this.likes = 0});

  Map<String, dynamic> toJson() => {
    'text': text,
    'imagePath': imagePath,
    'likes': likes,
  };

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      text: json['text'],
      imagePath: json['imagePath'],
      likes: json['likes'],
    );
  }
}

class PostStorage {
  static const String key = "posts";

  static Future<List<Post>> loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(key) ?? [];
    return data.map((e) => Post.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> savePosts(List<Post> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final data = posts.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(key, data);
  }
}
List<Post> globalPosts = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved posts from SharedPreferences
  globalPosts = await PostStorage.loadPosts();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier =
  ValueNotifier(ThemeMode.light);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: MyApp.themeNotifier,
      builder: (_, ThemeMode mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PRODIGY Social Media Platform',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          home: const LoginPage(),
        );
      },
    );
  }
}


/* ===================== LOGIN PAGE ===================== */

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "PRODIGY SOCIAL MEDIA PLATFORM",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const TextField(decoration: InputDecoration(labelText: "Email")),
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                );
              },
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== SIGNUP PAGE ===================== */

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "Name")),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: "Email")),
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== HOME SCREEN ===================== */

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final pages = const [
    FeedPage(),
    CreatePostPage(),
    ChatListPage(),
    NotificationsPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  final titles = const [
    "Feed",
    "Create Post",
    "Chats",
    "Notifications",
    "Profile",
    "Settings",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[index])),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

/* ===================== FEED PAGE ===================== */

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  void like(Post post) async {
    setState(() => post.likes++);
    await PostStorage.savePosts(globalPosts);
  }

  void edit(Post post) async {
    final controller = TextEditingController(text: post.text);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Post"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              post.text = controller.text;
              await PostStorage.savePosts(globalPosts);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: globalPosts.length,
      itemBuilder: (_, i) {
        final post = globalPosts[i];
        return Card(
          margin: const EdgeInsets.all(10),
          child: Column(
            children: [
              if (post.imagePath != null)
                Image.file(File(post.imagePath!), height: 200),
              ListTile(
                title: Text(post.text),
                subtitle: Text("Likes: ${post.likes}"),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite),
                    onPressed: () => like(post),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => edit(post),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

/* ===================== CREATE POST ===================== */

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController controller = TextEditingController();
  File? selectedImage;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => selectedImage = File(image.path));
    }
  }

  void post() async {
    if (controller.text.isEmpty && selectedImage == null) return;

    globalPosts.insert(
      0,
      Post(
        text: controller.text,
        imagePath: selectedImage?.path,
      ),
    );

    await PostStorage.savePosts(globalPosts);

    controller.clear();
    selectedImage = null;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Post saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          if (selectedImage != null)
            Image.file(selectedImage!, height: 150),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: pickImage,
              ),
              ElevatedButton(onPressed: post, child: const Text("Post")),
            ],
          )
        ],
      ),
    );
  }
}

/* ===================== CHAT LIST ===================== */

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, i) => ListTile(
        title: Text("User $i"),
        subtitle: const Text("Tap to chat"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatPage(user: "User $i")),
          );
        },
      ),
    );
  }
}

/* ===================== CHAT PAGE ===================== */

class ChatPage extends StatelessWidget {
  final String user;
  const ChatPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user)),
      body: Column(
        children: [
          const Expanded(
            child: Center(child: Text("Chat messages here")),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Type message",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== NOTIFICATIONS ===================== */

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(title: Text("New like on your post")),
        ListTile(title: Text("New follower")),
        ListTile(title: Text("Message received")),
      ],
    );
  }
}

/* ===================== PROFILE ===================== */

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          SizedBox(height: 10),
          Text("Username", style: TextStyle(fontSize: 18)),
          Text("Bio goes here"),
        ],
      ),
    );
  }
}

/* ===================== SETTINGS PAGE ===================== */

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.person),
          title: Text("Account"),
        ),
        const ListTile(
          leading: Icon(Icons.lock),
          title: Text("Privacy"),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode),
          title: const Text("Dark Mode"),
          value: MyApp.themeNotifier.value == ThemeMode.dark,
          onChanged: (value) {
            MyApp.themeNotifier.value =
            value ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text("Logout"),
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
            );
          },
        ),
      ],
    );
  }
}
