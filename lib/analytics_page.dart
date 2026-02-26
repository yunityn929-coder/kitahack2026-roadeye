import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0f0f11),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hazards_raw').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3b82f6),
                strokeWidth: 2,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final total = docs.length;

          int resolved = 0, pending = 0;
          int high = 0, medium = 0, low = 0;

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'PENDING';
            final confidence = (data['confidence'] ?? 0.0).toDouble();

            if (status == 'RESOLVED') {
              resolved++;
            } else {
              pending++;
            }

            if (confidence >= 0.8) {
              high++;
            } else if (confidence >= 0.5) {
              medium++;
            } else {
              low++;
            }
          }

          final resolutionRate = total > 0 ? resolved / total : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF141416),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2a2a2e), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3b82f6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ANALYTICS',
                          style: TextStyle(
                            color: Color(0xFFf5f5f5),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hazard detection overview',
                          style: TextStyle(
                            color: Color(0xFF666670),
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── KPI Cards ────────────────────────────
                      Row(
                        children: [
                          _KpiCard(
                            label: 'TOTAL HAZARDS',
                            value: '$total',
                            icon: Icons.crisis_alert_rounded,
                            color: const Color(0xFF3b82f6),
                          ),
                          const SizedBox(width: 16),
                          _KpiCard(
                            label: 'ACTIVE',
                            value: '$pending',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFef4444),
                          ),
                          const SizedBox(width: 16),
                          _KpiCard(
                            label: 'RESOLVED',
                            value: '$resolved',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF22c55e),
                          ),
                          const SizedBox(width: 16),
                          _KpiCard(
                            label: 'RESOLUTION RATE',
                            value: '${(resolutionRate * 100).toStringAsFixed(1)}%',
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFFa855f7),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Charts Row ───────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status breakdown
                          Expanded(
                            child: _ChartCard(
                              title: 'STATUS BREAKDOWN',
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  _DonutChart(
                                    resolved: resolved,
                                    pending: pending,
                                    total: total,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _Legend(
                                          color: const Color(0xFF22c55e),
                                          label: 'Resolved',
                                          value: resolved),
                                      const SizedBox(width: 24),
                                      _Legend(
                                          color: const Color(0xFFef4444),
                                          label: 'Active',
                                          value: pending),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Severity breakdown
                          Expanded(
                            child: _ChartCard(
                              title: 'SEVERITY DISTRIBUTION',
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  _SeverityBar(
                                    label: 'HIGH',
                                    count: high,
                                    total: total,
                                    color: const Color(0xFFef4444),
                                    icon: '⚠',
                                  ),
                                  const SizedBox(height: 12),
                                  _SeverityBar(
                                    label: 'MEDIUM',
                                    count: medium,
                                    total: total,
                                    color: const Color(0xFFf97316),
                                    icon: '▲',
                                  ),
                                  const SizedBox(height: 12),
                                  _SeverityBar(
                                    label: 'LOW',
                                    count: low,
                                    total: total,
                                    color: const Color(0xFFf59e0b),
                                    icon: '●',
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Resolution progress
                          Expanded(
                            child: _ChartCard(
                              title: 'RESOLUTION PROGRESS',
                              child: Column(
                                children: [
                                  const SizedBox(height: 24),
                                  _CircularProgress(
                                    value: resolutionRate,
                                    color: const Color(0xFF3b82f6),
                                    label:
                                        '${(resolutionRate * 100).toStringAsFixed(1)}%',
                                    sublabel: 'repaired',
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _StatPill(
                                          label: 'Done',
                                          value: '$resolved',
                                          color: const Color(0xFF22c55e)),
                                      const SizedBox(width: 10),
                                      _StatPill(
                                          label: 'Left',
                                          value: '$pending',
                                          color: const Color(0xFFef4444)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Summary Table ───────────────────────
                      _ChartCard(
                        title: 'SEVERITY × STATUS MATRIX',
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _MatrixTable(
                            docs: docs,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── KPI Card ─────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF18181b),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2a2a2e)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF888890),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart Card Wrapper ───────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2a2a2e)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF888890),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ── Donut Chart (pure Flutter) ───────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final int resolved, pending, total;

  const _DonutChart(
      {required this.resolved, required this.pending, required this.total});

  @override
  Widget build(BuildContext context) {
    final resolvedFrac = total > 0 ? resolved / total : 0.0;
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _DonutPainter(resolvedFrac: resolvedFrac),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: Color(0xFFf5f5f5),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'total',
                style: TextStyle(
                  color: Color(0xFF666670),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double resolvedFrac;

  _DonutPainter({required this.resolvedFrac});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 18.0;
    final rect = Rect.fromLTWH(
        strokeW / 2, strokeW / 2, size.width - strokeW, size.height - strokeW);

    // Background track
    canvas.drawArc(
      rect,
      -1.5708, // -90 deg
      6.2832,
      false,
      Paint()
        ..color = const Color(0xFF2a2a2e)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    if (resolvedFrac > 0) {
      canvas.drawArc(
        rect,
        -1.5708,
        6.2832 * resolvedFrac,
        false,
        Paint()
          ..color = const Color(0xFF22c55e)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    final pendingFrac = 1 - resolvedFrac;
    if (pendingFrac > 0) {
      canvas.drawArc(
        rect,
        -1.5708 + 6.2832 * resolvedFrac,
        6.2832 * pendingFrac,
        false,
        Paint()
          ..color = const Color(0xFFef4444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.resolvedFrac != resolvedFrac;
}

// ── Legend dot ───────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _Legend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(
          '$label ($value)',
          style: const TextStyle(color: Color(0xFF888890), fontSize: 12),
        ),
      ],
    );
  }
}

// ── Severity Bar ─────────────────────────────────────────────────────────────
class _SeverityBar extends StatelessWidget {
  final String label, icon;
  final int count, total;
  final Color color;

  const _SeverityBar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final frac = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text('$icon ', style: TextStyle(color: color, fontSize: 12)),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '$count',
                style: const TextStyle(
                    color: Color(0xFFe5e5e5),
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: const Color(0xFF2a2a2e),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circular progress ────────────────────────────────────────────────────────
class _CircularProgress extends StatelessWidget {
  final double value;
  final Color color;
  final String label, sublabel;

  const _CircularProgress(
      {required this.value,
      required this.color,
      required this.label,
      required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _CirclePainter(value: value, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                    color: Color(0xFF666670), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double value;
  final Color color;

  _CirclePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 12.0;
    final rect = Rect.fromLTWH(
        strokeW / 2, strokeW / 2, size.width - strokeW, size.height - strokeW);

    canvas.drawArc(
      rect,
      -1.5708,
      6.2832,
      false,
      Paint()
        ..color = const Color(0xFF2a2a2e)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    if (value > 0) {
      canvas.drawArc(
        rect,
        -1.5708,
        6.2832 * value,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.value != value;
}

// ── Stat Pill ────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Matrix Table ─────────────────────────────────────────────────────────────
class _MatrixTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;

  const _MatrixTable({required this.docs});

  @override
  Widget build(BuildContext context) {
    // severity × status
    final Map<String, Map<String, int>> matrix = {
      'HIGH': {'PENDING': 0, 'RESOLVED': 0},
      'MEDIUM': {'PENDING': 0, 'RESOLVED': 0},
      'LOW': {'PENDING': 0, 'RESOLVED': 0},
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final confidence = (data['confidence'] ?? 0.0).toDouble();
      final status = data['status'] ?? 'PENDING';
      final sev =
          confidence >= 0.8 ? 'HIGH' : confidence >= 0.5 ? 'MEDIUM' : 'LOW';
      matrix[sev]![status] = (matrix[sev]![status] ?? 0) + 1;
    }

    const headerStyle = TextStyle(
      color: Color(0xFF888890),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    );

    Widget cell(String text, Color color) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        );

    return Table(
      border: TableBorder.all(color: const Color(0xFF2a2a2e), width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF1e1e22)),
          children: [
            Padding(
                padding: const EdgeInsets.all(10),
                child: Text('SEVERITY', style: headerStyle)),
            Padding(
                padding: const EdgeInsets.all(10),
                child: Text('ACTIVE', style: headerStyle, textAlign: TextAlign.center)),
            Padding(
                padding: const EdgeInsets.all(10),
                child: Text('RESOLVED', style: headerStyle, textAlign: TextAlign.center)),
            Padding(
                padding: const EdgeInsets.all(10),
                child: Text('TOTAL', style: headerStyle, textAlign: TextAlign.center)),
          ],
        ),
        for (final entry in matrix.entries)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: entry.key == 'HIGH'
                        ? const Color(0xFFef4444)
                        : entry.key == 'MEDIUM'
                            ? const Color(0xFFf97316)
                            : const Color(0xFFf59e0b),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              cell(
                '${entry.value['PENDING']}',
                const Color(0xFFef4444),
              ),
              cell(
                '${entry.value['RESOLVED']}',
                const Color(0xFF22c55e),
              ),
              cell(
                '${(entry.value['PENDING'] ?? 0) + (entry.value['RESOLVED'] ?? 0)}',
                const Color(0xFFe5e5e5),
              ),
            ],
          ),
      ],
    );
  }
}