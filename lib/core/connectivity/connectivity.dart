import 'package:connectivity_plus/connectivity_plus.dart' as conn;

class Connectivity {
  Future<bool> isAvailable() async {
    final List<conn.ConnectivityResult> connectivityResult =
        await (conn.Connectivity().checkConnectivity());

    if (connectivityResult.contains(conn.ConnectivityResult.none)) {
      return false;
    } else if (connectivityResult.contains(conn.ConnectivityResult.wifi) ||
        connectivityResult.contains(conn.ConnectivityResult.mobile) ||
        connectivityResult.contains(conn.ConnectivityResult.ethernet) ||
        connectivityResult.contains(conn.ConnectivityResult.vpn)) {
      return true;
    }
    return false;
  }
}
