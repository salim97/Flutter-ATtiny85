import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_attiny85/profile_page.dart';
import 'package:usb_serial/transaction.dart';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UsbPort _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  List<Widget> _serialData = [];
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;
  int _deviceId;
  TextEditingController _textController = TextEditingController();

  Future<bool> _connectTo(device) async {
    _serialData.clear();

    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port.close();
      _port = null;
    }

    if (device == null) {
      _deviceId = null;
      setState(() {
        _status = "Disconnected";
      });
      return true;
    }

    _port = await device.create();
    if (!await _port.open()) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }

    _deviceId = device.deviceId;
    await _port.setDTR(true);
    await _port.setRTS(true);
    await _port.setPortParameters(115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(_port.inputStream, Uint8List.fromList([13, 10]));

    _subscription = _transaction.stream.listen((String line) {
      print("_transaction.stream.listen((String line) {");
      print(line);
      setState(() {
        if (line.contains("vcc:")) vcc = line.split(":")[1] + " mV";
        if (line.contains("freeram:")) freeRAM = line.split(":")[1] + " of 512 byte";
        if (line.contains("temperatureinternal:")) temperatureInternal = line.split(":")[1] + " °C";
        if (line.contains("cpuSpeed:")) cpuSpeedMHz = line.split(":")[1] + " MHz";
        if (line.contains("millis:")) millis = line.split(":")[1] + " ms";
        if (line.contains("eeprom:")) {
          eeprom[int.parse(line.split(":")[1].split("=>")[0])] = line.split(":")[1].split("=>")[1].codeUnitAt(0);
        }
        //_serialData.add(Text(line));
        if (_serialData.length > 20) {
          _serialData.removeAt(0);
        }
      });
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  void _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    print(devices);

    devices.forEach((device) {
      _ports.add(ListTile(
          leading: Icon(Icons.usb),
          title: Text(device.productName == null ? " " : device.productName),
          subtitle: Text(device.manufacturerName == null ? " " : device.manufacturerName),
          trailing: RaisedButton(
            child: Text(_deviceId == device.deviceId ? "Disconnect" : "Connect"),
            onPressed: () {
              _connectTo(_deviceId == device.deviceId ? null : device).then((res) {
                _getPorts();
              });
            },
          )));
    });

    setState(() {
      print(_ports);
    });
  }

  Uint8List eeprom = new Uint8List(25);
  String vcc, freeRAM, temperatureInternal, cpuSpeedMHz, millis;

  @override
  void initState() {
    super.initState();

    UsbSerial.usbEventStream.listen((UsbEvent event) {
      _getPorts();
    });

    _getPorts();
  }

  @override
  void dispose() {
    super.dispose();
    _connectTo(null);
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: const Text('USB Serial Plugin example app'),
      ),
      body: Container(
        child: _currentIndex == 0
            ? Center(
                child: Column(children: <Widget>[
                Text(_ports.length > 0 ? "Available Serial Ports" : "No serial devices available", style: Theme.of(context).textTheme.title),
                ..._ports,
                Text('Status: $_status\n'),
                ListTile(
                  leading: Icon(FontAwesomeIcons.bolt),
                  title: Text(vcc.toString()),
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.microchip),
                  title: Text(cpuSpeedMHz.toString()),
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.memory),
                  title: Text(freeRAM.toString()),
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.thermometer),
                  title: Text(temperatureInternal.toString()),
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.clock),
                  title: Text(millis.toString()),
                ),
              ]))
            : ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Row(
                      children: <Widget>[
                        Align(alignment: Alignment.centerLeft, child: Text("Address " + index.toString() + " :")),
                        SizedBox(
                          width: 15.0,
                        ),
                        Expanded(
                            child: Align(
                          alignment: Alignment.center,
                          child: TextField(
                            onSubmitted: (value) async {
                              print(value);
                              if (_port == null) {
                                return;
                              }
                              await _port.write(Uint8List.fromList([101, 115, index, int.parse(value)]));
                              await _port.write(Uint8List.fromList([101, 103, index]));
                            },
                            textAlign: TextAlign.center,
                            decoration: new InputDecoration(labelText: "Enter number between 0 and 255"),
                            keyboardType: TextInputType.number,
                          ),
                        )),
                      ],
                    ),
                    trailing: Text(eeprom[index].toString()),
                  );
                }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _port == null
            ? null
            : () async {
                if (_port == null) {
                  return;
                }
                await _port.write(Uint8List.fromList("s0".codeUnits));
                await _port.write(Uint8List.fromList("ea".codeUnits));
              },
        tooltip: 'get States',
        child: Icon(Icons.refresh),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped, // new
        currentIndex: _currentIndex, // new
        items: [
          new BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.microchip),
            title: Text("ATtiny85"),
          ),
          new BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.memory),
            title: Text("EEPROM"),
          ),
        ],
      ),
    );
  }
}
