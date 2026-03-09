import "package:flutter/material.dart";

class AppNoteWidget extends StatelessWidget {
  final String note;
  final IconData icon;

  const AppNoteWidget({
    super.key,
    required this.note,
    this.icon = Icons.sticky_note_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Colors.amber[700]!, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.amber[800]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.amber[900],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
