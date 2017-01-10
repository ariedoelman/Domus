//
//  WebsocketController.swift
//  Domus
//
//  Created by Arie Doelman on 03-01-17.
//
//
import Vapor
import HTTP

public final class WebsocketController: TextOutputHandler {
  private let inputHandler: TextInputHandler
  private var websocket: WebSocket? = nil

  public init(inputHandler: TextInputHandler) {
    self.inputHandler = inputHandler
  }

  public func addRoutes(to droplet: Droplet) {
    droplet.socket("ws", handler: openWebsocket)
  }

  private func openWebsocket(request req: Request, websocket ws: WebSocket) throws {
    websocket = ws
    // ping the socket to keep it open
    try background {
      while ws.state == .open {
        try? ws.ping()
        drop.console.wait(seconds: 10) // every 10 seconds
      }
    }

    ws.onText = { _, text in
      self.inputHandler.received(text: text)
    }

    ws.onClose = { ws, code, reason, clean in
      self.websocket = nil
      self.inputHandler.closed()
    }

    inputHandler.opened()
  }

  public func send(text: String) throws -> Bool {
    guard let websocket = self.websocket else {
      return false
    }
    try websocket.send(text)
    return true
  }

}
