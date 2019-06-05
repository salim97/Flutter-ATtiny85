import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';
import 'attiny85_model.dart';

class ProfilePage extends StatefulWidget {
  final UsbPort port;

  const ProfilePage({Key key, this.port}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String cpuSpeed = " ", temp = " ", freeRAM = " ", vcc = " ";
  getStates() async {
    Transaction<String> transaction = Transaction.stringTerminated(widget.port.inputStream, Uint8List.fromList([13, 10]));

    String _cpuSpeed, _temp, _freeRAM, _vcc;
    _vcc = await transaction.transaction(widget.port, Uint8List.fromList([50]), Duration(seconds: 1));
    _freeRAM = await transaction.transaction(widget.port, Uint8List.fromList([51]), Duration(seconds: 1));
    _temp = await transaction.transaction(widget.port, Uint8List.fromList([52]), Duration(seconds: 1));
    _cpuSpeed = await transaction.transaction(widget.port, Uint8List.fromList([53]), Duration(seconds: 1));
    setState(() {
      vcc = _vcc;
      freeRAM = _freeRAM;
      temp = _temp;
      cpuSpeed = _cpuSpeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Microcontroller profile"),
      ),
      body: Container(
        child: Center(
          child: Column(
            children: <Widget>[
              Text("VCC: " + vcc),
              Text("freeRAM: " + freeRAM),
              Text("temp: " + temp),
              Text("cpuSpeed: " + cpuSpeed),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getStates,
        tooltip: 'get States',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
