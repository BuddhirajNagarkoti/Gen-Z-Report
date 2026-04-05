import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/sync_marker.dart';

class SyncDataService {
  final Map<String, List<SyncMarker>> _markers = {};

  /// Loads markers for either a chapter or a specific page.
  Future<void> loadMarkers(String id) async {
    if (_markers.containsKey(id)) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/sync/$id.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> markerList = data['markers'];
      
      _markers[id] = markerList.map((m) => SyncMarker.fromJson(m)).toList();
      _markers[id]!.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    } catch (e) {
      _markers[id] = [];
    }
  }

  SyncMarker? getMarkerAtTime(String id, int timeMs) {
    final markers = _markers[id];
    if (markers == null || markers.isEmpty) return null;
    
    SyncMarker? active;
    for (var marker in markers) {
      if (marker.timeMs <= timeMs) {
        active = marker;
      } else {
        break;
      }
    }
    return active;
  }
}

