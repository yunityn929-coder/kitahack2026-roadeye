// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roadeye_dashboard/pothole_list_page.dart';
import 'dart:js' as js;
import 'package:roadeye_dashboard/sidebar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final Set<String> _drawnMarkerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGoogleMap());
  }

  void _initGoogleMap() {
    js.context.callMethod('eval', [
      """
      (function() {
        window.markerRegistry = {};
        window.currentInfoWindow = null;

        window.resolveMarker = function(markerId) {
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

            window.map.addListener('click', function() {
              if (window.currentInfoWindow) {
                window.currentInfoWindow.close();
                window.currentInfoWindow = null;
              }
            });
          } else {
            setTimeout(tryInitMap, 200);
          }
        }

        tryInitMap();
      })();
      """
    ]);

    _listenToRawHazards();
  }

  void _listenToRawHazards() {
    FirebaseFirestore.instance
        .collection('hazards_raw')
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        if (_drawnMarkerIds.contains(doc.id)) continue;

        final data = doc.data();
        final lat = (data['lat']).toDouble();
        final lng = (data['lng']).toDouble();
        final confidence = (data['confidence']).toDouble();

        // Determine severity based on confidence
        final severity = confidence >= 0.8
            ? 'HIGH'
            : confidence >= 0.5
                ? 'MEDIUM'
                : 'LOW';

        _addMarkerToJs(
          doc.id,
          lat,
          lng,
          data['imageUrl'] ?? '',
          data['detectedBy'] ?? 'HAZARD',
          severity,
          confidence,
          "Confidence: ${(confidence * 100).toStringAsFixed(1)}%",
        );

        _drawnMarkerIds.add(doc.id);
      }
    });
  }

  void _addMarkerToJs(String id, double lat, double lng, String img,
      String label, String sev, double confidence, String des) {
    // final iconColor = sev.toUpperCase() == 'HIGH'
    //     ? 'red'
    //     : sev.toUpperCase() == 'MEDIUM'
    //         ? 'orange'
    //         : 'yellow';

    // final headerColor = sev.toUpperCase() == 'HIGH'
    //     ? '#c62828'
    //     : sev.toUpperCase() == 'MEDIUM'
    //         ? '#e65100'
    //         : '#f9a825';
    String iconColor;
    String headerColor;
    if (sev == "HIGH") {
      iconColor = 'red';
      headerColor = '#c62828';
    } else if (sev == "MEDIUM") {
      iconColor = 'orange';
      headerColor = '#e65100';
    } else {
      iconColor = 'yellow';
      headerColor = '#f9a825';
    }

    final latStr = lat.toStringAsFixed(4);
    final lngStr = lng.toStringAsFixed(4);

    js.context.callMethod('eval', [
      """
      (function() {
        function tryAddMarker() {
          if (!window.map || typeof google === 'undefined') {
            setTimeout(tryAddMarker, 300);
            return;
          }

          var marker = new google.maps.Marker({
            position: { lat: $lat, lng: $lng },
            map: window.map,
            title: '$label',
            icon: {
              url: 'http://maps.google.com/mapfiles/ms/icons/$iconColor-dot.png',
              scaledSize: new google.maps.Size(40, 40)
            },
            animation: google.maps.Animation.DROP
          });

          window.markerRegistry['$id'] = marker;

          var popup = new google.maps.InfoWindow({
            content:
              '<div style="width:220px;font-family:Segoe UI,sans-serif;border-radius:8px;overflow:hidden;">' +
                '<div style="background:$headerColor;color:white;padding:8px 12px;font-weight:bold;font-size:14px;">' +
                  '🚨 $label <span style="float:right;background:rgba(255,255,255,0.25);border-radius:4px;padding:2px 6px;font-size:11px;">$sev</span>' +
                '</div>' +
                '<div style="height:120px;overflow:hidden;">' +
                  '<img src="$img" style="width:100%;height:100%;object-fit:cover;" onerror="this.src=\\'https://placehold.co/220x120?text=No+Image\\'"/>' +
                '</div>' +
                '<div style="padding:10px 12px;background:white;color:#333;">' +
                  '<div style="font-size:12px;color:#666;margin-bottom:4px;">📍 $latStr, $lngStr</div>' +
                  '<button onclick="window.resolveMarker(\\'$id\\')" style="width:100%;background:#2e7d32;color:white;border:none;padding:8px;border-radius:4px;cursor:pointer;font-size:13px;font-weight:bold;">✅ Mark as Repaired</button>' +
                '</div>' +
              '</div>',
            maxWidth: 240
          });

          marker.addListener('click', function() {
            if (window.currentInfoWindow) {
              window.currentInfoWindow.close();
            }
            popup.open(window.map, marker);
            window.currentInfoWindow = popup;
            window.map.panTo(marker.getPosition());
          });
        }

        tryAddMarker();
      })();
      """
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── SIDEBAR ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 60 : 250,
            color: Colors.grey[850],
            child: _isSidebarCollapsed
                ? Column(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_right, color: Colors.white),
                        onPressed: () =>
                            setState(() => _isSidebarCollapsed = false),
                      ),
                    ],
                  )
                : SimpleSidebar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
          ),

          // ── MAIN CONTENT ──
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                HtmlElementView(viewType: 'map-canvas'),
                PotholeListPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
