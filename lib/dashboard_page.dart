import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roadeye_dashboard/pothole_list_page.dart';
import 'package:roadeye_dashboard/history_page.dart';
import 'package:roadeye_dashboard/analytics_page.dart';
import 'dart:js' as js;
import 'package:roadeye_dashboard/sidebar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final Set<String> _drawnMarkerIds = {};

  bool _showHigh     = true;
  bool _showMedium   = true;
  bool _showLow      = true;
  bool _showResolved = true;

  int _countHigh = 0, _countMedium = 0, _countLow = 0, _countResolved = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGoogleMap());
  }

  void _applyFilters() {
    final high     = _showHigh     ? 'true' : 'false';
    final medium   = _showMedium   ? 'true' : 'false';
    final low      = _showLow      ? 'true' : 'false';
    final resolved = _showResolved ? 'true' : 'false';

    js.context.callMethod('eval', ["""
      (function() {
        if (!window.markerMeta) return;
        Object.keys(window.markerMeta).forEach(function(id) {
          var meta   = window.markerMeta[id];
          var marker = window.markerRegistry[id];
          if (!marker) return;

          var visible = false;
          if (meta.status === 'RESOLVED' && $resolved) visible = true;
          if (meta.status !== 'RESOLVED') {
            if (meta.sev === 'HIGH'   && $high)   visible = true;
            if (meta.sev === 'MEDIUM' && $medium) visible = true;
            if (meta.sev === 'LOW'    && $low)    visible = true;
          }
          marker.setVisible(visible);
        });
      })();
    """]);
  }

  void _toggleFilter(String key) {
    setState(() {
      switch (key) {
        case 'HIGH':     _showHigh     = !_showHigh;     break;
        case 'MEDIUM':   _showMedium   = !_showMedium;   break;
        case 'LOW':      _showLow      = !_showLow;      break;
        case 'RESOLVED': _showResolved = !_showResolved; break;
      }
    });
    _applyFilters();
  }

  void _initGoogleMap() {
    js.context['dartResolveMarker'] = js.allowInterop((String markerId) {
      FirebaseFirestore.instance
          .collection('hazards_raw')
          .doc(markerId)
          .update({'status': 'RESOLVED'});
    });

    js.context.callMethod('eval', ["""
      (function() {
        window.markerRegistry = {};
        window.markerMeta     = {};
        window.currentInfoWindow = null;

        window.resolveMarker = function(markerId) {
          if (window.dartResolveMarker) window.dartResolveMarker(markerId);
          if (window.markerRegistry[markerId]) {
            window.markerRegistry[markerId].setMap(null);
            delete window.markerRegistry[markerId];
          }
          if (window.currentInfoWindow) {
            window.currentInfoWindow.close();
            window.currentInfoWindow = null;
          }
        };

        function tryInitMap() {
          var el = document.getElementById('map-container');
          if (typeof google !== 'undefined' && el) {
            window.map = new google.maps.Map(el, {
              center: { lat: 3.1390, lng: 101.6869 },
              zoom: 13,
              disableDefaultUI: false
            });
          } else {
            setTimeout(tryInitMap, 200);
          }
        }
        tryInitMap();
      })();
    """]);

    _listenToRawHazards();
  }

  void _listenToRawHazards() {
    FirebaseFirestore.instance
        .collection('hazards_raw')
        .snapshots()
        .listen((snapshot) {
      int high = 0, medium = 0, low = 0, resolved = 0;

      for (var doc in snapshot.docs) {
        final data       = doc.data();
        final confidence = (data['confidence'] ?? 0).toDouble();
        final status     = data['status'] ?? 'PENDING';
        final severity   = confidence >= 0.8 ? 'HIGH'
                         : confidence >= 0.5 ? 'MEDIUM'
                         : 'LOW';

        if (status == 'RESOLVED')     { resolved++; }
        else if (severity == 'HIGH')  { high++; }
        else if (severity == 'MEDIUM'){ medium++; }
        else                          { low++; }

        if (_drawnMarkerIds.contains(doc.id)) continue;

        _addMarkerToJs(
          doc.id,
          (data['lat']).toDouble(),
          (data['lng']).toDouble(),
          data['imageUrl'] ?? '',
          data['detectedBy'] ?? 'HAZARD',
          severity,
          status,
        );
        _drawnMarkerIds.add(doc.id);
      }

      if (mounted) {
        setState(() {
          _countHigh     = high;
          _countMedium   = medium;
          _countLow      = low;
          _countResolved = resolved;
        });
      }

      Future.delayed(const Duration(milliseconds: 400), _applyFilters);
    });
  }

  void _addMarkerToJs(String id, double lat, double lng, String img,
      String label, String sev, String status) {
    String accentColor = '#f59e0b';
    String badgeBg     = '#78350f';
    String markerColor = '%23f59e0b';

    if (status == "RESOLVED") {
      accentColor = '#22c55e'; badgeBg = '#14532d'; markerColor = '%2322c55e';
    } else if (sev == "HIGH") {
      accentColor = '#ef4444'; badgeBg = '#7f1d1d'; markerColor = '%23ef4444';
    } else if (sev == "MEDIUM") {
      accentColor = '#f97316'; badgeBg = '#7c2d12'; markerColor = '%23f97316';
    }

    String sevIcon = sev == "HIGH" ? "⚠" : sev == "MEDIUM" ? "▲" : "●";
    if (status == "RESOLVED") sevIcon = "✓";

    String actionHtml = status == "RESOLVED"
        ? '''<div style="display:flex;align-items:center;gap:6px;justify-content:center;padding:8px 0 2px;">
               <span style="font-size:16px;">✓</span>
               <span style="color:#22c55e;font-weight:700;font-size:13px;letter-spacing:.5px;">REPAIRED</span>
             </div>'''
        : '''<button onclick="window.resolveMarker('$id')"
               style="width:100%;padding:9px 0;background:linear-gradient(135deg,$accentColor,${accentColor}cc);
                      color:#fff;border:none;border-radius:6px;cursor:pointer;
                      font-size:12px;font-weight:700;letter-spacing:.8px;
                      box-shadow:0 2px 8px ${accentColor}55;transition:opacity .2s;"
               onmouseover="this.style.opacity='.85'"
               onmouseout="this.style.opacity='1'">
             MARK AS REPAIRED
           </button>''';

    js.context.callMethod('eval', ["""
      (function() {
        window.markerMeta['$id'] = { sev: '$sev', status: '$status' };

        function tryAddMarker() {
          if (!window.map || typeof google === 'undefined') {
            setTimeout(tryAddMarker, 300);
            return;
          }

          var svgMarker = {
            url: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="36" height="46" viewBox="0 0 36 46"><defs><filter id="s" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="2" stdDeviation="2" flood-opacity="0.35"/></filter></defs><path d="M18 2C9.163 2 2 9.163 2 18c0 11.25 16 26 16 26S34 29.25 34 18C34 9.163 26.837 2 18 2z" fill="$markerColor" filter="url(%23s)"/><circle cx="18" cy="18" r="7" fill="white" opacity="0.9"/></svg>',
            scaledSize: new google.maps.Size(36, 46),
            anchor: new google.maps.Point(18, 46),
          };

          var marker = new google.maps.Marker({
            position: { lat: $lat, lng: $lng },
            map: window.map,
            icon: svgMarker,
            animation: google.maps.Animation.DROP
          });

          window.markerRegistry['$id'] = marker;

          var contentString = `
            <div style="width:240px;font-family:'Segoe UI',system-ui,sans-serif;border-radius:12px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,.28);border:1px solid rgba(255,255,255,.08);">
              <div style="position:relative;height:130px;background:#111;">
                <img src="$img" style="width:100%;height:100%;object-fit:cover;display:block;opacity:.92;"
                  onerror="this.src='https://placehold.co/240x130/1a1a1a/555?text=No+Image'">
                <div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(0,0,0,.75) 0%,transparent 55%);"></div>
                <div style="position:absolute;top:10px;left:10px;background:$badgeBg;border:1.5px solid $accentColor;color:$accentColor;padding:3px 9px;border-radius:20px;font-size:10px;font-weight:700;letter-spacing:1px;">$sevIcon $sev</div>
                <div style="position:absolute;bottom:10px;left:12px;right:12px;">
                  <div style="color:#fff;font-size:14px;font-weight:700;letter-spacing:.3px;text-shadow:0 1px 4px rgba(0,0,0,.6);">$label</div>
                </div>
              </div>
              <div style="padding:14px;background:#1c1c1e;">
                <div style="display:flex;gap:6px;margin-bottom:12px;">
                  <div style="flex:1;background:#2a2a2d;border-radius:6px;padding:6px 8px;">
                    <div style="color:#888;font-size:9px;letter-spacing:.8px;margin-bottom:2px;">LAT</div>
                    <div style="color:#e5e5e5;font-size:11px;font-weight:600;">${lat.toStringAsFixed(5)}</div>
                  </div>
                  <div style="flex:1;background:#2a2a2d;border-radius:6px;padding:6px 8px;">
                    <div style="color:#888;font-size:9px;letter-spacing:.8px;margin-bottom:2px;">LNG</div>
                    <div style="color:#e5e5e5;font-size:11px;font-weight:600;">${lng.toStringAsFixed(5)}</div>
                  </div>
                </div>
                <div style="height:2px;background:linear-gradient(90deg,$accentColor,transparent);border-radius:2px;margin-bottom:12px;"></div>
                $actionHtml
              </div>
            </div>
          `;

          var popup = new google.maps.InfoWindow({ content: contentString, disableAutoPan: false });
          marker.addListener('click', () => {
            if (window.currentInfoWindow) window.currentInfoWindow.close();
            popup.open(window.map, marker);
            window.currentInfoWindow = popup;
          });
        }
        tryAddMarker();
      })();
    """]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SimpleSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) => setState(() => _selectedIndex = index),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // index 0 — Map with filter bar overlaid
                Stack(
                  children: [
                    const HtmlElementView(viewType: 'map-canvas'),
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _FilterBar(
                          showHigh:      _showHigh,
                          showMedium:    _showMedium,
                          showLow:       _showLow,
                          showResolved:  _showResolved,
                          countHigh:     _countHigh,
                          countMedium:   _countMedium,
                          countLow:      _countLow,
                          countResolved: _countResolved,
                          onToggle:      _toggleFilter,
                        ),
                      ),
                    ),
                  ],
                ),
                const PotholeListPage(),
                const HistoryPage(),
                const AnalyticsPage(),
                const Center(child: Text("Audit Logs Page")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final bool showHigh, showMedium, showLow, showResolved;
  final int  countHigh, countMedium, countLow, countResolved;
  final void Function(String key) onToggle;

  const _FilterBar({
    required this.showHigh,
    required this.showMedium,
    required this.showLow,
    required this.showResolved,
    required this.countHigh,
    required this.countMedium,
    required this.countLow,
    required this.countResolved,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b).withOpacity(0.93),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2a2a2e)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'FILTER',
            style: TextStyle(
              color: Color(0xFF555560),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 20, color: const Color(0xFF2a2a2e)),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'HIGH',   icon: '⚠', count: countHigh,
            active: showHigh, activeColor: const Color(0xFFef4444),
            onTap: () => onToggle('HIGH'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'MEDIUM', icon: '▲', count: countMedium,
            active: showMedium, activeColor: const Color(0xFFf97316),
            onTap: () => onToggle('MEDIUM'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'LOW',    icon: '●', count: countLow,
            active: showLow, activeColor: const Color(0xFFf59e0b),
            onTap: () => onToggle('LOW'),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: const Color(0xFF2a2a2e)),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'RESOLVED', icon: '✓', count: countResolved,
            active: showResolved, activeColor: const Color(0xFF22c55e),
            onTap: () => onToggle('RESOLVED'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label, icon;
  final int count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color  = widget.active ? widget.activeColor : const Color(0xFF444450);
    final bg     = widget.active
        ? widget.activeColor.withOpacity(0.12)
        : const Color(0xFF111113);
    final border = widget.active
        ? widget.activeColor.withOpacity(0.45)
        : const Color(0xFF2a2a2e);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.activeColor.withOpacity(widget.active ? 0.2 : 0.07)
                : bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.active
                      ? widget.activeColor
                      : const Color(0xFF333338),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.icon} ${widget.label}',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.active
                        ? widget.activeColor.withOpacity(0.2)
                        : const Color(0xFF2a2a2e),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      color: widget.active
                          ? widget.activeColor
                          : const Color(0xFF555560),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              if (!widget.active) ...[
                const SizedBox(width: 5),
                const Icon(Icons.visibility_off_outlined,
                    color: Color(0xFF444450), size: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}