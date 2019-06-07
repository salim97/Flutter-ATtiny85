import 'dart:typed_data';

import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

enum CPU { vcc, freeRAM, temperatureInternal, speedMHz }

class ATtiny85 {
  String vcc, freeRAM, temperatureInternal, cpuSpeedMHz;
  Uint8List eeprom, ram;
  final UsbPort port;
  Transaction<String> transaction;
  ATtiny85(this.port) {
    transaction = Transaction.stringTerminated(port.inputStream, Uint8List.fromList([13, 10]));
    port.inputStream.listen((Uint8List event) {
		print(" port.inputStream.listen((Uint8List event) {");
		print(event);
		
	});

    vcc = " ";
    freeRAM = " ";
    temperatureInternal = " ";
    cpuSpeedMHz = " ";
  }

  sync() async {
    String tmp ;
    Transaction<String> t;
    t = Transaction.stringTerminated(port.inputStream, Uint8List.fromList([13, 10]));
    tmp = await t.transaction(port, Uint8List.fromList([115, 1]), Duration(seconds: 10));
    print(" sync() async {") ;
    print(tmp) ;
    return ;
    vcc = await transaction.transaction(port, Uint8List.fromList([115, 1]), Duration(seconds: 1));
    freeRAM = await transaction.transaction(port, Uint8List.fromList([115, 2]), Duration(seconds: 1));
    temperatureInternal = await transaction.transaction(port, Uint8List.fromList([115, 3]), Duration(seconds: 1));
    cpuSpeedMHz = await transaction.transaction(port, Uint8List.fromList([115, 4]), Duration(seconds: 1));
    if(vcc == null ) vcc = " ";
    if(freeRAM == null ) freeRAM = " ";
    if(temperatureInternal == null ) temperatureInternal = " ";
    if(cpuSpeedMHz == null ) cpuSpeedMHz = " ";
    print("sync() async {");
    print(int.parse(vcc));
    print(freeRAM);
    print(temperatureInternal);
    print(cpuSpeedMHz);


  }

  eepromWrite(int index, int value) async {
    await port.write(Uint8List.fromList([101, 115, index, value]));
  }

  Future<String> eepromRead(int index) async {
    var val = await transaction.transaction(port, Uint8List.fromList([101, 115, index]), Duration(seconds: 1));
    return val.toString() ;
  }

  ramAt(int index, int value) {}
}
