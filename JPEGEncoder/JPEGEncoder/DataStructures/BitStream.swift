//
//  BitStream.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 13/10/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import CBTHuffmanEncoder

public class BitStream {
  
  private var currentByte : UInt8 = 0
  private var currentShift : UInt8 = 0
  private var currentIndex : Int = 0
  private var byteArray : [UInt8]
  
  public required init(bytes: [UInt8]) {
    byteArray = bytes
  }
  
  public convenience init() {
    self.init(bytes: [])
  }
  
  public func readData<T>(withTree tree: HuffmanTreeNode<T>) throws -> HuffmanValue<T> {
    var currentNode = tree
    while !currentNode.isLeaf() {
      let readByte = byteArray[currentIndex] & (1 << currentShift)
      if readByte > 0 {
        currentNode = try currentNode.getRightNode()
      } else {
        currentNode = try currentNode.getLeftNode()
      }
      currentShift += 1
      if currentShift > 7 {
        currentShift = 0
        currentIndex += 1
      }
    }
    return currentNode.value
  }
  
  public func readAmountOfBytes(_ amount: UInt8) -> Int {
    if (amount == 0) {
      return 0
    }
    var readByte = 0
    var localShift = 0
    var lastBit = 0
    for _ in 0..<amount {
      lastBit = Int((byteArray[currentIndex] & (1 << currentShift)) >> currentShift) << localShift
      readByte += lastBit
      localShift += 1
      currentShift += 1
      if currentShift > 7 {
        currentShift = 0
        currentIndex += 1
      }
    }
    if lastBit == 0 {
      readByte = ~BitStream.makeMaskWithAmountOfBits(amount) | (readByte + 1)
    }
    return readByte
  }
  
  private static func makeMaskWithAmountOfBits(_ amount: UInt8) -> Int {
    var retVal : Int = 0
    for i in 0..<Int(amount) {
      retVal += (1 << i)
    }
    return retVal
  }
  
}
