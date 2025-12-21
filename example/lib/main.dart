import 'package:beon_widget_sdk/beon_widget_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

/// Example app demonstrating the Beon Widget SDK
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beon Widget Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BeonChatWidget(
      config: BeonConfig(
        // Replace with your actual API key from https://beon.chat
        apiKey: 'YOUR_API_KEY_HERE',

        // Optional: Override settings from API
        primaryColor: Colors.indigo,
        position: BeonPosition.bottomRight,

        // Customize header
        headerTitle: 'Support Chat',
        headerSubtitle: 'We typically reply within minutes',

        // Enable/disable features
        enableSounds: true,
        // enablePollingFallback: false, // Disabled by default
      ),
    );
  }
}
