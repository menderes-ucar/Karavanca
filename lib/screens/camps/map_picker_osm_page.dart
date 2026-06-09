import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickResult {
  final LatLng latLng;
  const MapPickResult({required this.latLng});
}

class MapPickerOsmPage extends StatefulWidget {
  const MapPickerOsmPage({super.key});

  @override
  State<MapPickerOsmPage> createState() => _MapPickerOsmPageState();
}

class _MapPickerOsmPageState extends State<MapPickerOsmPage> {
  final MapController _map = MapController();

  // default İstanbul
  LatLng _selected = LatLng(41.0082, 28.9784);

  void _selectAndReturn() {
    Navigator.pop(context, MapPickResult(latLng: _selected));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Haritadan Seç"),
        actions: [
          TextButton(
            onPressed: _selectAndReturn,
            child: const Text("Seç"),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 12,
              onTap: (tapPosition, point) {
                setState(() => _selected = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.karavanis', // package neyse onu yaz
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_pin, size: 46, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),

          // alt panel: lat/lng
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Konum: ${_selected.latitude.toStringAsFixed(6)}, ${_selected.longitude.toStringAsFixed(6)}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _selectAndReturn,
                    child: const Text("Seç"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
