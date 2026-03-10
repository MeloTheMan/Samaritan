import 'package:flutter/material.dart';

class VitalSignCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isNormal;
  final Color color;

  const VitalSignCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isNormal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isNormal ? Colors.green : Colors.red;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Icon(
                  isNormal ? Icons.check_circle : Icons.warning,
                  color: statusColor,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
