import 'package:flutter/material.dart';

class EbookTab extends StatelessWidget {
  const EbookTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E-Books')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Fitur E-Book Segera Hadir',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            )
          ],
        ),
      ),
    );
  }
}
