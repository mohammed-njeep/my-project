import 'package:flutter/material.dart';
import 'package:my_project/Login/AddHouseholdScreen.dart';
import 'package:my_project/Login/AddNeighborhoodScreen.dart';
import 'package:my_project/assignment_page.dart';
import 'package:my_project/auth.dart';
import 'package:my_project/service/services.dart';
import 'package:my_project/service/subProfile.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'Splash_Screen/SplashScreen .dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Services myServices = Services();
  await Supabase.initialize(
    url: myServices.url,
    publishableKey: myServices.publishableKey,
  );

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
      debugShowCheckedModeBanner: false,
      home: AssignmentPage(),
      // Scaffold(
      //   appBar: AppBar(),
      //   body: Container(
      //     child: Center(
      //       child: IconButton(
      //         onPressed: () {
      //           // subProfile().updateProfile("ahmmmmed", true);
      //           // Backend().createNeighborhood("alhndy", "2001", "adhy", true);
      //           Authclass().createAccount(
      //             email: "ahmmed01@g.com",
      //             password: "1234567",
      //             fullName: "ahmed",
      //             phone: "770543123",
      //             role: "admin",
      //           );
      //         },
      //         icon: Text("ffgrrtgg"),
      //       ),
      //     ),
      //   ),
      // ),
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
//       home: AddHouseholdScreen(),
//     );
//   }
// }
