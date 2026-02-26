import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0f0f11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
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
                    color: const Color(0xFF22c55e),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REPAIRED HISTORY',
                      style: TextStyle(
                        color: Color(0xFFf5f5f5),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Resolved hazard records',
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

          // ── List ────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hazards_raw')
                  .where('status', isEqualTo: 'RESOLVED')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF22c55e),
                      strokeWidth: 2,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history,
                            color: const Color(0xFF555560).withOpacity(0.6),
                            size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'No repaired hazards yet',
                          style: TextStyle(
                            color: Color(0xFF555560),
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final confidence = (data['confidence'] ?? 0.0).toDouble();
                    final lat = (data['lat'] ?? 0.0).toDouble();
                    final lng = (data['lng'] ?? 0.0).toDouble();
                    final detectedBy = data['detectedBy'] ?? 'UNKNOWN';
                    final imageUrl = data['imageUrl'] ?? '';

                    final severity = confidence >= 0.8
                        ? 'HIGH'
                        : confidence >= 0.5
                            ? 'MEDIUM'
                            : 'LOW';

                    return _RepairedCard(
                      index: index,
                      severity: severity,
                      confidence: confidence,
                      lat: lat,
                      lng: lng,
                      detectedBy: detectedBy,
                      imageUrl: imageUrl,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RepairedCard extends StatefulWidget {
  final int index;
  final String severity;
  final double confidence;
  final double lat;
  final double lng;
  final String detectedBy;
  final String imageUrl;

  const _RepairedCard({
    required this.index,
    required this.severity,
    required this.confidence,
    required this.lat,
    required this.lng,
    required this.detectedBy,
    required this.imageUrl,
  });

  @override
  State<_RepairedCard> createState() => _RepairedCardState();
}

class _RepairedCardState extends State<_RepairedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hovered = false;

  static const _green = Color(0xFF22c55e);
  static const _greenBg = Color(0xFF0f2a1a);

  Color get _sevColor {
    switch (widget.severity) {
      case 'HIGH':   return const Color(0xFFef4444);
      case 'MEDIUM': return const Color(0xFFf97316);
      default:       return const Color(0xFFf59e0b);
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _hovered
                  ? const Color(0xFF1a201a)
                  : const Color(0xFF18181b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? _green.withOpacity(0.35)
                    : const Color(0xFF2a2a2e),
                width: 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: _green.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // ── Thumbnail ────────────────────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                  child: Stack(
                    children: [
                      widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _NoImage(),
                            )
                          : _NoImage(),
                      // Green overlay tint to indicate resolved
                      Container(
                        width: 90,
                        height: 90,
                        color: _green.withOpacity(0.15),
                      ),
                      // Checkmark badge
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label + RESOLVED badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.detectedBy.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFe5e5e5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _greenBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _green.withOpacity(0.5), width: 1),
                              ),
                              child: const Text(
                                '✓ RESOLVED',
                                style: TextStyle(
                                  color: _green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Original severity bar (dimmed)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'WAS',
                              style: TextStyle(
                                color: Color(0xFF555560),
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.severity} · ${(widget.confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _sevColor.withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: widget.confidence,
                            minHeight: 4,
                            backgroundColor: const Color(0xFF2a2a2e),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _sevColor.withOpacity(0.4)),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Coordinates
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Color(0xFF444450), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.lat.toStringAsFixed(5)}, ${widget.lng.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Color(0xFF555560),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  width: 3,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.6),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(11),
                      bottomRight: Radius.circular(11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xFF1e1e22),
      child: const Icon(Icons.image_not_supported_outlined,
          color: Color(0xFF333338), size: 28),
    );
  }
}