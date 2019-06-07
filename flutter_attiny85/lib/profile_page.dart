import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';
import 'attiny85_model.dart';

class ProfilePage extends StatefulWidget {
  final UsbPort port;
  ATtiny85 attiny85;
  ProfilePage({Key key, this.port}) : super(key: key)
  {
    attiny85 = new ATtiny85(port);
  }

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  

  
  getStates() async {
    
  }

  @override
  Widget build(BuildContext context) {
    print( widget.attiny85.vcc);
    return Scaffold(
      appBar: AppBar(
        title: Text("Microcontroller profile"),
      ),
      body: Column(
        children: <Widget>[
          Container(
            child: Center(
              child: Column(
                children: <Widget>[
                  Text("VCC: " + widget.attiny85.vcc),
                  Text("freeRAM: " + widget.attiny85.freeRAM),
                  Text("temp: " + widget.attiny85.temperatureInternal),
                  Text("cpuSpeed: " + widget.attiny85.cpuSpeedMHz),
                ],
              ),
            ),
          ),
        Expanded(
                  child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return ListTile(
                title: Row(
                      children: <Widget>[
                         Align(alignment: Alignment.centerLeft, child: Text("Address " + index.toString()+" :")),
                         SizedBox(width: 15.0,),
                        Expanded(child: Align(alignment: Alignment.center, child: TextField(
                  onSubmitted: (value) {
                      print(value);
                  },
                  textAlign: TextAlign.center,
                   decoration: new InputDecoration(labelText: "Enter number between 0 and 255"),
                  keyboardType: TextInputType.number,
                ),)),
                      ],
                    ),
              );
            }),
        ),
        
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.attiny85.sync(),
        tooltip: 'get States',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
