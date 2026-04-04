import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkPowerSignalService {
  NetworkPowerSignalService({
    Connectivity? connectivity,
    Battery? battery,
  })  : _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? Battery();

  final Connectivity _connectivity;
  final Battery _battery;

  Future<bool> isWifiConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }

  Future<bool> isCharging() async {
    final state = await _battery.batteryState;
    return state == BatteryState.charging ||
        state == BatteryState.full ||
        state == BatteryState.connectedNotCharging;
  }
}