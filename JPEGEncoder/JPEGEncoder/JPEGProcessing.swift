//
//  JPEGProcessing.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 26/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Foundation
  
private func pi(_ multiplier: Double) -> Double {
  return cos((multiplier * Double.pi) / 16.0) / 2.0
}

private func dctMatrix() -> Matrix<Double> {
  var data = [Double](repeating: 0.0, count: 64)
  for i in 0 ..< 8 {
    for j in 0 ..< 8 {
      if i == 0 {
        data[i * 8 + j] = pi(4.0)
      } else {
        data[i * 8 + j] = pi(Double(j * 2 + 1) * Double(i));
      }
    }
  }
  return Matrix(data, rows: 8, cols: 8)
}

public func dct(_ source : Matrix<Double>) throws -> Matrix<Double> {
  let dct = dctMatrix()
  return try dct * source * transpose(dct)
}

public func reverseDct(_ source : Matrix<Double>) throws -> Matrix<Double> {
  let dct = dctMatrix()
  return try transpose(dct) * source * dct
}
