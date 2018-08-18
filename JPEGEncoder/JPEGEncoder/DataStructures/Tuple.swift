//
//  Tuple.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 28/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import CBTHuffmanEncoder

public struct Tuple<T : Equatable, U : Equatable> : Equatable, Parseable where T : Parseable, U : Parseable {
  let a : T
  let b : U
  
  public static func parseFromString(stringCode: String) throws -> HuffmanValue<Tuple<T, U>> {
    if (stringCode == "EOF") {
      return HuffmanValue.terminatingValue
    }
    let components = stringCode.components(separatedBy: ",")
    guard components.count == 2 else {
      throw ParseError.IncorrectFormat
    }
    let a = try T.parseFromString(stringCode: components[0])
    let b = try U.parseFromString(stringCode: components[1])
    switch (a, b) {
    case (.value(let aValue), .value(let bValue)):
      return HuffmanValue.value(Tuple(a: aValue,
                                      b: bValue))
    default:
      throw ParseError.IncorrectFormat
    }
  }
  
  static public func fromRaw(_ raw : (T, U)) -> Tuple {
    return Tuple(a: raw.0, b: raw.1)
  }
  
  public func raw() -> (T, U) {
    return (a, b)
  }
}

public func ==<T, U>(left : Tuple<T, U>, right : Tuple<T, U>) -> Bool {
  return left.a == right.a && left.b == right.b
}
