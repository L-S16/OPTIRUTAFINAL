import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class GeocodingHelper {
  static String clasificarZonaAutomatica(String direccion) {
    final dirLower = direccion.toLowerCase();
    if (dirLower.contains('quito')) {
      return 'Norte';
    } else if (dirLower.contains('guayaquil')) {
      return 'Sur';
    } else if (dirLower.contains('ambato')) {
      return 'Sur';
    } else if (dirLower.contains('latacunga')) {
      return 'Centro';
    } else if (dirLower.contains('pujili') || dirLower.contains('pujilí')) {
      return 'Oeste';
    } else if (dirLower.contains('sangolqui') || dirLower.contains('sangolquí')) {
      return 'Norte';
    } else if (dirLower.contains('aloag') || dirLower.contains('alóag')) {
      return 'Centro';
    } else {
      return 'Centro'; // Fallback por defecto
    }
  }

  static LatLng getLatLngFromDireccion(String direccion, String id) {
    final dirLower = direccion.toLowerCase();
    LatLng base;
    if (dirLower.contains('quito')) {
      base = const LatLng(-0.1807, -78.4678);
    } else if (dirLower.contains('latacunga')) {
      base = const LatLng(-0.9316, -78.6155);
    } else if (dirLower.contains('ambato')) {
      base = const LatLng(-1.2491, -78.6167);
    } else if (dirLower.contains('guayaquil')) {
      base = const LatLng(-2.1708, -79.9224);
    } else if (dirLower.contains('sangolqui') || dirLower.contains('sangolquí')) {
      base = const LatLng(-0.3323, -78.4419);
    } else if (dirLower.contains('aloag') || dirLower.contains('alóag')) {
      base = const LatLng(-0.4677, -78.5835);
    } else if (dirLower.contains('pujili') || dirLower.contains('pujilí')) {
      base = const LatLng(-0.9561, -78.6956);
    } else {
      base = const LatLng(-1.2491, -78.6167);
    }
    final double latOffset = ((id.hashCode & 0xFF) - 128) * 0.00002;
    final double lngOffset = (((id.hashCode >> 8) & 0xFF) - 128) * 0.00002;
    return LatLng(base.latitude + latOffset, base.longitude + lngOffset);
  }

  static Future<LatLng?> buscarCoordenadasNominatim(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final client = HttpClient();
      
      String processedAddress = address.trim();
      final lowerAddress = processedAddress.toLowerCase();
      // If it contains Pujili but not structured, expand it to search town center
      if (lowerAddress.contains('pujili') || lowerAddress.contains('pujilí')) {
        if (!lowerAddress.contains('pujili, pujili') && !lowerAddress.contains('pujilí, pujilí')) {
          processedAddress = 'Pujili, Pujili, Cotopaxi, Ecuador';
        }
      }

      // Nominatim requires a User-Agent header to avoid 403 Forbidden
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(processedAddress)}&format=json&limit=1');
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'OptiRutaApp/1.0 (contact: luis@optiruta.com)');
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(responseBody);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat'].toString());
          final double lon = double.parse(data[0]['lon'].toString());
          debugPrint("Nominatim geocodificó '$address' a ($lat, $lon)");
          return LatLng(lat, lon);
        }
      } else {
        debugPrint("Nominatim retornó estado: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error buscando coordenadas en Nominatim: $e");
    }
    return null;
  }
}
