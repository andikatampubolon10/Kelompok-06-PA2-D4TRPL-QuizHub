import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class MateriDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String file_url;

  const MateriDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.file_url,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Back button (leading icon) and title setup
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back icon in white
          onPressed: () {
            Navigator.pop(context); // Go back when the back icon is pressed
          },
        ),
        title: Text(
          "Materi", // Title of the page
          style: const TextStyle(
            fontSize: 24, // Larger font size for the title
            fontWeight: FontWeight.bold,
            color: Colors.white, // White color for the title
          ),
        ),
        backgroundColor: const Color(0xFF0078D4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title of the material (dynamically passed title)
            Text(
              title,  // The title passed from the previous screen
              style: const TextStyle(
                fontSize: 32,  // Larger font size for the title
                fontWeight: FontWeight.bold,
                color: Colors.black87, // Black color for the material title
              ),
            ),
            const SizedBox(height: 16),  // Space between the title and description

            // "Deskripsi:" Section
            Text(
              'Deskripsi:',
              style: const TextStyle(
                fontSize: 18,  // Font size for the label
                fontWeight: FontWeight.bold,
                color: Colors.black87,  // Black color for the label
              ),
            ),
            const SizedBox(height: 8),  // Space between label and description

            // Description Text Section
            Text(
              description,  // The description of the material
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),  // Space after description

            // File Name Section
            GestureDetector(
              onTap: () async {
                final Uri url = Uri.parse(file_url);

                try {
                  final bool launched = await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!launched) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak dapat membuka file')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terjadi kesalahan saat membuka file')),
                  );
                }
              },
              child: Text(
                'Nama file: $file_url',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

          ],
        ),
      )
    );
  }
}