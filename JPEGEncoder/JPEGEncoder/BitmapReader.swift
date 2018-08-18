//
//  BitmapReader.swift
//  BitmapReader
//
//  Created by Sergei Smagleev on 08/10/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Cocoa
import Foundation

enum BitmanReaderErrors : Error {
  case FileNotFoundError
  case UnsupportedFormat
}

func fromByteArray<T>(value: [UInt8], _: T.Type) -> T {
  return value.withUnsafeBufferPointer {
    return UnsafeRawPointer($0.baseAddress!).load(as: T.self)
  }
}

func readBytes<T>(fileHandle: FileHandle, _ : T.Type) -> T {
  let size = MemoryLayout<T>.size
  var tempArray = [UInt8](repeating: 0, count: size)
  fileHandle.readData(ofLength: size).copyBytes(to: &tempArray, count: size)
  return fromByteArray(value: tempArray, T.self)
}

public func readBitmapFromFile(file: String) throws -> Matrix<RGBPixel> {
  
  #if DEBUG
    let beginTime = Date()
  #endif
  
  guard let fileHandle = FileHandle(forReadingAtPath: file) else {
    throw BitmanReaderErrors.FileNotFoundError
  }
  defer {
    fileHandle.closeFile()
    #if DEBUG
      let executionTime = Date().timeIntervalSince(beginTime)
      print("\(#function) total execution time: \(executionTime)")
    #endif
  }
  
  fileHandle.seek(toFileOffset: 0x02)
  let fileHeader = readBytes(fileHandle: fileHandle, FileHeader.self)
  let bitmapHeader = readBytes(fileHandle: fileHandle, BitmapHeader.self)

  let width = Int(bitmapHeader.width)
  let height = Int(abs(bitmapHeader.height))
  
  let bytesPerComponent : Int = Int(bitmapHeader.colorDepth / 8)
  let bytesInRow = Int32(bytesPerComponent) * bitmapHeader.width
  let paddingBytes = (4 - bytesInRow % 4) % 4
  var colorPoints = [RGBPixel](repeating: emptyPixel(), count: height * width)
  
  fileHandle.seek(toFileOffset: UInt64(fileHeader.dataOffset))
  var row = 0
  for i in 0..<height {
    row = bitmapHeader.height > 0 ? height - 1 - i : i
    for j in 0..<width {
      var pixel = emptyPixel()
      fileHandle.readData(ofLength: Int(bytesPerComponent)).copyBytes(to: &pixel.blue, count: Int(bytesPerComponent))
      colorPoints[width * row + j] = pixel
    }
    fileHandle.seek(toFileOffset: UInt64(paddingBytes) + fileHandle.offsetInFile)
  }
  return Matrix(colorPoints, rows: height, cols: width)
}

public func createViewFromBitmapData(bitmapData : Matrix<RGBPixel>) -> NSImage? {
  
  #if DEBUG
    let beginTime = Date()
  #endif
  
  defer {
    #if DEBUG
      let executionTime = Date().timeIntervalSince(beginTime)
      print("\(#function) total execution time: \(executionTime)")
    #endif
  }
  
  let width = Int(bitmapData.width)
  let height = Int(bitmapData.height)
  
  let area = Int(bitmapData.height * bitmapData.width)
  let componentsPerPixel = 4
  
  var pixelData : [UInt8] = [UInt8](repeating: 0, count: Int(area * componentsPerPixel))
  
  for i in 0 ..< area {
    let offset = i * componentsPerPixel
    pixelData[offset] = bitmapData[i / Int(bitmapData.width), i % Int(bitmapData.width)].red
    pixelData[offset + 1] = bitmapData[i / Int(bitmapData.width), i % Int(bitmapData.width)].green
    pixelData[offset + 2] = bitmapData[i / Int(bitmapData.width), i % Int(bitmapData.width)].blue
    pixelData[offset + 3] = 0
  }
  
  let bitsPerComponent = 8
  let bytesPerRow = (bitsPerComponent * Int(bitmapData.width) / 8) * componentsPerPixel;
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  guard let gtx = CGContext(data: &pixelData[0],
                      width: width,
                      height: height,
                      bitsPerComponent: bitsPerComponent,
                      bytesPerRow: bytesPerRow,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
                        return nil
  }
  guard let toCGImage = gtx.makeImage() else {
    return nil
  }
  return NSImage(cgImage: toCGImage, size: NSSize(width: CGFloat(width), height: CGFloat(height)))
}
