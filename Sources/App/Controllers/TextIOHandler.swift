//
//  SendStatus.swift
//  Domus
//
//  Created by Arie Doelman on 03-01-17.
//
//

public protocol TextInputHandler: class {
  func received(text: String)
}

public protocol TextOutputHandler: class {
  func send(text: String) throws -> Bool
}

public final class TextIOConnector: TextInputHandler, TextOutputHandler {
  private weak var inputHandler: TextInputHandler?
  private weak var outputHandler: TextOutputHandler?

  public init() {
  }

  public func connect(inputSource: TextInputHandler, outputDestination: TextOutputHandler) {
    self.inputHandler = inputSource
    self.outputHandler = outputDestination
  }

  public func send(text: String) throws -> Bool {
    guard let outputHandler = self.outputHandler else {
      return false
    }
    return try outputHandler.send(text: text)
  }

  public func received(text: String) {
    guard let inputHandler = self.inputHandler else {
      return
    }
    inputHandler.received(text: text)
  }


}
