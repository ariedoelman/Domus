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
    do {
      try sensors?.onTemperatureAndHumidityChange { th in
        do {
          guard try self.outputHandler.send(text: String(key: "temperature", value: th.temperature)),
            try self.outputHandler.send(text: String(key: "humidity", value: th.humidity))
            else {
              print("Unable to output \(th)")
              self.sensors?.cancelTemperatureAndHumidityChangeReport()
              return
          }
        } catch {
          print("Stopped sending temperature and humidity status, due to error \(error)")
        }
      }

    } catch {
      print("Failed to setup sensors status reports due to error: \(error)")
    }
  }

  public func closed() {
    print("Websocket closed")
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
