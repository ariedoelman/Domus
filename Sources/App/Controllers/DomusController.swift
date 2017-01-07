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

public final class DomusController: TextInputHandler {
  private let outputHandler: TextOutputHandler
  private let operationQueue: OperationQueue
  private var sendingUpdates: Bool = false
  private var sensors: GrovePiSensors!

  public init(outputHandler: TextOutputHandler) {
    self.outputHandler = outputHandler
    operationQueue = OperationQueue()
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
    guard !sendingUpdates else { return }
    if sensors == nil {
      sensors = try GrovePiSensors()
    }
    operationQueue.addOperation(doSendStatus)
  }

  private func doSendStatus() {
    sendingUpdates = true
    usleep(3_000_000)
    do {
      let sensorUpdates: [String] = [
          String(key: "temperature", value: try sensors.readTemperature()),
          String(key: "humidity", value: try sensors.readHumidity()),
          String(key: "distance", value: try sensors.readDistanceInCentimeters())
      ]
      guard (try sensorUpdates.first { return !(try outputHandler.send(text: $0)) }) == nil else {
        return
      }
      sendingUpdates = false
      operationQueue.addOperation(doSendStatus)
    } catch {
      sendingUpdates = false
      print("Stopped sending status")
    }
  }

}

private extension String {
  init(key: String, value: Float) {
    self.init("\(key)=\(value)")!
  }
  init(key: String, value: UInt16) {
    self.init("\(key)=\(value)")!
  }
}
