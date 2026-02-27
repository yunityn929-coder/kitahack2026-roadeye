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
      final user = FirebaseAuth.instance.currentUser;
      final submittedBy = user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : user?.email ?? 'Unknown';

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

      final buffer = StringBuffer();
      buffer.writeln(
          'ID,Detected By,Latitude,Longitude,Confidence (%),Severity,Status');

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        final confidence = (data['confidence'] ?? 0.0).toDouble();
        final severity = confidence >= 0.8
            ? 'HIGH'
            : confidence >= 0.5
                ? 'MEDIUM'
                : 'LOW';

        final id = 'PTH-${(i + 1).toString().padLeft(3, '0')}';
        final lat = (data['lat'] ?? '').toString();
        final lng = (data['lng'] ?? '').toString();
        final confStr = (confidence * 100).toStringAsFixed(1);
        final status =
            _escapeCsv(data['status']?.toString() ?? 'PENDING');

        buffer.writeln(
            '$id,${_escapeCsv(submittedBy)},$lat,$lng,$confStr,$severity,$status');
      }

      final csvContent = buffer.toString();
      final fileName =
          'roadeye_report_${DateTime.now().millisecondsSinceEpoch}.csv';

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

  String _jsString(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('`', r'\`')
        .replaceAll(r'$', r'\$');
    return '`$escaped`';
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _showProfileDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';
    final displayName = user?.displayName ?? '';

    showDialog(
      context: context,
      builder: (ctx) => _ProfileDialog(email: email, displayName: displayName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';

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

          _SidebarButton(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            isSelected: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),

          Theme(
            data: Theme.of(context)
                .copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const Icon(Icons.warning_amber_rounded,
                  color: Colors.white70, size: 20),
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

          _SidebarButton(
            icon: Icons.download,
            label: 'Download Report',
            isSelected: false,
            onTap: () => _downloadCsvReport(context),
          ),

          const Divider(color: Color(0xFF2a2a2e), height: 1),

          InkWell(
            onTap: () => _showProfileDialog(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.settings_outlined,
                      color: Colors.white38, size: 16),
                ],
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 40),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout',
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDialog extends StatefulWidget {
  final String email;
  final String displayName;

  const _ProfileDialog({required this.email, required this.displayName});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  bool _resetSent = false;
  bool _loading = false;
  String _message = '';

  Future<void> _sendPasswordReset() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: widget.email);
      setState(() {
        _resetSent = true;
        _message =
            'Password reset email sent to ${widget.email}. Check your inbox.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'Failed to send reset email.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        widget.email.isNotEmpty ? widget.email[0].toUpperCase() : '?';

    return Dialog(
      backgroundColor: const Color(0xFF18181b),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                widget.email,
                style: const TextStyle(
                  color: Color(0xFFe5e5e5),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFF2a2a2e)),
              const SizedBox(height: 16),

              Row(
                children: const [
                  Icon(Icons.lock_reset_rounded,
                      color: Color(0xFF888890), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'RESET PASSWORD',
                    style: TextStyle(
                      color: Color(0xFF888890),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'A password reset link will be sent to your registered email address.',
                style: TextStyle(
                  color: Color(0xFF666670),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              if (_message.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _resetSent
                        ? const Color(0xFF22c55e).withOpacity(0.1)
                        : Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _resetSent
                          ? const Color(0xFF22c55e).withOpacity(0.4)
                          : Colors.redAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _resetSent
                          ? const Color(0xFF22c55e)
                          : Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blueAccent,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _resetSent
                              ? const Color(0xFF22c55e).withOpacity(0.15)
                              : Colors.blueAccent,
                          foregroundColor: _resetSent
                              ? const Color(0xFF22c55e)
                              : Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(_resetSent
                            ? Icons.check_circle_outline_rounded
                            : Icons.send_rounded),
                        label: Text(_resetSent
                            ? 'Email Sent'
                            : 'Send Reset Email'),
                        onPressed:
                            _resetSent ? null : _sendPasswordReset,
                      ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close',
                    style: TextStyle(color: Color(0xFF666670))),
              ),
            ],
          ),
        ),
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
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: isSelected
            ? Colors.blueAccent.withOpacity(0.1)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.blueAccent : Colors.white70,
                size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
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

  const _SidebarSubButton(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 48, top: 10, bottom: 10),
        width: double.infinity,
        color: isSelected
            ? Colors.blueAccent.withOpacity(0.1)
            : Colors.transparent,
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