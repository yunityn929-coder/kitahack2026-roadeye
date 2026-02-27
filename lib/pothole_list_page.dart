import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PotholeListPage extends StatelessWidget {
  final String searchQuery;
  const PotholeListPage({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0f0f11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: const Color(0xFFef4444),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE POTHOLES',
                      style: TextStyle(
                        color: Color(0xFFf5f5f5),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pending hazard reports',
                      style: TextStyle(
                        color: Color(0xFF666670),
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1d),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2a2a2e)),
                  ),
                  child: Row(
                    children: [
                      _PulseDot(),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF22c55e),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hazards_raw')
                  .where('status', isEqualTo: 'PENDING')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFef4444),
                      strokeWidth: 2,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState(noData: true);
                }

                final allDocs = snapshot.data!.docs;
                final docs = searchQuery.isEmpty
                    ? allDocs
                    : allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['detectedBy'] ?? '').toString().toLowerCase();
                        return name.contains(searchQuery.toLowerCase());
                      }).toList();

                if (docs.isEmpty) {
                  return _emptyState(noData: false, query: searchQuery);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final confidence =
                        (data['confidence'] ?? 0.0).toDouble();
                    final lat = (data['lat'] ?? 0.0).toDouble();
                    final lng = (data['lng'] ?? 0.0).toDouble();
                    final detectedBy = data['detectedBy'] ?? 'UNKNOWN';
                    final imageUrl = data['imageUrl'] ?? '';

                    final severity = confidence >= 0.8
                        ? 'HIGH'
                        : confidence >= 0.5
                            ? 'MEDIUM'
                            : 'LOW';

                    return _PotholeCard(
                      index: index,
                      docId: docId,
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
  Widget _emptyState({required bool noData, String query = ''}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noData ? Icons.check_circle_outline : Icons.search_off,
            color: Color(noData ? 0xFF22c55e : 0xFF555560).withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            noData
                ? 'All clear — no active hazards'
                : 'No results for "$query"',
            style: const TextStyle(
              color: Color(0xFF555560),
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF22c55e),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PotholeCard extends StatefulWidget {
  final int index;
  final String docId;
  final String severity;
  final double confidence;
  final double lat;
  final double lng;
  final String detectedBy;
  final String imageUrl;

  const _PotholeCard({
    required this.index,
    required this.docId,
    required this.severity,
    required this.confidence,
    required this.lat,
    required this.lng,
    required this.detectedBy,
    required this.imageUrl,
  });

  @override
  State<_PotholeCard> createState() => _PotholeCardState();
}

class _PotholeCardState extends State<_PotholeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hovered = false;

  Color get _sevColor {
    switch (widget.severity) {
      case 'HIGH':
        return const Color(0xFFef4444);
      case 'MEDIUM':
        return const Color(0xFFf97316);
      default:
        return const Color(0xFFf59e0b);
    }
  }

  Color get _sevBg {
    switch (widget.severity) {
      case 'HIGH':
        return const Color(0xFF3b1010);
      case 'MEDIUM':
        return const Color(0xFF3b1f0a);
      default:
        return const Color(0xFF3b2a0a);
    }
  }

  String get _sevIcon {
    switch (widget.severity) {
      case 'HIGH':
        return '⚠';
      case 'MEDIUM':
        return '▲';
      default:
        return '●';
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
                  ? const Color(0xFF1e1e22)
                  : const Color(0xFF18181b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? _sevColor.withOpacity(0.35)
                    : const Color(0xFF2a2a2e),
                width: 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: _sevColor.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                  child: widget.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _NoImage(size: 90),
                        )
                      : _NoImage(size: 90),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                color: _sevBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _sevColor.withOpacity(0.5),
                                    width: 1),
                              ),
                              child: Text(
                                '${_sevIcon} ${widget.severity}',
                                style: TextStyle(
                                  color: _sevColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CONFIDENCE',
                              style: TextStyle(
                                color: Color(0xFF555560),
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(widget.confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _sevColor,
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
                                _sevColor),
                          ),
                        ),

                        const SizedBox(height: 10),

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
                                letterSpacing: 0.2,
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
                    color: _sevColor.withOpacity(0.6),
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
  final double size;
  const _NoImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF1e1e22),
      child: const Icon(Icons.image_not_supported_outlined,
          color: Color(0xFF333338), size: 28),
    );
  }
}