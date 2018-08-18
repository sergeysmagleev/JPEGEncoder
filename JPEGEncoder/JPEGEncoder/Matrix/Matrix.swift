//
//  Matrix.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 23/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Accelerate

public enum MatrixErrors : Error {
  case sizesDontMatch
}

public class Matrix<T : Equatable> : Sequence, IteratorProtocol, Equatable {
  
  internal let data : [T]
  private let heightVar : Int
  private let widthVar : Int
  private var iteratorIndex = 0
  
  convenience public init(_ data : [[T]]) {
    let flatData = data.flatMap { $0 }
    let height = data.count
    let width = data.first?.count ?? 0
    self.init(flatData, rows: height, cols: width)
  }
  
  required public init(_ flatData : [T], rows : Int, cols : Int) {
    assert(flatData.count == rows * cols && rows > 0 || cols > 0, "Incorrect matrix size")
    heightVar = rows
    widthVar = cols
    self.data = flatData
  }
  
  public var count : Int {
    get {
      return data.count
    }
  }
  
  public var height : Int {
    get {
      return heightVar
    }
  }
  
  public var width : Int {
    get {
      return widthVar
    }
  }
  
  public subscript(i : Int, j : Int) -> T {
    return data[i * widthVar + j]
  }
  
  public func next() -> T? {
    guard iteratorIndex < data.count else {
      iteratorIndex = 0
      return nil
    }
    defer { iteratorIndex += 1 }
    return data[iteratorIndex]
  }
  
}

extension Matrix where T : FloatingPoint {
  
  public func equalTo(_ matrix: Matrix<T>, precision: T) -> Bool {
    for (leftElement, rightElement) in zip(self, matrix) {
      if (abs(leftElement - rightElement) > precision) {
        return false
      }
    }
    return true
  }
  
}

public func transpose(_ matrix : Matrix<Double>) -> Matrix<Double> {
  var retVal = [Double](repeating: 0.0, count: matrix.height * matrix.width)
    vDSP_mtransD(matrix.data, 1, &retVal, 1, UInt(matrix.width), UInt(matrix.height))
    return Matrix(retVal, rows: matrix.width, cols: matrix.height)
}

extension Matrix {
  
  public func matrixMap<U>(processClosure : (T) throws -> U) rethrows -> Matrix<U> {
    let tempArray = try self.map { item -> U in return try processClosure(item) }
    return Matrix<U>(tempArray, rows: height, cols: width)
  }
  
}

public func ==<T : Equatable> (left : Matrix<T>, right : Matrix<T>) -> Bool {
  if (left.height != right.height || left.width != right.width) {
    return false
  }
  for (leftElement, rightElement) in zip(left, right) {
    if (leftElement != rightElement) {
      return false
    }
  }
  return true
}

public func ==<T : Equatable> (left : Matrix<T>, right : Matrix<T>) -> Bool where T : FloatingPoint {
  if (left.height != right.height || left.width != right.width) {
    return false
  }
  let precision = T(1) / T(100)
  for (leftElement, rightElement) in zip(left, right) {
    if (abs(leftElement - rightElement) > precision) {
      return false
    }
  }
  return true
}

func *(left : Matrix<Double>, right : Matrix<Double>) throws -> Matrix<Double> {
  guard left.width == right.height else {
    throw MatrixErrors.sizesDontMatch
  }
  let count = left.height * right.width
  var retVal = [Double](repeating: 0.0, count: count)
  vDSP_mmulD(left.data, 1, right.data, 1, &retVal, 1, UInt(left.height), UInt(right.width), UInt(left.width))
  return Matrix(retVal, rows: left.height, cols: right.width)
}

func +(left : Matrix<Double>, right : Matrix<Double>) throws -> Matrix<Double> {
  guard left.height == right.height && left.width == right.width else {
    throw MatrixErrors.sizesDontMatch
  }
  var retVal = [Double](repeating: 0.0, count: left.count)
  vDSP_vaddD(left.data, 1, right.data, 1, &retVal, 1, vDSP_Length(left.count))
  return Matrix(retVal, rows: left.height, cols: left.width)
}

func -(left : Matrix<Double>, right : Matrix<Double>) throws -> Matrix<Double> {
  guard left.height == right.height && left.width == right.width else {
    throw MatrixErrors.sizesDontMatch
  }
  var retVal = [Double](repeating: 0.0, count: left.count)
  vDSP_vsubD(right.data, 1, left.data, 1, &retVal, 1, vDSP_Length(left.count))
  return Matrix(retVal, rows: left.height, cols: left.width)
}

public func quantize(_ left: Matrix<Double>, by right: Matrix<Double>) throws -> Matrix<Double> {
  guard left.height == right.height && left.width == right.width else {
    throw MatrixErrors.sizesDontMatch
  }
  var retVal = [Double](repeating: 0.0, count: left.count)
  vDSP_vdivD(right.data, 1, left.data, 1, &retVal, 1, UInt(left.count))
  return Matrix(retVal, rows: left.width, cols: left.height)
}

public func dequantize(_ left: Matrix<Double>, by right: Matrix<Double>) throws -> Matrix<Double> {
  guard left.height == right.height && left.width == right.width else {
    throw MatrixErrors.sizesDontMatch
  }
  var retVal = [Double](repeating: 0.0, count: left.count)
  vDSP_vmulD(left.data, 1, right.data, 1, &retVal, 1, UInt(left.count))
  return Matrix(retVal, rows: left.width, cols: left.height)
}
