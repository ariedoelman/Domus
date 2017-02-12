//
//  DomusController.swift
//  Domus
//
//  Created by Arie Doelman on 03-01-17.
//
//
#if os(Linux)
  import Glibc
#else
  import Darwin.C
#endif
import Foundation
import Vapor
import HTTP
import Socks
import GrovePiIO

public final class DomusController: TextInputHandler {
  private let outputHandler: TextOutputHandler
  private var bus: GrovePiBus?
  private var sensors: GrovePiSensors?
  private var motorModel: MotorModel?

  public init(outputHandler: TextOutputHandler) {
    self.outputHandler = outputHandler
  }

  deinit {
    try? GrovePiBus.disconnectBus()
  }

  public func addRoutes(to droplet: Droplet) {
    droplet.get("domus", handler: showDomusView)
  }

  private func showDomusView(request: Request) throws -> ResponseRepresentable {
    try start()
    let host = request.uri.host
    let portExtension = request.uri.port != nil ? ":\(request.uri.port!)" : ""
    return try drop.view.make("domus", [
      "wsuri": "ws://\(host)\(portExtension)/ws".makeNode(),
      "portconnections": sensors!.buildPortConnectionDescriptions().makeNode()
      ])
  }


  private func start() throws {
    GrovePiBus.printCommands = true
    if bus == nil {
      bus = try GrovePiBus.connectBus()
    }
    if sensors == nil {
      sensors = try GrovePiSensors(bus!)
    }
    if motorModel == nil {
      motorModel = try MotorModel(bus!)
    }
  }

  public func opened() {
    print("Websockets opened")
//    receiveTemperatureAndHumidityChanges()
    receiveDistanceChanges()
//    receiveLightChanges()
//    receiveSoundChanges()
  }

  public func received(text: String) {
    print("Received: \(text)")
    guard let motorModel = self.motorModel else { return }
    let motorControlSettings = text.parseDictionary()
    do {
      if let whichMotor = motorControlSettings["motor"], let motorSelection = MotorSelection(rawValue: whichMotor) {
        if let _ = motorControlSettings["stop"] {
          try motorModel.stopMotor(motorSelection: motorSelection)
        } else if let gearValue = motorControlSettings["gear"], let gear = Range256(gearValue),
          let directionValue = motorControlSettings["direction"], let direction = MotorDirection(rawValue: directionValue) {
          try motorModel.updateDirectionAndSpeed(motorSelection: motorSelection, direction: direction, gear: gear)
        } else {
          print("Incorrect motor settings")
        }
      }
    } catch {
      print("Motor settings: \(error)")
    }
  }

  public func closed() {
    print("Websocket closed")
    sensors?.cancelAllReports()
  }

//  private func receiveTemperatureAndHumidityChanges() {
//    do {
//      try sensors?.onTemperatureAndHumidityChange { th in
//        do {
//          guard try self.outputHandler.send(text: String(key: "temperature", value: th.temperature)),
//            try self.outputHandler.send(text: String(key: "humidity", value: th.humidity))
//            else {
//              print("Unable to output temperature and humidity: \(th)")
//              self.sensors?.cancelTemperatureAndHumidityChangeReport()
//              return
//          }
//        } catch {
//          print("Stopped sending temperature and humidity status, due to error \(error)")
//        }
//      }
//    } catch {
//      _ = try? self.outputHandler.send(text: String(key: "temperature", value: error))
//      _ = try? self.outputHandler.send(text: String(key: "humidity", value: error))
//      print("Failed to setup temperature and humidity sensor continuous status report due to error: \(error)")
//    }
//  }

  private func receiveDistanceChanges() {
    do {
      try sensors?.onDistanceChange { distance in
        do {
          guard try self.outputHandler.send(text: String(key: "distance", value: distance))
            else {
              print("Unable to output distance: \(distance)")
              self.sensors?.cancelDistanceChangeReport()
              return
          }
        } catch {
          print("Stopped sending distance status, due to error \(error)")
        }
      }
    } catch {
      _ = try? self.outputHandler.send(text: String(key: "distance", value: error))
      print("Failed to setup distance sensor continuous status report due to error: \(error)")
    }
  }

//  private func receiveLightChanges() {
//    do {
//      try sensors?.onLightChange { lightLevel in
//        do {
//          guard try self.outputHandler.send(text: String(key: "lightlevel", value: lightLevel))
//            else {
//              print("Unable to output light: \(lightLevel)")
//              self.sensors?.cancelLightChangeReport()
//              return
//          }
//        } catch {
//          print("Stopped sending light status, due to error \(error)")
//        }
//      }
//    } catch {
//      _ = try? self.outputHandler.send(text: String(key: "lightlevel", value: error))
//      print("Failed to setup light sensor continuous status report due to error: \(error)")
//    }
//  }

//  private func receiveSoundChanges() {
//    do {
//      try sensors?.onSoundChange { soundLevel in
//        do {
//          guard try self.outputHandler.send(text: String(key: "soundlevel", value: soundLevel))
//            else {
//              print("Unable to output sound: \(soundLevel)")
//              self.sensors?.cancelSoundChangeReport()
//              return
//          }
//        } catch {
//          print("Stopped sending sound status, due to error \(error)")
//        }
//      }
//    } catch {
//      _ = try? self.outputHandler.send(text: String(key: "soundlevel", value: error))
//      print("Failed to setup sound sensor continuous status report due to error: \(error)")
//    }
//  }

}

private extension String {
  init(key: String, value: Float) {
    self.init("\(key)=\(value)")!
  }
  init(key: String, value: UInt16) {
    self.init("\(key)=\(value)")!
  }
  init(key: String, value: Error) {
    self.init("\(key)=\(value)")!
  }

  func parseDictionary() -> [String:String] {
    let lines = self.components(separatedBy: "\n")
    var result = [String:String]()
    for line in lines {
      let keyValuePair = line.components(separatedBy: "=")
      if keyValuePair.count >= 1 {
        result[keyValuePair[0]] = keyValuePair.count > 1 ? keyValuePair[1] : ""
      }
    }
    return result
  }
}
