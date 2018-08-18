//
//  JPEGEncoderTests.swift
//  JPEGEncoderTests
//
//  Created by Sergei Smagleev on 23/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import XCTest
import CBTHuffmanEncoder
@testable import JPEGEncoder

class JPEGEncoderTests: XCTestCase {
    
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testSum() {
    let matrixA = Matrix([[1.0, 2.0, 3.0],
                          [5.0, 6.0, 7.0]])
    let matrixB = Matrix([[3.0, 4.0, 5.0],
                          [7.0, 8.0, 9.0]])
    XCTAssert(try matrixA + matrixB == Matrix([[4.0, 6.0, 8.0],
                                               [12.0, 14.0, 16.0]]), "sum failed")
  }
  
  func testMultiply() {
    let matrixA = Matrix([[3.0, 4.0],
                          [5.0, 7.0],
                          [8.0, 9.0]])
    let matrixB = Matrix([[1.0, 2.0, 3.0],
                          [5.0, 6.0, 7.0]])
    XCTAssert(try matrixA * matrixB == Matrix([[23.0, 30.0, 37.0],
                                               [40.0, 52.0, 64.0],
                                               [53.0, 70.0, 87.0]]), "multiply failed")
  }
  
  func testQuantization() {
    let matrix : Matrix<Double> = Matrix([[94.5, 25.3],
                         [24.4, 1.5]])
    let quantization : Matrix<Double> = Matrix([[5, 4],
                                                [4, 2]])
    let quantized : Matrix<Int>
    let dequantized : Matrix<Double>
    do {
      quantized = try quantize(matrix, by: quantization).matrixMap { Int($0) }
      dequantized = try dequantize(quantized.matrixMap { Double($0) }, by: quantization)
    } catch {
      XCTFail("quantization failed")
      return
    }
    XCTAssert(quantized == Matrix([[18, 6],
                                   [6, 0]]), "quantization failed")
    XCTAssert(dequantized == Matrix([[90, 24],
                                     [24, 0]]), "dequantization failed")
  }
  
  func testFloatingPointEquality() {
    let matrixA = Matrix([[1.112, 1.112],
                          [-0.125, 0.1]])
    let matrixB = Matrix([[1.113, 1.111],
                          [-0.125, 0.102]])
    let matrixC = Matrix([[1.123, 1.111],
                          [-2, 0.102]])
    let matrixD = Matrix([[1.112, 1.112],
                          [-0.125, 0.1]])
    XCTAssert(matrixA.equalTo(matrixB, precision: 0.01))
    XCTAssert(!matrixC.equalTo(matrixD, precision: 0.01))
  }
  
  func testDCT() {
    let matrixA : Matrix<Double> = Matrix([[51, 51, 50, 51, 51, 50, 51, 50],
                                           [52, 52, 50, 50, 50, 51, 52, 51],
                                           [51, 51, 51, 50, 50, 52, 51, 52],
                                           [50, 51, 52, 50, 51, 52, 50, 52],
                                           [50, 50, 52, 52, 50, 51, 52, 50],
                                           [52, 52, 51, 50, 50, 50, 50, 51],
                                           [50, 52, 51, 50, 51, 50, 52, 52],
                                           [52, 51, 51, 51, 50, 50, 50, 51]])
    let matrixB : Matrix<Double> = Matrix([[407,    0.352,  1.904,    -0.661, -1,     -0.229, 0.023,  -0.11],
                                           [0.058,  -0.654, -0.116,   1.350,  -0.335, 0.162,  -0.173, -0.383],
                                           [-0.518, 1.019,  1,        0.689,  1.171,  0.115,  -1.707, 0.105],
                                           [-0.592, 0.818,  -0.598,   -0.055, 0.102,  0.711,  -1.529, 0.470],
                                           [-0.5,   0.179,  -2.174,   -0.425, 0.5,    0.956,  0.630,  0.005],
                                           [0.118,  -1.074, -0.352,   -0.599, -0.020, -1.902, 0.109,  0.568],
                                           [-0.597, 1.190,  0.293,    0.254,  0.868,  -0.108, 1,      -0.470],
                                           [0.086,  -1.194, -1.006,   -0.412, -0.502, 1.454,  -0.603, 0.111]])
    XCTAssert(matrixB.equalTo(try dct(matrixA), precision: 0.01))
  }
  
  func testReadingTable() {
    let input = ["EOF\t00", "1\t010", "2\t011"]
    let table : HuffmanTreeNode<Int>
    do {
      table = try readTable(input)
    } catch {
      XCTFail("failed to read huffmanTable")
      return
    }
    XCTAssert(try table.getLeftNode().getLeftNode().value.isTerminal())
    XCTAssert(try table.getLeftNode().getRightNode().getLeftNode().value.unwrap() == 1)
    XCTAssert(try table.getLeftNode().getRightNode().getRightNode().value.unwrap() == 2)
  }
  
