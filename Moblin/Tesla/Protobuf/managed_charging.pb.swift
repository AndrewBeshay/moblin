// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: managed_charging.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

/// The reasons why the site controller may recommend no charge.
/// The site controller will only return the highest priority reason to the vehicle.
enum ManagedCharging_ChargeOnSolarNoChargeReason: SwiftProtobuf.Enum, Swift.CaseIterable {
  typealias RawValue = Int
  case invalid // = 0

  /// The Powerwall is being prioritized over the vehicle to charge.
  case powerwallChargePriority // = 1

  /// There is not enough solar for the vehicle to charge effectively.
  case insufficientSolar // = 2

  /// The site controller is prioritizing export to the grid. This can
  /// happen when the site controller is in autonomous mode and it is
  /// most economical to export excess solar to the grid, or during a
  /// virtual power plant event.
  case gridExportPriority // = 3

  /// Another vehicle is charging on solar at this location and has priority.
  case alternateVehicleChargePriority // = 4
  case UNRECOGNIZED(Int)

  init() {
    self = .invalid
  }

  init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .invalid
    case 1: self = .powerwallChargePriority
    case 2: self = .insufficientSolar
    case 3: self = .gridExportPriority
    case 4: self = .alternateVehicleChargePriority
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  var rawValue: Int {
    switch self {
    case .invalid: return 0
    case .powerwallChargePriority: return 1
    case .insufficientSolar: return 2
    case .gridExportPriority: return 3
    case .alternateVehicleChargePriority: return 4
    case .UNRECOGNIZED(let i): return i
    }
  }

  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static let allCases: [ManagedCharging_ChargeOnSolarNoChargeReason] = [
    .invalid,
    .powerwallChargePriority,
    .insufficientSolar,
    .gridExportPriority,
    .alternateVehicleChargePriority,
  ]

}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension ManagedCharging_ChargeOnSolarNoChargeReason: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "CHARGE_ON_SOLAR_NO_CHARGE_REASON_INVALID"),
    1: .same(proto: "CHARGE_ON_SOLAR_NO_CHARGE_REASON_POWERWALL_CHARGE_PRIORITY"),
    2: .same(proto: "CHARGE_ON_SOLAR_NO_CHARGE_REASON_INSUFFICIENT_SOLAR"),
    3: .same(proto: "CHARGE_ON_SOLAR_NO_CHARGE_REASON_GRID_EXPORT_PRIORITY"),
    4: .same(proto: "CHARGE_ON_SOLAR_NO_CHARGE_REASON_ALTERNATE_VEHICLE_CHARGE_PRIORITY"),
  ]
}
