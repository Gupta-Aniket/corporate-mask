import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(CorporateMaskApp());
}

class CorporateMaskApp extends StatelessWidget {
  CorporateMaskApp({super.key});
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String? apiKey;
  bool isLoading = false;
  final inputController = TextEditingController();
  final outputController = TextEditingController();
  Map<String, String> variants = {};
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _loadApiKey();
  }

  @override
  void dispose() {
    _slideController.dispose();
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('apiKey');
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', key);
    setState(() {
      apiKey = key;
    });
  }

  Future<bool> _validateApiKey(String key) async {
    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key';
      final body = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Test message: Please return a short success confirmation.",
              },
            ],
          },
        ],
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result["candidates"] != null;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  String buildPrompt(String userInput) {
    return '''
Given the following message, generate 4 variants:
- "formal": corporate pleasing, highly professional tone polite for senior level managers etc .
- "semi_formal": corporate pleasing Semi-formal, polite for colleagues.
- "casual": corporate pleasing Friendly casual internal tone.
- "f_it": Brutally honest but still corporate-safe try to be pleasing.

Output STRICT valid JSON with keys: "formal", "semi_formal", "casual", "f_it".
Do not include any markdown, explanations or commentary. Just output raw valid JSON.

Here is the message:
"$userInput"
''';
  }

  Future<void> generateVariants() async {
    final text = inputController.text.trim();
    if (text.isEmpty || apiKey == null) return;

    setState(() {
      isLoading = true;
      variants.clear();
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';
      final body = {
        "contents": [
          {
            "parts": [
              {"text": buildPrompt(text)},
            ],
          },
        ],
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final raw =
            result["candidates"]?[0]["content"]["parts"][0]["text"] ?? "";
        final cleaned = raw.replaceAll(RegExp(r"^```json|```"), '').trim();
        final parsed = jsonDecode(cleaned);

        setState(() {
          variants = Map<String, String>.from(parsed);
        });

        // Animate results appearance
        _slideController.forward();

        // Success haptic feedback
        HapticFeedback.mediumImpact();

        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Variants generated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        _showError("Failed to generate variants. Please try again.");
      }
    } catch (e) {
      _showError(
        "Something went wrong. Please check your connection and try again.",
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showCopySuccess() {
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.content_copy_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Copied to clipboard'),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget buildApiKeyInput() {
    final controller = TextEditingController();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "API Setup",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter your Gemini API key to start transforming your messages with AI-powered corporate communication styles",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse("https://aistudio.google.com/app/apikey"),
                  );
                },
                child: Text("Get your key here"),
              ),
              const SizedBox(height: 40),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: "API Key",
                          hintText: "Enter your Gemini API key",
                          prefixIcon: const Icon(Icons.vpn_key_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _validateAndSaveKey(controller),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () => _validateAndSaveKey(controller),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text("Validate & Save"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Your API key is stored securely on your device",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _validateAndSaveKey(TextEditingController controller) async {
    final key = controller.text.trim();
    if (key.isEmpty) return;

    setState(() => isLoading = true);
    final valid = await _validateApiKey(key);
    setState(() => isLoading = false);

    if (valid) {
      await _saveApiKey(key);
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
      _showError("Invalid API key. Please check and try again.");
    }
  }

  Widget buildVariantCard(String mode, String text) {
    final displayName = mode
        .replaceAll("_", " ")
        .split(" ")
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(" ");

    final icon = _getIconForMode(mode);
    final color = _getColorForMode(mode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            outputController.text = text;
          });
          HapticFeedback.selectionClick();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForMode(String mode) {
    switch (mode) {
      case 'formal':
        return Icons.business_center_rounded;
      case 'semi_formal':
        return Icons.groups_rounded;
      case 'casual':
        return Icons.sentiment_satisfied_rounded;
      case 'f_it':
        return Icons.whatshot_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  Color _getColorForMode(String mode) {
    switch (mode) {
      case 'formal':
        return Colors.indigo;
      case 'semi_formal':
        return Colors.blue;
      case 'casual':
        return Colors.green;
      case 'f_it':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget buildMainScreen() {
    FocusNode focusNode = FocusNode();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Corporate Mask"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'reset') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Reset API Key"),
                        content: const Text(
                          "Are you sure you want to remove your saved API key?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Reset"),
                          ),
                        ],
                      ),
                );

                if (confirmed == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('apiKey');
                  setState(() {
                    apiKey = null;
                    variants.clear();
                    inputController.clear();
                    outputController.clear();
                  });
                }
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded),
                        SizedBox(width: 8),
                        Text("Reset API Key"),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Your Message",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      focusNode: focusNode,
                      controller: inputController,
                      decoration: InputDecoration(
                        hintText: "Type your message here...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  focusNode.unfocus();
                                  generateVariants();
                                },
                        icon:
                            isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.auto_fix_high_rounded),
                        label: const Text("Generate Variants"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (variants.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                "Choose Your Style",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children:
                      variants.entries.map((entry) {
                        return buildVariantCard(entry.key, entry.value);
                      }).toList(),
                ),
              ),
            ],
            if (variants.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.text_snippet,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Generated Text",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              if (outputController.text.isNotEmpty) {
                                Clipboard.setData(
                                  ClipboardData(text: outputController.text),
                                );
                                _showCopySuccess();
                              }
                            },
                            icon: const Icon(Icons.content_copy_rounded),
                            tooltip: "Copy to clipboard",
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: outputController,
                        decoration: InputDecoration(
                          hintText: "Your converted text will appear here",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),

                        maxLines: null,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return apiKey == null ? buildApiKeyInput() : buildMainScreen();
  }
}
