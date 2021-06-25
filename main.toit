import gpio
import spi

import dbc

import .obd2
import .can

INT := gpio.Pin 4

SCK := gpio.Pin 25
CS1 := gpio.Pin 26
CS2 := gpio.Pin 17
CS3 := gpio.Pin 16
MOSI := gpio.Pin 27
MISO := gpio.Pin 18

main:
  bus := spi.Bus --mosi=MOSI --miso=MISO --clock=SCK

  dev1 := bus.device --cs=CS1 --frequency=250_000
  dev2 := bus.device --cs=CS2 --frequency=250_000
  dev3 := bus.device --cs=CS3 --frequency=20_000_000


  display1 := Display dev1
  display2 := Display dev2
  can := CAN INT dev3

  3.repeat:
    display1.set "5PEE"
    display2.set "ENGI"
    sleep --ms=600
    display1.set "    "
    display2.set "    "
    sleep --ms=400

  dispatcher := dbc.Dispatcher

  display1.number 0
  display2.number 0

  dispatcher.register OBD2Decoder:: | msg |
    if msg is OBD2_ParameterID_Service01_S1_PID_0C_EngineRPM:
      eng := msg as OBD2_ParameterID_Service01_S1_PID_0C_EngineRPM
      display2.number eng.S1_PID_0C_EngineRPM

    if msg is OBD2_ParameterID_Service01_S1_PID_0D_VehicleSpeed:
      speed := msg as OBD2_ParameterID_Service01_S1_PID_0D_VehicleSpeed
      display1.number speed.S1_PID_0D_VehicleSpeed

  task::
    (Duration --ms=500).periodic:
      can.request_pid CAN.PID_ENGINE_SPEED
      sleep --ms=30
      can.request_pid CAN.PID_VEHICLE_SPEED

  while true:
    msg := can.read
    dispatcher.dispatch msg.id msg.data

class Display:
  device_/spi.Device
  constructor .device_:
    // Factory reset.
    device_.registers.write_bytes 0x81 #[]
    sleep --ms=1
    // Clear.
    device_.registers.write_bytes 0x76 #[]
    sleep --ms=1
    // Full brightness
    device_.registers.write_u8 0x7A 255
    sleep --ms=1

  set str/string:
    device_.write str.to_byte_array
    sleep --ms=1

  number i/num:
    device_.write "$(%4d i)".to_byte_array
    sleep --ms=1
