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
  private var sensors: GrovePiSensors?

  public init(outputHandler: TextOutputHandler) {
    self.outputHandler = outputHandler
  }

  public func addRoutes(to droplet: Droplet) {
    droplet.get("domus", handler: showDomusView)
  }

  public func received(text: String) {
    print("Received: \(text)")
  }

  private func showDomusView(request: Request) throws -> ResponseRepresentable {
    try start()
    let host = request.uri.host
    let portExtension = request.uri.port != nil ? ":\(request.uri.port!)" : ""
    return try drop.view.make("domus", [
      "wsuri": "ws://\(host)\(portExtension)/ws"])
  }

  private func start() throws {
    if sensors == nil {
      sensors = try GrovePiSensors()
    }
  }

  public func opened() {
    print("Websockets opened")
    receiveTemperatureAndHumidityChanges()
    receiveDistanceChanges()
    receiveLightChanges()
    receiveSoundChanges()
  }

  public func closed() {
    print("Websocket closed")
    sensors?.cancelAllReports()
  }

  private func receiveTemperatureAndHumidityChanges() {
    do {
      try sensors?.onTemperatureAndHumidityChange { th in
        do {
          guard try self.outputHandler.send(text: String(key: "temperature", value: th.temperature)),
            try self.outputHandler.send(text: String(key: "humidity", value: th.humidity))
            else {
              print("Unable to output temperature and humidity: \(th)")
              self.sensors?.cancelTemperatureAndHumidityChangeReport()
              return
          }
        } catch {
          print("Stopped sending temperature and humidity status, due to error \(error)")
        }
      }
    } catch {
      print("Failed to setup temperature and humidity sensor continuous status report due to error: \(error)")
    }
  }

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
      print("Failed to setup distance sensor continuous status report due to error: \(error)")
    }
  }

  private func receiveLightChanges() {
    do {
      try sensors?.onLightChange { lightLevel in
        do {
          guard try self.outputHandler.send(text: String(key: "light", value: lightLevel))
            else {
              print("Unable to output light: \(lightLevel)")
              self.sensors?.cancelLightChangeReport()
              return
          }
        } catch {
          print("Stopped sending light status, due to error \(error)")
        }
      }
    } catch {
      print("Failed to setup light sensor continuous status report due to error: \(error)")
    }
  }

  private func receiveSoundChanges() {
    do {
      try sensors?.onSoundChange { soundLevel in
        do {
          guard try self.outputHandler.send(text: String(key: "soundlevel", value: soundLevel))
            else {
              print("Unable to output sound: \(soundLevel)")
              self.sensors?.cancelSoundChangeReport()
              return
          }
        } catch {
          print("Stopped sending sound status, due to error \(error)")
        }
      }
    } catch {
      print("Failed to setup sound sensor continuous status report due to error: \(error)")
    }
  }

//  private func doSendStatus() {
//    do {
//      let sensorUpdates: [String] = [
//          String(key: "temperature", value: try sensors.readTemperature()),
//          String(key: "humidity", value: try sensors.readHumidity()),
//          String(key: "distance", value: try sensors.readDistanceInCentimeters())
//      ]
//      guard (try sensorUpdates.first { return !(try outputHandler.send(text: $0)) }) == nil else {
//        return
//      }
//    } catch {
//      print("Stopped sending status")
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
}
