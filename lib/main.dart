import 'package:flutter/material.dart';
import 'package:esense_flutter/esense.dart';
import 'dart:async';

import './stream_chart/stream_chart.dart';
import './stream_chart/chart_legend.dart';
import 'package:audio_service/audio_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth Headphones Accelerometer'),
        ),
        body: BluetoothAccelerometer(title: "Song Control"),
      ),
    );
  }
}



class BluetoothAccelerometer extends StatefulWidget {
  const BluetoothAccelerometer({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _BluetoothAccelerometerState createState() => _BluetoothAccelerometerState();
}

class _BluetoothAccelerometerState extends State<BluetoothAccelerometer> {
  final String _deviceName = "eSense-0539";
  double _x = 0;
  double _y = 0;
  double _z = 0;
  double _lastX = 0;
  double _threshold = 1.5;

  @override
  void initState() {
    super.initState();
    // Connect to the Bluetooth headphones
    _connectToESense();
    }

  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     children: <Widget>[
  //       Text('Device: $_deviceName'),
  //       Text('X: $_x'),
  //       Text('Y: $_y'),
  //       Text('Z: $_z'),
  //     ],
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<ConnectionEvent>(
        stream: ESenseManager().connectionEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            switch (snapshot.data!.type) {
              case ConnectionType.connected:
                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: StreamChart<SensorEvent>(
                          stream: ESenseManager().sensorEvents,
                          handler: _handleAccel,
                          timeRange: const Duration(seconds: 10),
                          minValue: -20000.0,
                          maxValue: 20000.0,
                        ),
                      ),
                    ),
                    const ChartLegend(label: "Accel")
                  ],
                );
              case ConnectionType.unknown:
                return ReconnectButton(
                  child: const Text("Connection: Unknown"),
                  onPressed: _connectToESense,
                );
              case ConnectionType.disconnected:
                return ReconnectButton(
                  child: const Text("Connection: Disconnected"),
                  onPressed: _connectToESense,
                );
              case ConnectionType.device_found:
                return const Center(child: Text("Connection: Device found"));
              case ConnectionType.device_not_found:
                return ReconnectButton(
                  child: Text("Connection: Device not found - $_deviceName"),
                  onPressed: _connectToESense,
                );
            }
          } else {
            return const Center(child: Text("Waiting for Connection Data..."));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    ESenseManager().disconnect();
    super.dispose();
  }

Future<void> _connectToESense() async {
  await ESenseManager().disconnect();
  bool hasSuccessfulConneted = await ESenseManager().connect(_deviceName);
  print("hasSuccessfulConneted: $hasSuccessfulConneted");
}

List<double> _handleAccel(SensorEvent event) {
  if (event.accel != null) {
    return [
      event.accel![0].toDouble(),
      event.accel![1].toDouble(),
      event.accel![2].toDouble(),
    ];
  } else {
    return [0.0, 0.0, 0.0];
  }
}



  void skipToNextSong() {
    // Skip to the next song
    AudioService.skipToNext();
  }
}




class ReconnectButton extends StatelessWidget {
  const ReconnectButton({Key? key, required this.child, required this.onPressed}) : super(key: key);

  final Widget child;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        child,
        ElevatedButton(
          onPressed: onPressed,
          child: const Text("Connect To eSense"),
        )
      ]),
    );
  }
}
