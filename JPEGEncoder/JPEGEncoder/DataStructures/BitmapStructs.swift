//
//  BitmapStructs.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 10/10/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Accelerate

let yCbCrToRGBMatrix = [
    1.164, 0.0, 1.596,
    1.164, -0.392, -0.813,
    1.164, 2.017, 0.0
    ]

let rbgToYCbCrMatrix = [
    0.257, 0.504, 0.098,
    -0.148, -0.291, 0.439,
    0.439, -0.368, -0.071
    ]

let offsetMatrix = [16.0, 128.0, 128.0]

public struct FileHeader {
  var fileSize : Int32
  var reservedWord1 : Int16
  var reservedWord2 : Int16
  var dataOffset : Int32
}

public struct BitmapHeader {
  var size : Int32
  var width : Int32
  var height : Int32
  var bitPlanes : Int16
  var colorDepth : Int16
  var compression : Int32
  var imageSize : Int32
  var xppm : Int32
  var yppm : Int32
  var usedColors : Int32
  var importantColors : Int32
}

public struct RGBPixel : Equatable {
  var blue : UInt8
  var green : UInt8
  var red : UInt8
  var alpha : UInt8
}

public struct YCbCrPixel : Equatable{
  var luminance : Double
  var chromaBlue : Double
  var chromaRed : Double
}

public func emptyPixel() -> RGBPixel {
  return RGBPixel(blue: 0, green: 0, red: 0, alpha: 0)
}

public func ==(lhs : RGBPixel, rhs : RGBPixel) -> Bool {
  return lhs.red == rhs.red &&
    lhs.green == rhs.green &&
    lhs.blue == rhs.blue &&
    lhs.alpha == rhs.alpha
}

public func ==(lhs : YCbCrPixel, rhs : YCbCrPixel) -> Bool {
  return lhs.luminance == rhs.luminance &&
    lhs.chromaBlue == rhs.chromaBlue &&
    lhs.chromaRed == rhs.chromaRed
}

public func rgbToYCbCr(pixel : RGBPixel) -> YCbCrPixel {
  let rgbMatrix = [Double(pixel.red),
                   Double(pixel.green),
                   Double(pixel.blue)]
  var retVal = [Double](repeating: 0.0, count: 3)
  vDSP_mmulD(rbgToYCbCrMatrix, 1, rgbMatrix, 1, &retVal, 1, 3, 1, 3)
  vDSP_vaddD(offsetMatrix, 1, retVal, 1, &retVal, 1, 3)
  return YCbCrPixel(luminance: retVal[0],
                    chromaBlue: retVal[1],
                    chromaRed: retVal[2])
}

public func yCbCrToRGB(pixel : YCbCrPixel) -> RGBPixel {
  let yCbCrMatrix = [pixel.luminance, pixel.chromaBlue, pixel.chromaRed]
  var retVal = [Double](repeating: 0.0, count: 3)
  vDSP_vsubD(offsetMatrix, 1, yCbCrMatrix, 1, &retVal, 1, 3)
  vDSP_mmulD(yCbCrToRGBMatrix, 1, retVal, 1, &retVal, 1, 3, 1, 3)
  return RGBPixel(blue: UInt8(boundaryValue(value: retVal[2], minimum: 0.0, maximum: 255.0)),
                  green: UInt8(boundaryValue(value: retVal[1], minimum: 0.0, maximum: 255.0)),
                  red: UInt8(boundaryValue(value: retVal[0], minimum: 0.0, maximum: 255.0)),
                  alpha: 0)
}

func boundaryValue<T : Comparable>(value : T, minimum : T, maximum : T) -> T {
  return max(minimum, min(value, maximum))
}
