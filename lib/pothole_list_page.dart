import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PotholeListPage extends StatelessWidget {
  const PotholeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hazards_raw')
          .where('status', isEqualTo: 'PENDING')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No raw hazards found"));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final confidence = (data['confidence'] ?? 0.0).toDouble();

            // Determine severity
            final severity = confidence >= 0.8
                ? 'HIGH'
                : confidence >= 0.5
                    ? 'MEDIUM'
                    : 'LOW';

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                // leading: Image.network(
                //   data['imageUrl'] ?? '',
                //   width: 60,
                //   height: 60,
                //   fit: BoxFit.cover,
                // ),
                title: Text(data['detectedBy'] ?? 'Unknown'),
                subtitle: Text(
                    "Confidence: ${(confidence * 100).toStringAsFixed(1)}%\nLat: ${data['lat']}, Lng: ${data['lng']}"),
                trailing: Text(
                  severity,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getSeverityColor(severity),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.yellow;
    }
  }
}
