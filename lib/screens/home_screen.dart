// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackautomat/managers/stack_manager.dart';
import 'package:snackautomat/providers/coin_provider.dart';
import 'package:snackautomat/providers/secure_storage_provider.dart';
import '../widgets/product_widget.dart';
import '../widgets/coin_widget.dart';
import '../widgets/display_widget.dart';
import '../widgets/wallet_widget.dart';
import 'admin_screen.dart';
import 'vendor_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  List<String> outputItems = [];

  // Animation für das Key-Icon
  late AnimationController _blinkController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stack = ref.watch(refStack);
    final products = stack.products;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 204, 204, 204), // Hintergrundfarbe anpassen
        actionsIconTheme: const IconThemeData(color: Color.fromARGB(255, 24, 122, 45)), // Icon-Farbe anpassen
        title: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Ihre Auswahl...',
              textStyle: const TextStyle(
                fontSize: 35.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(147, 21, 109, 9),
              ),
              speed: const Duration(milliseconds: 200),
            ),
          ],
          totalRepeatCount: 60, // Animation mehrfach abspielen
          pause: const Duration(milliseconds: 1000),
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: 45,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VendorScreen()),
              );
            },
          ),
          IconButton(
            iconSize: 45,
            icon: FadeTransition(
              opacity: _animation,
              child: const Icon(Icons.key),
            ),
            onPressed: () {
              _showPasswordDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const DisplayWidget(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(1.0),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                return ProductWidget(
                  product: products[index],
                );
              },
            ),
          ),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                WalletWidget(image: 'assets/wallet/wallet.png'),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allCoins.length,
                    itemBuilder: (context, index) {
                      return CoinWidget(coin: allCoins[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    TextEditingController passwordController = TextEditingController();
    final secureStorage = ref.read(secureStorageProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Admin Login"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Passwort",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Passwort überprüfen
                String? storedHashedPassword = await secureStorage.read(key: 'admin_password');

                if (storedHashedPassword == null) {
                  // Kein Passwort gesetzt, neues Passwort speichern
                  String hashedPassword = hashPassword(passwordController.text);
                  await secureStorage.write(key: 'admin_password', value: hashedPassword);

                  Navigator.pop(context); // Dialog schließen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminScreen()),
                  );
                } else {
                  // Passwort überprüfen
                  String hashedInputPassword = hashPassword(passwordController.text);
                  if (hashedInputPassword == storedHashedPassword) {
                    Navigator.pop(context); // Dialog schließen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminScreen()),
                    );
                  } else {
                    // Falsches Passwort
                    Navigator.pop(context); // Dialog schließen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Falsches Passwort')),
                    );
                  }
                }
              },
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog schließen
              },
              child: const Text("Abbrechen"),
            ),
          ],
        );
      },
    );
  }

  String hashPassword(String password) {
    // Ein statisches Salt (für Demo-Zwecke)
    const String salt = "EinSicheresSalt";

    var bytes = utf8.encode(password + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
