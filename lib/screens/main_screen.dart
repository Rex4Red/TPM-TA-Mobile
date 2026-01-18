import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favorite_screen.dart';
import 'location_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const FavoriteScreen(),
    const LocationScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900], 
        selectedItemColor: Colors.blueAccent, 
        unselectedItemColor: Colors.grey, 
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          // 1. Home
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          
          // 2. Favorit
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Favorit',
          ),
          
          // 3. Lokasi (UPDATED ICON) 🗺️
          // Menggunakan Icons.map_rounded agar lebih merepresentasikan "Peta LBS"
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded), 
            label: 'Peta', // Saya ganti labelnya jadi 'Peta' agar lebih relevan (Opsional)
          ),
        ],
      ),
    );
  }
}