#include <DigiCDC.h>
#include <avr/sleep.h>
#include <avr/power.h>
#include <EEPROM.h>

int getMHz();
int8_t getTemperatureInternal();
int getVCC();
int getFreeRAM();
#define LED_BUILDIN 1 

void setup() {
        // initialize the digital pin as an output.
        SerialUSB.begin();
        pinMode(LED_BUILDIN,OUTPUT);

}
char recievedData[10];

// the loop routine runs over and over again forever:
void loop() {
        recievedData[0] = 0;
        recievedData[1] = 0;
        recievedData[2] = 0;
        recievedData[3] = 0;
        //turns led on and off based on sending 0 or 1 from serial terminal
        if (SerialUSB.available()) {

                recievedData[0] = SerialUSB.read();
                recievedData[1] = SerialUSB.read();
                if(recievedData[0] == 's')
                        switch (recievedData[1]) {
                        case '0':
                                SerialUSB.print("vcc:"); SerialUSB.println(getVCC());
                                SerialUSB.print("freeram:"); SerialUSB.println(getFreeRAM());
                                SerialUSB.print("temperatureinternal:"); SerialUSB.println(getTemperatureInternal());
                                SerialUSB.print("cpuSpeed:"); SerialUSB.println(getMHz());
                                SerialUSB.print("millis:");  SerialUSB.println(millis());
                                break;
                        case '1':
                                SerialUSB.print("vcc:");
                                SerialUSB.println(getVCC());
                                break;
                        case '2':
                                SerialUSB.print("freeram:");
                                SerialUSB.println(getFreeRAM());
                                break;
                        case '3':
                                SerialUSB.print("temperatureinternal:");
                                SerialUSB.println(getTemperatureInternal());
                                break;
                        case '4':
                                SerialUSB.print("cpuSpeed:");
                                SerialUSB.println(getMHz());
                                break;
                        case '5':
                                SerialUSB.print("millis:");
                                SerialUSB.println(millis());
                                break;
                        default:
                                SerialUSB.println("ERROR");
                                break;
                        }
                if(recievedData[0] == 'e' )
                {
                        recievedData[2] = SerialUSB.read();
                        if( recievedData[1] == 's')
                        {
                                recievedData[3] = SerialUSB.read();
                                EEPROM.write(recievedData[2], recievedData[3]);
                        }
                        if( recievedData[1] == 'g')
                        {
                                SerialUSB.print("eeprom:");
                                SerialUSB.print((int)recievedData[2]);
                                SerialUSB.print("=>");
                                SerialUSB.println(EEPROM.read((int)recievedData[2]));
                        }
                        if( recievedData[1] == 'a')
                            for(int i = 0 ; i < 16 ; i++)
                            {
                                  SerialUSB.print("eeprom:");
                                  SerialUSB.print(i);
                                  SerialUSB.print("=>");
                                  SerialUSB.println(EEPROM.read(i));
                            }

                }
                if(recievedData[0] == 'l' )
                  if(recievedData[1] == '0' )
                      digitalWrite(LED_BUILDIN, HIGH);
                  else
                       digitalWrite(LED_BUILDIN, LOW);

        }

        SerialUSB.delay(1);          // keep usb alive // can alos use SerialUSB.refresh();
}

int getVCC() {
        //reads internal 1V1 reference against VCC
  #if defined(__AVR_ATtiny84__) || defined(__AVR_ATtiny44__)
        ADMUX = _BV(MUX5) | _BV(MUX0); // For ATtiny84
  #elif defined(__AVR_ATtiny85__) || defined(__AVR_ATtiny45__)
        ADMUX = _BV(MUX3) | _BV(MUX2); // For ATtiny85/45
  #elif defined(__AVR_ATmega1284P__)
        ADMUX = _BV(REFS0) | _BV(MUX4) | _BV(MUX3) | _BV(MUX2) | _BV(MUX1); // For ATmega1284
  #else
        ADMUX = _BV(REFS0) | _BV(MUX3) | _BV(MUX2) | _BV(MUX1); // For ATmega328
  #endif
        delay(2); // Wait for Vref to settle
        ADCSRA |= _BV(ADSC); // Convert
        while (bit_is_set(ADCSRA, ADSC));
        uint8_t low = ADCL;
        unsigned int val = (ADCH << 8) | low;
        //discard previous result
        ADCSRA |= _BV(ADSC); // Convert
        while (bit_is_set(ADCSRA, ADSC));
        low = ADCL;
        val = (ADCH << 8) | low;

        return ((long)1024 * 1100) / val;
}

int getFreeRAM() {
        extern int __bss_end;
        extern int  *__brkval;
        int free_memory;
        if((int)__brkval == 0) {
                free_memory = ((int)&free_memory) - ((int)&__bss_end);
        }
        else {
                free_memory = ((int)&free_memory) - ((int)__brkval);
        }
        return free_memory;
}

int8_t getTemperatureInternal() {
        /* from the data sheet
           Temperature / °C -45°C +25°C +85°C
           Voltage     / mV 242 mV 314 mV 380 mV
         */
        ADMUX = (1<<REFS0) | (1<<REFS1) | (1<<MUX3); //turn 1.1V reference and select ADC8
        delay(2); //wait for internal reference to settle
        // start the conversion
        ADCSRA |= bit(ADSC);
        //sbi(ADCSRA, ADSC);
        // ADSC is cleared when the conversion finishes
        while (ADCSRA & bit(ADSC));
        //while (bit_is_set(ADCSRA, ADSC));
        uint8_t low  = ADCL;
        uint8_t high = ADCH;
        //discard first reading
        ADCSRA |= bit(ADSC);
        while (ADCSRA & bit(ADSC));
        low  = ADCL;
        high = ADCH;
        int a = (high << 8) | low;
        return a - 272; //return temperature in C
}

int getMHz() {
        return F_CPU / 1000000;
}

