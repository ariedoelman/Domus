//
//  GrovePiSensors.swift
//  Domus
//
//  Created by Arie Doelman on 03-01-17.
//
//
import GrovePiIO
import Foundation
import Vapor

public struct PortConnectionDescription: NodeRepresentable {
  public let port: String
  public let unit: String
  public let status: String
  public let value: String

  public init<S: GrovePiInputSource>(source: S, value: String) {
    self.port = source.portLabel.name
    self.unit = source.inputUnit.name
    self.status = source.delegatesCount > 0 ? "Sampling" : ""
    self.value = value
  }

  public func makeNode(context: Context) throws -> Node {
    return try Node(node: [
      "port": port,
      "unit": unit,
      "status": status,
      "value": value
      ])
  }

}


public final class GrovePiSensors {
  private let thSensor: TemperatureAndHumiditySensorSource
  private let urSensor: UltrasonicRangerSensorSource
  private let lightSensor: LightSensorSource
  private let soundSensor: SoundSensorSource
  private var thReporter: InputValueChangedReporter<TemperatureAndHumidity>?
  private var urReporter: InputValueChangedReporter<DistanceInCentimeters>?
  private var lightReporter: InputValueChangedReporter<Range1024>?
  private var soundReporter: InputValueChangedReporter<Range1024>?

  public init(_ bus: GrovePiBus) throws {
    thSensor = try bus.connectTemperatureAndHumiditySensor(to: .D7, moduleType: .blue, sampleTimeInterval: 5)
    urSensor = try bus.connectUltrasonicRangerSensor(portLabel: .D5, sampleTimeInterval: 1)
    lightSensor = try bus.connectLightSensor(portLabel: .A0, sampleTimeInterval: 1)
    soundSensor = try bus.connectSoundSensor(portLabel: .A1, sampleTimeInterval: 1)
  }

  public func buildPortConnectionDescriptions() -> [PortConnectionDescription] {
    var connections = [PortConnectionDescription]()
    connections.append(PortConnectionDescription(source: thSensor, value: "temperature"))
    connections.append(PortConnectionDescription(source: thSensor, value: "humidity"))
    connections.append(PortConnectionDescription(source: urSensor, value: "distance"))
    connections.append(PortConnectionDescription(source: lightSensor, value: "lightlevel"))
    connections.append(PortConnectionDescription(source: soundSensor, value: "soundlevel"))
    return connections
  }

  public func onTemperatureAndHumidityChange(report: @escaping (TemperatureAndHumidity) -> ()) throws {
    guard thReporter == nil else { return }
    thReporter = InputValueChangedReporter(reportNewInput: report)
    try thSensor.addValueChangedDelegate(thReporter!)
  }

  public func cancelTemperatureAndHumidityChangeReport() {
    if let thReporter = self.thReporter {
      self.thReporter = nil
      try? thSensor.removeValueChangedDelegate(thReporter)
    }
  }

  public func onDistanceChange(report: @escaping (DistanceInCentimeters) -> ()) throws {
    guard urReporter == nil else { return }
    urReporter = InputValueChangedReporter(reportNewInput: report)
    try urSensor.addValueChangedDelegate(urReporter!)
  }

  public func cancelDistanceChangeReport() {
    if let urReporter = self.urReporter {
      self.urReporter = nil
      try? urSensor.removeValueChangedDelegate(urReporter)
    }
  }

  public func onLightChange(report: @escaping (Range1024) -> ()) throws {
    guard lightReporter == nil else { return }
    lightReporter = InputValueChangedReporter(reportNewInput: report)
    try lightSensor.addValueChangedDelegate(lightReporter!)
  }

  public func cancelLightChangeReport() {
    if let lightReporter = self.lightReporter {
      self.lightReporter = nil
      try? lightSensor.removeValueChangedDelegate(lightReporter)
    }
  }

  public func onSoundChange(report: @escaping (Range1024) -> ()) throws {
    guard soundReporter == nil else { return }
    soundReporter = InputValueChangedReporter(reportNewInput: report)
    try soundSensor.addValueChangedDelegate(soundReporter!)
  }

  public func cancelSoundChangeReport() {
    if let soundReporter = self.soundReporter {
      self.soundReporter = nil
      try? soundSensor.removeValueChangedDelegate(soundReporter)
    }
  }
  
  public func cancelAllReports() {
    cancelTemperatureAndHumidityChangeReport()
    cancelDistanceChangeReport()
    cancelLightChangeReport()
    cancelSoundChangeReport()
  }

}
