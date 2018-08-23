//
//  BitmapConverter.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 12/10/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Foundation
import CBTHuffmanEncoder

let lumaQuantizationMatrix = Matrix<Double>([
    16, 11, 10, 16, 24, 40, 51, 61,
    12, 12, 14, 19, 26, 58, 60, 55,
    14, 13, 16, 24, 40, 57, 69, 56,
    14, 17, 22, 29, 51, 87, 80, 62,
    18, 22, 37, 56, 68, 109, 103, 77,
    24, 35, 55, 64, 81, 104, 113, 92,
    49, 64, 78, 87, 103, 121, 120, 101,
    72, 92, 95, 98, 112, 100, 103, 99
    ], rows: 8, cols: 8)

let chromaQuantizationMatrix = Matrix<Double>([
    17, 18, 24, 47, 99, 99, 99, 99,
    18, 21, 26, 66, 99, 99, 99, 99,
    24, 26, 56, 99, 99, 99, 99, 99,
    47, 66, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99
  ], rows: 8, cols: 8)

public func divideMatrixToChunks(_ matrix : Matrix<Double>, height: Int = 8, width: Int = 8) -> Matrix<Matrix<Double>> {
  let verticalCount = Int(ceil(Double(matrix.height) / Double(height)))
  let horizontalCount = Int(ceil(Double(matrix.width) / Double(width)))
  var retVal : [Matrix<Double>] = []
  for i in 0 ..< verticalCount {
    for j in 0 ..< horizontalCount {
      var segment : [Double] = []
      for k : Int in 0 ..< height {
        for l : Int in 0 ..< width {
          if i * height + k >= matrix.height {
            segment.append(0.0)
          } else if j * width + l >= matrix.width {
            segment.append(0.0)
          } else {
            segment.append(matrix[i * height + k, j * width + l])
          }
        }
      }
      retVal.append(Matrix(segment, rows: height, cols: width))
    }
  }
  return Matrix(retVal, rows: verticalCount, cols: horizontalCount)
}

public func restoreMatrixFromChunks(_ chunks: Matrix<Matrix<Double>>) -> Matrix<Double> {
  var retVal = [Double](repeating: 0.0, count: chunks.count * 64)
  for i in 0 ..< chunks.height {
    for j in 0 ..< chunks.width {
      for k : Int in 0..<8 {
        for l : Int in 0..<8 {
          retVal[(i * 8 + k) * chunks.width * 8 + (j * 8 + l)] = chunks[i, j][k, l]
        }
      }
    }
  }
  return Matrix(retVal, rows: chunks.height * 8, cols: chunks.width * 8)
}

public func compressRGBData(_ matrix : Matrix<RGBPixel>) throws -> [ComponentsChunk] {
  #if DEBUG
    let beginTime = Date()
  #endif
  
  defer {
    #if DEBUG
      let executionTime = Date().timeIntervalSince(beginTime)
      print("\(#function) total execution time: \(executionTime)")
    #endif
  }
  let yCbCrMatrix = matrix.matrixMap { pixel -> YCbCrPixel in rgbToYCbCr(pixel: pixel) }
  
  let lumaMatrix = yCbCrMatrix.matrixMap { pixel -> Double in pixel.luminance }
  let chromaBlueMatrix = yCbCrMatrix.matrixMap { pixel -> Double in pixel.chromaBlue }
  let chromaRedMatrix = yCbCrMatrix.matrixMap { pixel -> Double in pixel.chromaRed }
  
  let lumaChunks = divideMatrixToChunks(lumaMatrix)
  let chromaBlueChunks = divideMatrixToChunks(chromaBlueMatrix)
  let chromaRedChunks = divideMatrixToChunks(chromaRedMatrix)
  
  let lumaQuantized = try lumaChunks.matrixMap { chunk -> Matrix<Double> in
    try quantize(try dct(chunk), by: lumaQuantizationMatrix)
  }
  let chromaBlueQuantized = try chromaBlueChunks.matrixMap { chunk -> Matrix<Double> in
    try quantize(try dct(chunk), by: chromaQuantizationMatrix)
  }
  let chromaRedQuantized = try chromaRedChunks.matrixMap { chunk -> Matrix<Double> in
    try quantize(try dct(chunk), by: chromaQuantizationMatrix)
  }
  
  let lumaQuantizedChunks = createChunks(lumaQuantized)
  let chromaBlueQuantizedChunks = createChunks(chromaBlueQuantized)
  let chromaRedQuantizedChunks = createChunks(chromaRedQuantized)
  
  let componentChunks = zip(lumaQuantizedChunks, zip(chromaBlueQuantizedChunks, chromaRedQuantizedChunks))
    .map { luma, chroma -> ComponentsChunk in
      let chromaBlue = chroma.0
      let chromaRed = chroma.1
      return ComponentsChunk(lumaChunk: luma, chromaBlueChunk: chromaBlue, chromaRedChunk: chromaRed)
  }
  
  return componentChunks
}

