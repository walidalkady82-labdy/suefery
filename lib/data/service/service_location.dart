import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class ServiceLocation {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Requests permission and gets the current device location.
  /// Throws an exception if services are disabled or permissions are denied.
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them to use SUEFERY.');
    }

    // 2. Check permission status.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. We need your location to find the nearest store.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in settings.');
    } 

    // 3. Get the position (High accuracy is needed for that <15 min promise)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10));
  }

  /// Encodes latitude and longitude into a Geohash string.
  String encodeGeohash(double lat, double lon, {int precision = 9}) {
    int idx = 0; 
    int bit = 0; 
    bool evenBit = true; 
    String geohash = '';

    double latMin = -90;
    double latMax = 90;
    double lonMin = -180;
    double lonMax = 180;

    while (geohash.length < precision) {
      if (evenBit) {
        double lonMid = (lonMin + lonMax) / 2;
        if (lon >= lonMid) {
          idx = idx * 2 + 1;
          lonMin = lonMid;
        } else {
          idx = idx * 2;
          lonMax = lonMid;
        }
      } else {
        double latMid = (latMin + latMax) / 2;
        if (lat >= latMid) {
          idx = idx * 2 + 1;
          latMin = latMid;
        } else {
          idx = idx * 2;
          latMax = latMid;
        }
      }
      evenBit = !evenBit;

      if (++bit == 5) {
        geohash += _base32[idx];
        bit = 0;
        idx = 0;
      }
    }
    return geohash;
  }

  /// Calculates the Great-Circle distance in Kilometers (Haversine).
  double calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; 
    const earthRadiusKm = 6371.0;

    var c = math.cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    
    return earthRadiusKm * 2 * math.asin(math.sqrt(a));
  }
}