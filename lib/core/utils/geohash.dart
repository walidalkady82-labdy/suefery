class GeohashUtils {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes a latitude/longitude pair into a Geohash string.
  /// [precision] determines the length of the hash (default 10 is very precise).
  static String encode(double lat, double lon, {int precision = 10}) {
    String geohash = '';
    bool evenBit = true;
    double latMin = -90, latMax = 90;
    double lonMin = -180, lonMax = 180;
    int bit = 0;
    int ch = 0;

    while (geohash.length < precision) {
      double mid;

      if (evenBit) {
        mid = (lonMin + lonMax) / 2;
        if (lon > mid) {
          ch |= (1 << (4 - bit));
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        mid = (latMin + latMax) / 2;
        if (lat > mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      evenBit = !evenBit;
      if (bit < 4) {
        bit++;
      } else {
        geohash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }

    return geohash;
  }
}