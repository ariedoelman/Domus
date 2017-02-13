//
//  MotorModel.swift
//  Domus
//
//  Created by Arie Doelman on 11-02-17.
//
//

import Foundation
import GrovePiIO

public final class MotorModel {
  private let dualMotor: MotorDriveDestination
  private var dualMotorSettings: DualMotorGearAndDirection

  public var leftMotorDirection: MotorDirection { return dualMotorSettings.motorA.direction! }
  public var leftMotorGear: Range256 { return dualMotorSettings.motorA.gear! }
  public var isLeftMotorStopped: Bool { return leftMotorGear == 0 }
  public var rightMotorDirection: MotorDirection { return dualMotorSettings.motorB.direction! }
  public var rightMotorGear: Range256 { return dualMotorSettings.motorB.gear! }
  public var isRightMotorStopped: Bool { return rightMotorGear == 0 }

  public init(_ bus: GrovePiBus) throws {
    dualMotor = try bus.connectDualMotorDrive(portLabel: .I2C_2)
    dualMotorSettings = DualMotorGearAndDirection(motorAB: MotorGearAndDirection(gear: 0, direction: .none))
  }

  public func updateDirectionAndSpeed(leftGear: Range256, leftDirection: MotorDirection,
                                      rightGear: Range256, rightDirection: MotorDirection) throws {
    let updatedDualMotorSettings: DualMotorGearAndDirection
      if leftDirection == leftMotorDirection && rightDirection == rightMotorDirection {
        guard leftGear != leftMotorGear || rightGear != rightMotorGear else {
          return
        }
        updatedDualMotorSettings = DualMotorGearAndDirection(gearA: leftGear, gearB: rightGear)
      } else if leftGear == leftMotorGear && rightGear == rightMotorGear {
        updatedDualMotorSettings = DualMotorGearAndDirection(directionA: leftDirection, directionB: rightDirection)
      } else {
        updatedDualMotorSettings = DualMotorGearAndDirection(motorA: MotorGearAndDirection(gear: leftGear, direction: leftDirection),
                                                             motorB: MotorGearAndDirection(gear: rightGear, direction: rightDirection))
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
      dualMotorSettings.motorB.gear = gearB
    }
  }

  public func stopMotors() throws {
    guard !isLeftMotorStopped && !isRightMotorStopped else { return }
    let updatedDualMotorSettings = DualMotorGearAndDirection(gearA: 0, gearB: 0)
    try dualMotor.writeValue(updatedDualMotorSettings)
    dualMotorSettings.motorA.gear = updatedDualMotorSettings.motorA.gear
    dualMotorSettings.motorB.gear = updatedDualMotorSettings.motorB.gear
  }
}
