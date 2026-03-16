import 'package:flutter/material.dart';

class VitalSignCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isNormal;
  final Color color;
  final bool? isAvailable; // Nouveau: indique si le capteur est disponible
  final String? subtitle; // Nouveau: sous-titre optionnel

  const VitalSignCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isNormal,
    required this.color,
    this.isAvailable,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isNormal ? Colors.green : Colors.red;
    final available = isAvailable ?? true;
    
    return Card(
      elevation: 2,
      color: available ? null : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon, 
                  color: available ? color : Colors.grey, 
                  size: 24
                ),
                const Spacer(),
                if (available)
                  Icon(
                    isNormal ? Icons.check_circle : Icons.warning,
                    color: statusColor,
                    size: 16,
                  )
                else
                  Icon(
                    Icons.sensors_off,
                    color: Colors.grey,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: available ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              available ? value : 'N/A',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: available ? null : Colors.grey[400],
              ),
            ),
            if (subtitle != null && available) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (!available) ...[
              const SizedBox(height: 4),
              Text(
                'Capteur indisponible',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