  func testZigzagRun() {
    let input : Matrix<Double> = Matrix([[3, 2, 3],
                                      [1, 0, 4]])
    XCTAssert(input.zigzagRun() == [2, 1, 0, 3, 4])
    
    let input2 : Matrix<Double> = Matrix([[3, 2, 3, 5, 3],
                                       [1, 0, 4, 2, 0],
                                       [3, 0, 4, 2, 0],
                                       [1, 2, 0, 0, 0],
                                       [1, 0, 0, 0, 0]])
    XCTAssert(input2.zigzagRun() == [2, 1, 3, 0, 3, 5, 4, 0, 1, 1, 2, 4, 2, 3, 0, 2])
    
    let intZigzag = produceAC(input2.zigzagRun().map { Int($0) })
    let rle = [(HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
               (HuffmanValue.value(Tuple(a: 0, b: 1)), 1),
               (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
               (HuffmanValue.value(Tuple(a: 1, b: 2)), 3),
               (HuffmanValue.value(Tuple(a: 0, b: 3)), 5),
               (HuffmanValue.value(Tuple(a: 0, b: 3)), 4),
               (HuffmanValue.value(Tuple(a: 1, b: 1)), 1),
               (HuffmanValue.value(Tuple(a: 0, b: 1)), 1),
               (HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
               (HuffmanValue.value(Tuple(a: 0, b: 3)), 4),
               (HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
               (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
               (HuffmanValue.value(Tuple(a: 1, b: 2)), 2),
               (HuffmanValue.terminatingValue, 0)]
    let comparator : (((HuffmanValue<Tuple<Int, Int>>, Int), (HuffmanValue<Tuple<Int, Int>>, Int)) -> Bool) = { left, right in
      return left.0 == right.0 && left.1 == right.1
    }
    for (a, b) in zip(intZigzag, rle) {
      XCTAssert(comparator(a, b))
    }
  }
  
  func testCreateChunks() {
    let matrix1 : Matrix<Double> = Matrix([[200, 2, 3, 4],
                                        [3, 2, 3, 0],
                                        [2, 2, 0, 0],
                                        [1, 0, 0, 0]])
    let matrix2 : Matrix<Double> = Matrix([[208, 2, 3, 4],
                                        [3, 2, 3, 0],
                                        [2, 2, 0, 0],
                                        [1, 0, 0, 0]])
    let chunk1 = QuantizedChunk(dcValue: (HuffmanValue.value(8), 200), acValues: [(HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                  (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
                                                                                  (HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                  (HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                  (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
                                                                                  (HuffmanValue.value(Tuple(a: 0, b: 3)), 4),
                                                                                  (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
                                                                                  (HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                  (HuffmanValue.value(Tuple(a: 0, b: 1)), 1),
                                                                                  (HuffmanValue.terminatingValue, 0)])
    let chunk2 = QuantizedChunk(dcValue: (HuffmanValue.value(4), 8), acValues: [(HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
                                                                                (HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                (HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
                                                                                (HuffmanValue.value(Tuple(a: 0, b: 3)), 4),
                                                                                (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
                                                                                (HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                (HuffmanValue.value(Tuple(a: 0, b: 1)), 1),
                                                                                (HuffmanValue.terminatingValue, 0)])
    let input = Matrix([[matrix1, matrix2]])
    let output = [chunk1, chunk2]
    XCTAssertEqual(createChunks(input), output)
  }
  
  func testEncode() {
    guard let dcPath = Bundle.main.path(forResource: "dc_coefficients", ofType: "txt"),
      let acPath = Bundle.main.path(forResource: "ac_coefficients", ofType: "txt") else {
        XCTFail("Table files missing")
        return
    }
    let dcTable : HuffmanTable<Int>
    let acTable : HuffmanTable<Tuple<Int, Int>>
    do {
      dcTable = try createEncodedCharacters(try readTableFromFile(dcPath))
      acTable = try createEncodedCharacters(try readTableFromFile(acPath))
    } catch {
      XCTFail("Failed to create tables")
      return
    }
    
    let input : [QuantizedChunk] = [QuantizedChunk(dcValue: (HuffmanValue.value(2), 2), acValues: [(HuffmanValue.value(Tuple(a: 0, b: 2)), 2),
                                                                                                   (HuffmanValue.value(Tuple(a: 0, b: 2)), 3),
                                                                                                   (HuffmanValue.value(Tuple(a: 1, b: 2)), 2),
                                                                                                   (HuffmanValue.terminatingValue, 0)]),
                                    QuantizedChunk(dcValue: (HuffmanValue.terminatingValue, 0), acValues: [])]
    let output : [UInt8] = [0b01010110, 0b01111101, 0b01011011, 0b11111111, 0b00000001]
    let encoder = makeChunkEncoder(dcTable: dcTable, acTable: acTable)
    XCTAssertEqual(try encoder(input), output)
  }
  
  func testMatrixMap() {
    let input : Matrix<Double> = Matrix([[3, 2, 3],
                                         [1, 0, 4]])
    let output : Matrix<Double> = Matrix([[5, 4, 5],
                                          [3, 2, 6]])
    XCTAssertEqual(output, input.matrixMap(processClosure: { value -> Double in
      return value + 2
    }))
  }
  
  func testDivideToChunks() {
    let input : Matrix<Double> = Matrix([[3, 2, 3],
                                         [1, 0, 4],
                                         [6, 7, 9]])
    let matrix1 : Matrix<Double> = Matrix([[3, 2],
                                           [1, 0]])
    let matrix2 : Matrix<Double> = Matrix([[3, 0],
                                           [4, 0]])
    let matrix3 : Matrix<Double> = Matrix([[6, 7],
                                           [0, 0]])
    let matrix4 : Matrix<Double> = Matrix([[9, 0],
                                           [0, 0]])
    let output : Matrix<Matrix<Double>> = Matrix([[matrix1, matrix2],
                                                  [matrix3, matrix4]])
    let processed = divideMatrixToChunks(input, height: 2, width: 2)
    XCTAssertEqual(output, processed)
  }
    
}
