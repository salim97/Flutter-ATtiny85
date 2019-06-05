import 'package:flutter/material.dart';
import 'package:flutter_attiny85/profile_page.dart';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
//import 'dart:convert';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UsbPort _port;
  List<UsbDevice> _devices = [];
  _scan() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();

    print(devices);

    if (devices.length == 0) {
      return;
    }
    setState(() {
      _devices = devices;
    });
    return;
  }

  void initState() {
    super.initState();
    UsbSerial.usbEventStream.listen((UsbEvent event) {
      print("Usb Event $event");
      _scan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
          itemCount: this._devices.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.developer_board),
              title: Text("Device ID: " + _devices[index].deviceId.toString()),
              subtitle: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Align(alignment: Alignment.center, child: Text("pid: " + _devices[index].pid.toString()))),
                      Expanded(child: Align(alignment: Alignment.center, child: Text("vid: " + _devices[index].vid.toString()))),
                    ],
                  ),
                  Align(alignment: Alignment.centerLeft, child: Text("product: " + _devices[index].productName)),
                  Align(alignment: Alignment.centerLeft, child: Text("manufacturer: " + _devices[index].manufacturerName)),
                ],
              ),
              onTap: () async {
                _port = await _devices[index].create();

                bool openResult = await _port.open();
                if (!openResult) {
                  print("Failed to open");
                  Scaffold.of(context).showSnackBar(new SnackBar(
                    content: Text("Failed to open " + _port.toString()),
                  ));
                  return;
                }

                await _port.setDTR(true);
                await _port.setRTS(true);
                _port.setPortParameters(115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

                Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context) => new ProfilePage(port: _port,)));
              },
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: _scan,
        tooltip: 'Scan Connected Devices',
        child: Icon(Icons.search),
      ),
    );
  }
}
