import 'package:easybooks/data/notifiers.dart';
import 'package:flutter/material.dart';

class SelectVatStatusPage extends StatefulWidget {
  const SelectVatStatusPage({super.key});

  @override
  State<SelectVatStatusPage> createState() => _SelectVatStatusPageState();
}

class _SelectVatStatusPageState extends State<SelectVatStatusPage> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Color(0xFF161616),
        child: Center(
          child: Container(
            width: 400,
            height: 275,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 30, 30, 30),
              border: Border.all(color: const Color(0xFF717171)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "VAT Registration Status",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  "Is your business officially VAT-registered?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
        
                // Buttons (visible and styled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        notifier_selectedPage.value = 4; // No
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE0E0E0),
                        side: const BorderSide(color: Color(0xFF6A6A6A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('No'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () {
                        notifier_selectedPage.value = 5; // Yes
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6FFF43),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      child: const Text("Yes"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
