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

public final class DomusController: TextInputHandler {
  private let outputHandler: TextOutputHandler
  private let operationQueue: OperationQueue
  private var sendingUpdates: Bool = false

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
    start()
    return try drop.view.make("domus", [
      "wsurl": "ws://localhost:8080/ws"])
  }

  private func start() {
    guard !sendingUpdates else { return }
    operationQueue.addOperation(doSendStatus)
  }

  private func doSendStatus() {
    sendingUpdates = true
    usleep(3_000_000)
    do {
      guard try outputHandler.send(text: String(key: "temperature", value: -1.0)) else {
        return
      }
      guard try outputHandler.send(text: String(key: "humidity", value: 99.9)) else {
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
}
