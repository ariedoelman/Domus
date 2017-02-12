//
//  MotorModel.swift
//  Domus
//
//  Created by Arie Doelman on 11-02-17.
//
//

import Foundation
import GrovePiIO

public enum MotorSelection: String {
  case left, right, both
}

public final class MotorModel {
  private let dualMotor: MotorDriveDestination
  private var dualMotorSettings: DualMotorGearAndDirection

  public var leftMotorDirection: MotorDirection { return dualMotorSettings.motorA.direction! }
  public var leftMotorGear: Range256 { return dualMotorSettings.motorA.gear! }
  public var isLeftMotorStopped: Bool { return leftMotorGear == 0 }
  public var rightMotorDirection: MotorDirection { return dualMotorSettings.motorA.direction! }
  public var rightMotorGear: Range256 { return dualMotorSettings.motorA.gear! }
  public var isRightMotorStopped: Bool { return rightMotorGear == 0 }

  public init(_ bus: GrovePiBus) throws {
    dualMotor = try bus.connectDualMotorDrive(portLabel: .I2C_2)
    dualMotorSettings = DualMotorGearAndDirection(motorAB: MotorGearAndDirection(gear: 0, direction: .none))
  }

  public func updateDirectionAndSpeed(motorSelection: MotorSelection, direction: MotorDirection, gear: Range256) throws {
    let updatedDualMotorSettings: DualMotorGearAndDirection
    switch motorSelection {
    case .left:
      if direction == leftMotorDirection {
        guard gear != leftMotorGear else { return }
        updatedDualMotorSettings = DualMotorGearAndDirection(gearA: gear, gearB: rightMotorGear)
      } else if gear == leftMotorGear {
        updatedDualMotorSettings = DualMotorGearAndDirection(directionA: direction, directionB: rightMotorDirection)
      } else {
        updatedDualMotorSettings = DualMotorGearAndDirection(motorA: MotorGearAndDirection(gear: gear, direction: direction),
                                                             motorB: dualMotorSettings.motorB)
      }
    case .right:
      if direction == rightMotorDirection {
        guard gear != rightMotorGear else { return }
        updatedDualMotorSettings = DualMotorGearAndDirection(gearA: leftMotorGear, gearB: gear)
      } else if gear == rightMotorGear {
        updatedDualMotorSettings = DualMotorGearAndDirection(directionA: leftMotorDirection, directionB: direction)
      } else {
        updatedDualMotorSettings = DualMotorGearAndDirection(motorA: dualMotorSettings.motorA,
                                                             motorB: MotorGearAndDirection(gear: gear, direction: direction))
      }
    case .both:
      if direction == leftMotorDirection && direction == rightMotorDirection {
        guard gear != leftMotorGear || gear != rightMotorGear else { return }
        updatedDualMotorSettings = DualMotorGearAndDirection(gearAB: gear)
      } else if gear == leftMotorGear && gear == rightMotorGear {
        updatedDualMotorSettings = DualMotorGearAndDirection(directionAB: direction)
      } else {
        updatedDualMotorSettings = DualMotorGearAndDirection(motorAB: MotorGearAndDirection(gear: gear, direction: direction))
      }
    }
    try dualMotor.writeValue(updatedDualMotorSettings)
    if let directionA = updatedDualMotorSettings.motorA.direction {
      dualMotorSettings.motorA.direction = directionA
    }
    if let directionB = updatedDualMotorSettings.motorB.direction {
      dualMotorSettings.motorB.direction = directionB
    }
    if let gearA = updatedDualMotorSettings.motorA.gear {
      dualMotorSettings.motorA.gear = gearA
    }
    if let gearB = updatedDualMotorSettings.motorB.gear {
      dualMotorSettings.motorA.gear = gearB
    }
  }

  public func stopMotor(motorSelection: MotorSelection) throws {
    let updatedDualMotorSettings: DualMotorGearAndDirection
    switch motorSelection {
    case .left:
      guard !isLeftMotorStopped else { return }
      updatedDualMotorSettings = DualMotorGearAndDirection(gearA: 0, gearB: rightMotorGear)
    case .right:
      guard !isRightMotorStopped else { return }
      updatedDualMotorSettings = DualMotorGearAndDirection(gearA: leftMotorGear, gearB: 0)
    case .both:
      guard !isLeftMotorStopped && !isRightMotorStopped else { return }
      updatedDualMotorSettings = DualMotorGearAndDirection(gearA: 0, gearB: 0)
    }
    try dualMotor.writeValue(updatedDualMotorSettings)
    dualMotorSettings.motorA.gear = updatedDualMotorSettings.motorA.gear
    dualMotorSettings.motorB.gear = updatedDualMotorSettings.motorB.gear
  }
}
