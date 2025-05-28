import 'package:flutter/material.dart';

class SoalNavigatorWidget extends StatelessWidget {
  final int jumlahSoal;
  final int currentIndex;
  final Function(int) onSoalTap;
  final VoidCallback onSubmit;

  const SoalNavigatorWidget({
    Key? key,
    required this.jumlahSoal,
    required this.currentIndex,
    required this.onSoalTap,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: jumlahSoal,
            itemBuilder: (context, index) {
              final nomor = index + 1;
              final isSelected = index == currentIndex;

              return GestureDetector(
                onTap: () => onSoalTap(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$nomor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: const Text("Submit"),
            ),
          ),
        ),
      ],
    );
  }
}