public func encodeChunks(_ chunks : [ComponentsChunk], rows: Int, cols: Int) throws -> [UInt8] {
  #if DEBUG
    let beginTime = Date()
  #endif
  
  defer {
    #if DEBUG
      let executionTime = Date().timeIntervalSince(beginTime)
      print("\(#function) total execution time: \(executionTime)")
    #endif
  }
  guard let dcPath = Bundle.main.path(forResource: "dc_coefficients", ofType: "txt"),
    let acPath = Bundle.main.path(forResource: "ac_coefficients", ofType: "txt") else {
      return []//must throw
  }
  let dcTable : HuffmanTable<Int> = try createEncodedCharacters(try readTableFromFile(dcPath))
  let acTable : HuffmanTable<Tuple<Int, Int>> = try createEncodedCharacters(try readTableFromFile(acPath))
  let encoder = makeChunkEncoder(dcTable: dcTable, acTable: acTable)
  let allChunks = chunks.map { [$0.lumaChunk, $0.chromaBlueChunk, $0.chromaRedChunk] }.flatMap { $0 }
  return try [UInt8(rows), UInt8(cols)] + encoder(allChunks)
}

public func uncompressRGBData(_ chunks: [QuantizedChunk], rows: Int, cols: Int) throws -> Matrix<RGBPixel> {
  #if DEBUG
    let beginTime = Date()
  #endif
  
  defer {
    #if DEBUG
      let executionTime = Date().timeIntervalSince(beginTime)
      print("\(#function) total execution time: \(executionTime)")
    #endif
  }
  var lumaQuantizedChunks : [QuantizedChunk] = []
  var chromaBlueQuantizedChunks : [QuantizedChunk] = []
  var chromaRedQuantizedChunks : [QuantizedChunk] = []
  
  for i in 0..<chunks.count / 3 {
    lumaQuantizedChunks.append(chunks[i * 3])
    chromaBlueQuantizedChunks.append(chunks[i * 3 + 1])
    chromaRedQuantizedChunks.append(chunks[i * 3 + 2])
  }
  
  let lumaQuantized = matricesFromChunks(source: lumaQuantizedChunks, rows: rows, cols: cols)
  let chromaBlueQuantized = matricesFromChunks(source: chromaBlueQuantizedChunks, rows: rows, cols: cols)
  let chromaRedQuantized = matricesFromChunks(source: chromaRedQuantizedChunks, rows: rows, cols: cols)
  
  let lumaDequantized = try lumaQuantized.matrixMap { chunk -> Matrix<Double> in
    try reverseDct(try dequantize(chunk, by: lumaQuantizationMatrix))
  }
  let chromaBlueDequantized = try chromaBlueQuantized.matrixMap { chunk -> Matrix<Double> in
    try reverseDct(try dequantize(chunk, by: chromaQuantizationMatrix))
  }
  let chromaRedDequantized = try chromaRedQuantized.matrixMap { chunk -> Matrix<Double> in
    try reverseDct(try dequantize(chunk, by: chromaQuantizationMatrix))
  }
  
  let lumaMatrix = restoreMatrixFromChunks(lumaDequantized)
  let chromaBlueMatrix = restoreMatrixFromChunks(chromaBlueDequantized)
  let chromaRedMatrix = restoreMatrixFromChunks(chromaRedDequantized)
  
  var pixelMap : [YCbCrPixel] = []
  for i in 0..<lumaMatrix.height {
    for j in 0..<lumaMatrix.width {
      let luma = lumaMatrix[i, j]
      let chromaBlue = chromaBlueMatrix[i, j]
      let chromaRed = chromaRedMatrix[i, j]
      pixelMap.append(YCbCrPixel(luminance: luma, chromaBlue: chromaBlue, chromaRed: chromaRed))
    }
  }
  
  let rgbPixels = pixelMap.map { item in yCbCrToRGB(pixel: item) }
  let rgbPixelMatrix = Matrix(rgbPixels, rows: lumaMatrix.height, cols: lumaMatrix.width)
  
  return rgbPixelMatrix
}

public func decodeChunks(_ binary: [UInt8]) throws -> [QuantizedChunk] {
  #if DEBUG
    let beginTime = Date()
  #endif
  
  defer {
    #if DEBUG
      let executionTime = Date().timeIntervalSince(beginTime)
      print("\(#function) total execution time: \(executionTime)")
    #endif
  }
  guard let dcPath = Bundle.main.path(forResource: "dc_coefficients", ofType: "txt"),
    let acPath = Bundle.main.path(forResource: "ac_coefficients", ofType: "txt") else {
      return []//must throw
  }
  let dcTable : HuffmanTreeNode<Int> = try readTableFromFile(dcPath)
  let acTable : HuffmanTreeNode<Tuple<Int, Int>> = try readTableFromFile(acPath)
  let bitStream = BitStream(bytes: binary)
  let rows = binary[0]
  let cols = binary[1]
  var retVal : [QuantizedChunk] = []
  _ = bitStream.readAmountOfBytes(UInt8(16))
  for _ in 0..<3 {
    for _ in 0..<rows {
      for _ in 0..<cols {
        let dcBitLength = try bitStream.readData(withTree: dcTable)
        if dcBitLength.isTerminal() {
          break
        }
        let dcDifference = bitStream.readAmountOfBytes(UInt8(try dcBitLength.forceUnwrap()))
        let dcValue = (dcBitLength, Int(dcDifference))
        var acValue : (HuffmanValue<Tuple<Int, Int>>, Int)
        var acArray : [(HuffmanValue<Tuple<Int, Int>>, Int)] = []
        while(true) {
          let acBitLength: HuffmanValue<Tuple<Int, Int>> = try bitStream.readData(withTree: acTable)
          if acBitLength.isTerminal() {
            break
          }
          let readAC = bitStream.readAmountOfBytes(UInt8(try acBitLength.forceUnwrap().b))
          acValue = (acBitLength, Int(readAC))
          acArray.append(acValue)
        }
        retVal.append(QuantizedChunk(dcValue: dcValue, acValues: acArray))
      }
    }
  }
  return retVal

}
