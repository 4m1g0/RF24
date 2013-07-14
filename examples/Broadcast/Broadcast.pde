/*
 Copyright (C) 2013 4m1g0 <dev.4m1g0@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

/**
 * Example for Broadcast with nRF24L01+ radios. 
 *
 * This is an example of how to broadcast with the RF24 class.  Write this 
 * sketch to two different nodes changing the address.
 */

#include <SPI.h>
#include "nRF24L01.h"
#include "RF24.h"
#include "printf.h"

//
// Hardware configuration
//

// Set up nRF24L01 radio on SPI bus plus pins 9 & 10 

RF24 radio(9,10);

//
// Topology
//

// Radio pipe addresses for the 2 nodes to communicate.
const uint64_t pipes[2] = { 0xFFFFFFFF00LL, 0xFFFFFFFF01LL }; // all reading pipes must share first 32 bits (datasheet pag 40)
const uint64_t bcastAddr = 0xFFFFFFFFFFLL; // 5 bytes

// nombre de la maquina
const char name[10] = "maquina1";

void setup(void)
{
  //
  // Print preamble
  //

  Serial.begin(57600);
  printf_begin();
  printf("\n\rRF24/examples/Broadcast/\n\r");
  printf("*** PRESS 'T' to transmit and 'B' to bradcast\n\r");

  //
  // Setup and configure rf radio
  //

  radio.begin();

  // optionally, increase the delay between retries & # of retries
  radio.setRetries(15,15);

  // optionally, reduce the payload size.  seems to
  // improve reliability
  //radio.setPayloadSize(8);

  //
  // Open pipes to other nodes for communication
  //

  // This simple sketch opens three pipes for these two nodes to communicate
  // Open 'our' pipe for writing
  // Open the 'other' pipe for reading, in position #1 (we can have up to 5 pipes open for reading)
  // The thirth pipe is for broadcast (reading and writing)

  // Leemos en la direccion de broadcast
  radio.openReadingPipe(1,bcastAddr);
  
  // Leemos en nuestro direccion local
  radio.openReadingPipe(2,pipes[0]);

  //
  // Start listening
  //

  radio.startListening();

  //
  // Dump the configuration of the rf unit for debugging
  //
  delay(5000); // Delay 5s waiting for terminal
  radio.printDetails();
}

void loop(void)
{
  // if there is data ready
  if ( radio.available() )
  {
    // Dump the payloads until we've gotten everything
    char got_name[10];
    bool done = false;
    while (!done)
    {
      // Fetch the payload, and see if this was the last one.
      done = radio.read(got_name, sizeof(char) * 10);

      // Imprimimos lo recibido
      printf("Received: %s...\r\n", got_name);
    }
  }


  // Leemos el serial
  if ( Serial.available() )
  {
    char c = toupper(Serial.read());
    if ( c == 'T')
    {
      printf("Trying to transmit to %X...\n\r", pipes[1]);

      // Transmitimos hacia la direccion privada de la otra maquina
      radio.openWritingPipe(pipes[1]);
      
      // Paramos de escuchar para poder hablar
      radio.stopListening();
      
      // Enviamos nuestro nombre de maquina
      bool ok = radio.write(name, sizeof(char*) * 10 );
      
      if (ok)
        printf("ok...\n\r");
      else
        printf("failed.\n\r");

      // Ahora continuamos escuchando
      radio.startListening();
    }
    else if ( c == 'B')
    {
      printf("Trying to broadcast...\n\r");
      
      // Transmitimos hacia la direccion de broadcast
      radio.openWritingPipe(bcastAddr);
      
      // Paramos de escuchar para poder hablar
      radio.stopListening();
      
      // Enviamos nuestro nombre de maquina
      bool ok = radio.write(name, sizeof(char) * 10);
      
      if (ok)
        printf("ok...\n\r");
      else
        printf("failed.\n\r");

      // Ahora continuamos escuchando
      radio.startListening();
    }
  }
}
// vim:cin:ai:sts=2 sw=2 ft=cpp
