//
//  HuffmanReader.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 27/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import CBTHuffmanEncoder
import Foundation

public func readLines(_ filename : String) throws -> [String] {
  let content = try String(contentsOfFile: filename, encoding: String.Encoding.utf8)
  return content.components(separatedBy: NSCharacterSet.newlines)
}

public func readTable<T : Parseable>(_ lines: [String]) throws -> HuffmanTreeNode<T> {
  let encodedCharacters = try lines.map { line -> EncodedValue<T> in
    let components = line.components(separatedBy: "\t")
    let value = try T.parseFromString(stringCode: components[0])
    let stringRepresentation = components[1]
    let encodedCharacter = EncodedValue(value: value, stringRepresentation: stringRepresentation)
    return encodedCharacter
  }
  return createTreeFromTable(encodedCharacters)
}

public func readTableFromFile<T : Parseable>(_ path : String) throws -> HuffmanTreeNode<T> {
  let lines = try readLines(path)
  return try readTable(lines)
}

public func readFile(fromURL url: URL) throws -> [UInt8] {
  let fileData = try Data(contentsOf: url)
  var byteArray = [UInt8](repeating: 0, count: fileData.count)
  fileData.copyBytes(to: &byteArray, count: fileData.count)
  return byteArray
}

public func writeToFile(toURL url: URL, source : [UInt8]) throws {
  let data = Data(bytes: source)
  try data.write(to: url, options: .atomic)
}

