// import 'package:check_vpn_connection/check_vpn_connection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionChecker {
  static Future<ConnectionStatus> isConnect() async {
    List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return ConnectionError('لطفا اتصال اینترنت خود را بررسی نمائید');
    }

    // bool isVPNActive = await CheckVpnConnection.isVpnActive();
    // if (isVPNActive) {
    //   return ConnectionError('لطفا فیلترشکن خود را خاموش نمائید');
    // }

    return ConnectionOK();
  }
}

class ConnectionStatus {}

class ConnectionOK extends ConnectionStatus {}

class ConnectionError extends ConnectionStatus {
  final String message;
  ConnectionError(this.message);
}
