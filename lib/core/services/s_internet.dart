import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final internetServiceProvider = Provider<InternetService>((ref) {
  return InternetService();
});

class InternetService {
  Future<bool> isConnected() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();

      // No network available
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return false;
      }

      // Verify actual internet access
      return await InternetConnection().hasInternetAccess;
    } catch (e) {
      return false;
    }
  }
}
