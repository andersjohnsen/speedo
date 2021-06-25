import serial.protocols.spi as spi
import gpio
import mcp2518fd

class CAN:
  static PID_ENGINE_SPEED   ::= 0x0C
  static PID_VEHICLE_SPEED  ::= 0x0D

  static PID_REQUEST_ ::= 0x7DF
  static PID_REPLY_   ::= 0x7E8

  driver_/mcp2518fd.Driver

  constructor interrupt/gpio.Pin device/spi.Device:
    driver_ = mcp2518fd.Driver device

    driver_.configure

    task --background::
      driver_.run interrupt

  request_pid pid/int:
    msg := mcp2518fd.Message
      PID_REQUEST_
      #[2, 1, pid, 0, 0, 0, 0, 0]
    driver_.send msg

  read:
    return driver_.receive
