//
//  GrovePiSensors.swift
//  Domus
//
//  Created by Arie Doelman on 03-01-17.
//
//
import GrovePiIO

public final class GrovePiSensors {
  private let thSensor: TemperatureAndHumiditySensor
  private let urSensor: UltrasonicRangeSensor

  public init() throws {
    let bus = try GrovePiBusFactory.getBus()
    thSensor = try bus.temperatureAndHumiditySensor(at: .D7, moduleType: .blue)
    urSensor = try bus.ultrasonicRangeSensor(at: .D3)
  }

  public func readTemperature() throws -> Float {
    return try thSensor.readTemperatureAndHumidity().temperature
  }

  public func readHumidity() throws -> Float {
    return try thSensor.readTemperatureAndHumidity().humidity
  }

  public func readDistanceInCentimeters() throws -> UInt16 {
    return try urSensor.readCentimeters()
  }

  public func onTemperatureAndHumidityChange(report: @escaping ((Float, Float)) -> ()) -> ChangeReportID {
    return thSensor.onChange(report: report)
  }

  public func onDistanceChange(report: @escaping (UInt16) -> ()) -> ChangeReportID {
    return urSensor.onChange(report: report)
  }

}

