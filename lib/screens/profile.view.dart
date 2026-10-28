import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 80,
            backgroundImage: AssetImage('images/aya.png'),
          ),
          const SizedBox(height: 10),
          const Text(
            "The Koalalaland",
            style: TextStyle(
              color: Color.fromARGB(255, 122, 167, 180),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "aya.kathiri@emsi-edu.ma",
            style: TextStyle(
              color: Color.fromARGB(255, 122, 167, 180),
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 30,
              backgroundColor: const Color.fromARGB(255, 122, 167, 180),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            child: Text("Modifier Profile"),
          ),
        ],
      ),
    );
  }
}
