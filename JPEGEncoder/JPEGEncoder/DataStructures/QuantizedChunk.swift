//
//  QuantizedChunk.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 27/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import CBTHuffmanEncoder

public struct QuantizedChunk : Equatable {
  let dcValue : (HuffmanValue<Int>, Int)
  let acValues : [(HuffmanValue<Tuple<Int, Int>>, Int)]
}

public struct ComponentsChunk {
  let lumaChunk : QuantizedChunk
  let chromaBlueChunk : QuantizedChunk
  let chromaRedChunk : QuantizedChunk
}

public func ==(lhs : QuantizedChunk, rhs : QuantizedChunk) -> Bool {
  let dcComparator : ((HuffmanValue<Int>, Int), (HuffmanValue<Int>, Int)) -> Bool = {
    (left, right) -> Bool in
    return left.0 == right.0 && left.1 == right.1
  }
  let acComparator : ((HuffmanValue<Tuple<Int, Int>>, Int), (HuffmanValue<Tuple<Int, Int>>, Int)) -> Bool = {
    (left, right) -> Bool in
    return left.0 == right.0 && left.1 == right.1
  }
  return dcComparator(lhs.dcValue, rhs.dcValue) && zip(lhs.acValues, rhs.acValues).reduce(true) {
    total, tuple -> Bool in
    return total && acComparator(tuple.0, tuple.1)
  }
}
