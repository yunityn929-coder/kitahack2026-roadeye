import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:js' as js;

class SimpleSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SimpleSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  Future<void> _downloadCsvReport(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fetching data for report...")),
    );

    try {
      // Get current logged-in user's display name or email
      final user = FirebaseAuth.instance.currentUser;
      final submittedBy = user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : user?.email ?? 'Unknown';

      // Fetch all hazards (both active & resolved)
      final snapshot = await FirebaseFirestore.instance
          .collection('hazards_raw')
          .get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No data found to export.")),
          );
        }
        return;
      }

      // Build CSV content
      final buffer = StringBuffer();
      buffer.writeln('ID,Detected By,Latitude,Longitude,Confidence (%),Severity,Status');

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc  = snapshot.docs[i];
        final data = doc.data();
        final confidence = (data['confidence'] ?? 0.0).toDouble();
        final severity = confidence >= 0.8
            ? 'HIGH'
            : confidence >= 0.5
                ? 'MEDIUM'
                : 'LOW';

        final id      = 'PTH-${(i + 1).toString().padLeft(3, '0')}';
        final lat     = (data['lat'] ?? '').toString();
        final lng     = (data['lng'] ?? '').toString();
        final confStr = (confidence * 100).toStringAsFixed(1);
        final status  = _escapeCsv(data['status']?.toString() ?? 'PENDING');

        buffer.writeln('$id,${_escapeCsv(submittedBy)},$lat,$lng,$confStr,$severity,$status');
      }

      // Trigger browser download via JS
      final csvContent = buffer.toString();
      final fileName   = 'roadeye_report_${DateTime.now().millisecondsSinceEpoch}.csv';

      js.context.callMethod('eval', ["""
        (function() {
          var blob = new Blob([${_jsString(csvContent)}], { type: 'text/csv;charset=utf-8;' });
          var url  = URL.createObjectURL(blob);
          var a    = document.createElement('a');
          a.href     = url;
          a.download = '$fileName';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        })();
      """]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report downloaded: $fileName")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating report: $e")),
        );
      }
    }
  }

  /// Wraps a Dart string safely for inline JS (backtick template literal).
  String _jsString(String value) {
    // Escape backticks and backslashes so the JS template literal stays valid
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('`', r'\`')
        .replaceAll(r'$', r'\$');
    return '`$escaped`';
  }

  /// Wraps a CSV field in quotes if it contains commas, quotes, or newlines.
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey[900],
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'RoadEye OS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _SidebarButton(
            icon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),

          // --- NESTED POTHOLES MENU ---
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.white70, size: 20),
              title: const Text(
                'Potholes',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white70,
              children: [
                _SidebarSubButton(
                  label: 'Active Potholes',
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemSelected(1),
                ),
                _SidebarSubButton(
                  label: 'Repaired History',
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemSelected(2),
                ),
              ],
            ),
          ),

          const Spacer(),

          // --- DOWNLOAD REPORT BUTTON ---
          _SidebarButton(
            icon: Icons.download,
            label: 'Download Report',
            isSelected: false,
            onTap: () => _downloadCsvReport(context),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 40),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSubButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarSubButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 48, top: 10, bottom: 10),
        width: double.infinity,
        color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.white60,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}