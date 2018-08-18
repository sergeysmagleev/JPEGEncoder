//
//  Parseable.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 28/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import CBTHuffmanEncoder

public enum ParseError : Error {
  case IncorrectFormat
}

public protocol Parseable {
  static func parseFromString(stringCode : String) throws -> HuffmanValue<Self>
}

extension Int : Parseable {
  public static func parseFromString(stringCode: String) throws -> HuffmanValue<Int> {
    if (stringCode == "EOF") {
      return HuffmanValue.terminatingValue
    }
    guard let value = Int(stringCode) else {
      throw ParseError.IncorrectFormat
    }
    return HuffmanValue.value(value)
  }
}
