//
//  JPEGDecoding.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 13/10/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import CBTHuffmanEncoder

public func makeChunkDecoder(dcTable : HuffmanTable<Int>, acTable : HuffmanTable<Tuple<Int, Int>>)
  -> ([QuantizedChunk]) throws -> [UInt8] {
    return { source -> [UInt8] in
      var retVal : [EncodedEntity] = []
      
      for chunk in source {
        let encodedDCLength = try dcTable.codeForHuffmanValue(chunk.dcValue.0)
        retVal.append(encodedDCLength)
        if (chunk.dcValue.0.isTerminal()) {
          break
        }
        var normalizedDC = chunk.dcValue.1
        if (normalizedDC < 0) {
          normalizedDC = ~abs(normalizedDC)
        }
        guard let value = chunk.dcValue.0.unwrap() else {
          throw HuffmanTableErrors.MissingValue
        }
        let encodedDCValue = EncodedEntity(codeLength: UInt8(value), encodedValue: Int32(normalizedDC))
        retVal.append(encodedDCValue)
        for acValue in chunk.acValues {
          let encodedACLength = try acTable.codeForHuffmanValue(acValue.0)
          retVal.append(encodedACLength)
          if acValue.0.isTerminal() {
            break
          }
          guard let tuple = acValue.0.unwrap() else {
            throw HuffmanTableErrors.MissingValue
          }
          var normalizedAC = acValue.1
          if (normalizedAC < 0) {
            normalizedAC = ~abs(normalizedAC)
          }
          let encodedACValue = EncodedEntity(codeLength: UInt8(tuple.b),
                                             encodedValue: Int32(normalizedAC))
          retVal.append(encodedACValue)
        }
      }
      return saveEncodedDataToByteArray(retVal)
    }
}

public func matricesFromChunks(source : [QuantizedChunk], rows: Int, cols: Int) -> Matrix<Matrix<Double>> {
  var previousDCValue : Double = 0.0
  var retVal : [Matrix<Double>] = []
  var index = 0
  for _ in 0..<rows {
    for _ in 0..<cols {
      let dcValue = Double(source[index].dcValue.1) + previousDCValue
      let acValue = byteArrayFromRLE(source[index].acValues)
      var matrix = reverseZigzagRun(acValue.map { Double($0) })
      matrix[0] = dcValue
      previousDCValue = dcValue
      retVal.append(Matrix(matrix, rows: 8, cols: 8))
      index += 1
    }
  }
  return Matrix(retVal, rows: rows, cols: cols)
}

public func byteArrayFromRLE(_ source : [(HuffmanValue<Tuple<Int, Int>>, Int)]) -> [Int] {
  var retVal : [Int] = []
  for item in source {
    if item.0.isTerminal() {
      break
    }
    guard let value = item.0.unwrap() else {
      break
    }
    for _ in 0 ..< value.a {
      retVal.append(0)
    }
    retVal.append(item.1)
  }
  assert(retVal.count < 64, "byte sequence too long")
  return retVal
}
