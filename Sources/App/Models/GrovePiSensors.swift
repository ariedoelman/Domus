//
//  GrovePiSensors.swift
//  Domus
//
//  Created by Arie Doelman on 03-01-17.
//
//
import GrovePiIO
import Foundation

public final class GrovePiSensors {
  private let thSensor: TemperatureAndHumiditySensorSource
  private let urSensor: UltrasonicRangerSensorSource
  private let lightSensor: LightSensorSource
  private let soundSensor: SoundSensorSource
  private var thReporter: InputValueChangedReporter<TemperatureAndHumidity>?
  private var urReporter: InputValueChangedReporter<DistanceInCentimeters>?
  private var lightReporter: InputValueChangedReporter<Range1024>?
  private var soundReporter: InputValueChangedReporter<Range1024>?

  public init() throws {
    let bus = try GrovePiBus.connectBus()
    thSensor = try bus.connectTemperatureAndHumiditySensor(to: .D7, moduleType: .blue, sampleTimeInterval: 60)
    urSensor = try bus.connectUltrasonicRangerSensor(portLabel: .D3, sampleTimeInterval: 60)
    lightSensor = try bus.connectLightSensor(portLabel: .A0)
    soundSensor = try bus.connectSoundSensor(portLabel: .A1)
  }

  deinit {
    try? GrovePiBus.disconnectBus()
  }

  public func readTemperature() throws -> Float {
    return try thSensor.readValue().temperature
  }

  public func readHumidity() throws -> Float {
    return try thSensor.readValue().humidity
  }

  public func readDistanceInCentimeters() throws -> DistanceInCentimeters {
    return try urSensor.readValue()
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
