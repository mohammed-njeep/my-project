import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Splash_Screen/SplashScreen .dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ehfcdcgajtzvblxspaba.supabase.co',
    anonKey: 'sb_publishable_JyyJ74uOZmaImTVpkFZCkQ_hCJQpaAW', 
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdvancedSplashScreen(),
    );
  }
}