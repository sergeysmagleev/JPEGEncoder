//
//  JPEGEncoding.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 29/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Foundation
import CBTHuffmanEncoder

public func acCodeLength(_ source : Int) -> UInt8 {
  if (source == 0) {
    return 0
  }
  return UInt8(trunc(log2(Double(abs(source))))) + 1
}

public func produceAC(_ source : [Int]) -> [(HuffmanValue<Tuple<Int, Int>>, Int)] {
  var retVal : [(HuffmanValue<Tuple<Int, Int>>, Int)] = []
  var currentStreak = 0
  var currentIndex = 0
  let codeLengths = source.map { Int(acCodeLength($0)) }
  while currentIndex < codeLengths.count {
    if source[currentIndex] == 0 && currentStreak < 15 {
      currentStreak += 1
    } else {
      retVal.append((HuffmanValue.value(Tuple(a: currentStreak, b: codeLengths[currentIndex])), source[currentIndex]))
      currentStreak = 0
    }
    currentIndex += 1
  }
  retVal.append((HuffmanValue.terminatingValue, 0))
  return retVal
}

public func createChunks(_ source : Matrix<Matrix<Double>>) -> [QuantizedChunk] {
  var previousDCValue = 0
  var retVal : [QuantizedChunk] = []
  for item in source {
    let dcValue = Int(item[0, 0]) - previousDCValue
    previousDCValue = Int(item[0, 0])
    let dc = (HuffmanValue.value(Int(acCodeLength(dcValue))), dcValue)
    let acValues = item.zigzagRun()
    let ac = produceAC(acValues.map { Int($0)} )
    retVal.append(QuantizedChunk(dcValue: dc, acValues: ac))
  }
  return retVal
}

public func makeChunkEncoder(dcTable : HuffmanTable<Int>, acTable : HuffmanTable<Tuple<Int, Int>>)
  -> ([QuantizedChunk]) throws -> [UInt8] {
    return { source -> [UInt8] in
      #if DEBUG
        let beginTime = Date()
      #endif
      
      defer {
        #if DEBUG
          let executionTime = Date().timeIntervalSince(beginTime)
          print("\(#function) total execution time: \(executionTime)")
        #endif
      }
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
