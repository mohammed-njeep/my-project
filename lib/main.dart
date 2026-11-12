import 'package:flutter/material.dart';
import 'package:my_project/auth.dart';
import 'package:my_project/services/services.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'Splash_Screen/SplashScreen .dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Services myServices = Services();
  await Supabase.initialize(
    url: myServices.url,
    publishableKey: myServices.publishableKey,
  );
  //jjjjjjjjjjjjjjjjjjjjjjjjjj
  runApp(MyApp());
}

// It's handy to then extract the Supabase client in a variable for later uses
final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Container(
          child: Center(
            child: IconButton(
              onPressed: () {
                Authclass().signup("noooo3@g.com", "88888888");
              },
              icon: Text("ffgrrtgg"),
            ),
          ),
        ),
      ),
    );
  }
}
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AdvancedSplashScreen(),
//     );
//   }
// }
