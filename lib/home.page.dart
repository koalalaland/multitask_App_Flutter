import 'package:flutter/material.dart';
import 'package:multitask_app/screens/cards.view.dart';
import 'package:multitask_app/screens/home.view.dart';
import 'package:multitask_app/screens/login.view.dart';
import 'package:multitask_app/screens/profile.view.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currIndex = 0;

  List<Widget> screens = [HomeView(), ProfileView(), LoginView(), CardsView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 122, 167, 180),
        title: const Text(
          'App multitaches',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IndexedStack(index: currIndex, children: screens),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currIndex,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 122, 167, 180),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          setState(() {
            currIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Cards'),
        ],
      ),
    );
  }
}
