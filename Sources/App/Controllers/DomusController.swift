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
  private var sensors: GrovePiSensors!
  private var thReportID: ChangeReportID?
  private var distanceReportID: ChangeReportID?

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
    if thReportID == nil {
      thReportID = sensors.onTemperatureAndHumidityChange { (temp, humi) in
        do {
          guard try self.outputHandler.send(text: String(key: "temperature", value: temp)),
              try self.outputHandler.send(text: String(key: "humidity", value: humi))
            else {
              self.thReportID?.cancel()
              return
          }
        } catch {
          print("Stopped sending temperature and humidity status")
        }
      }
    }
  }

  public func opened() {
    print("Websocket opened")
    do {
      let sensorUpdates: [String] = [
        String(key: "temperature", value: try sensors.readTemperature()),
        String(key: "humidity", value: try sensors.readHumidity()),
        String(key: "distance", value: try sensors.readDistanceInCentimeters())
      ]
      guard (try sensorUpdates.first { return !(try outputHandler.send(text: $0)) }) == nil else {
        return
      }
    } catch {
      print("Encountered error while updating counters: \(error)")
    }
  }

  public func closed() {
    print("Websocket closed")
  }

//  private func doSendStatus() {
//    sendingUpdates = true
//    usleep(3_000_000)
//    do {
//      let sensorUpdates: [String] = [
//          String(key: "temperature", value: try sensors.readTemperature()),
//          String(key: "humidity", value: try sensors.readHumidity()),
//          String(key: "distance", value: try sensors.readDistanceInCentimeters())
//      ]
//      guard (try sensorUpdates.first { return !(try outputHandler.send(text: $0)) }) == nil else {
//        return
//      }
//      sendingUpdates = false
//      operationQueue.addOperation(doSendStatus)
//    } catch {
//      sendingUpdates = false
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
