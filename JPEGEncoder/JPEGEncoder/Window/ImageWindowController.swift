//
//  ImageWindowController.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 10/10/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Cocoa

enum ImageWindowState {
  case Undefined
  case Bitmap
  case JPEG
  case Loading
}

class ImageWindowController : NSWindowController {
  
  @IBOutlet weak var scrollView: NSScrollView!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  @IBOutlet weak var openBitmapButton: NSButton!
  @IBOutlet weak var openJPEGButton: NSButton!
  @IBOutlet weak var saveAsJPEGButton: NSButton!
  
  var bitmap : Matrix<RGBPixel>?
  var currentState : ImageWindowState = .Undefined
  
  override func windowDidLoad() {
    super.windowDidLoad()
    configure()
    updateState(.Undefined)
  }
  
  func configure() {
    openBitmapButton.title = "Open Bitmap"
    openJPEGButton.title = "Open JPEG"
    saveAsJPEGButton.title = "Export to JPEG"
  }
  
  //MARK: - Update
  
  func updateState(_ state : ImageWindowState) {
    currentState = state
    switch currentState {
    case .Undefined:
      progressIndicator.alphaValue = 0.0
      scrollView.alphaValue = 1.0
      saveAsJPEGButton.isEnabled = false
      openJPEGButton.isEnabled = true
      openBitmapButton.isEnabled = true
      break
    case .Loading:
      progressIndicator.alphaValue = 1.0
      progressIndicator.startAnimation(nil)
      scrollView.alphaValue = 0.0
      saveAsJPEGButton.isEnabled = false
      openJPEGButton.isEnabled = false
      openBitmapButton.isEnabled = false
      break
    case .Bitmap:
      progressIndicator.alphaValue = 0.0
      scrollView.alphaValue = 1.0
      saveAsJPEGButton.isEnabled = true
      openJPEGButton.isEnabled = true
      openBitmapButton.isEnabled = true
      break
    case .JPEG:
      progressIndicator.alphaValue = 0.0
      scrollView.alphaValue = 1.0
      saveAsJPEGButton.isEnabled = false
      openJPEGButton.isEnabled = true
      openBitmapButton.isEnabled = true
      break
    }
  }
  
  //MARK: - Operations on images
  
  func setImage(image : NSImage?) {
    if let newimage = image {
      let imageView = NSImageView()
      let size = newimage.size
      scrollView.alphaValue = 1
      scrollView.setFrameSize(size)
      imageView.setFrameSize(size)
      imageView.image = newimage
      scrollView.documentView = imageView
      scrollView.resize(withOldSuperviewSize: self.scrollView.frame.size)
    }
  }
  
  func loadBitmap(fromUrl: URL, completion : @escaping (NSImage?) -> ()) {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
      let bitmapData : Matrix<RGBPixel>
      do {
        bitmapData = try readBitmapFromFile(file: fromUrl.path)
      } catch {
        DispatchQueue.main.async {
          completion(nil)
        }
        return
      }
      self.bitmap = bitmapData
      let image = createViewFromBitmapData(bitmapData: bitmapData)
      DispatchQueue.main.async {
        completion(image)
      }
    }
  }
  
  func loadJPEG(fromUrl: URL, completion : @escaping (NSImage?) -> ()) {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
      let bitmapData : Matrix<RGBPixel>
      do {
        let bytes = try readFile(fromURL: fromUrl)
        let height = bytes[0]
        let width = bytes[1]
        let chunks = try decodeChunks(bytes)
        bitmapData = try uncompressRGBData(chunks, rows: Int(height), cols: Int(width))
      } catch {
        DispatchQueue.main.async {
          completion(nil)
        }
        return
      }
      self.bitmap = bitmapData
      let image = createViewFromBitmapData(bitmapData: bitmapData)
      DispatchQueue.main.async {
        completion(image)
      }
    }
  }
  
  func compressImage(url : URL) {
    guard let bitmap = self.bitmap else {
      print("no bitmap to compress")
      return
    }
    updateState(.Loading)
    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
      do {
        let pixels = try compressRGBData(bitmap)
        let binaryData = try encodeChunks(pixels,
                                          rows: Int(ceil(Double(bitmap.height) / 8.0)),
                                          cols: Int(ceil(Double(bitmap.width) / 8.0)))
        try writeToFile(toURL: url, source: binaryData)
        print("compression byte count: \(binaryData.count)")
        
      } catch {
        DispatchQueue.main.async {
          self.updateState(.Undefined)
        }
        print("failed to compress")
        return
      }
      print("saved to a file: \(url)")
      DispatchQueue.main.async {
        self.loadJPEG(fromUrl: url, completion: { image in
          if (image != nil) {
            self.setImage(image: image)
            self.updateState(.JPEG)
          } else {
            self.updateState(.Undefined)
          }
        })
      }
    }
  }
  
  //MARK: - IBActions
  
  @IBAction func openBitmapButtonTapped(_ sender: AnyObject) {
    openBitmapFile()
  }
  
  @IBAction func openJPEGButtonTapped(_ sender: AnyObject) {
    openJPEGFile()
  }
  
  @IBAction func saveAsJPEGButtonTapped(_ sender: AnyObject) {
    saveJPEGFile()
  }
  
  //MARK: - File Dialogs
  
  func openBitmapFile() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Choose a bitmap file"
    openPanel.showsResizeIndicator = true
    openPanel.showsHiddenFiles = false
    openPanel.canChooseDirectories = false
    openPanel.canCreateDirectories = false
    openPanel.allowsMultipleSelection = false
    openPanel.allowedFileTypes = ["bmp"]
    
    if (openPanel.runModal() == NSModalResponseOK) {
      guard let result = openPanel.url else {
        return
      }
      if currentState == .Loading {
        return
      }
      updateState(.Loading)
      loadBitmap(fromUrl: result) { [unowned self] image in
        if (image != nil) {
          self.setImage(image: image)
          self.updateState(.Bitmap)
        } else {
          self.updateState(.Undefined)
        }
      }
    }
  }
  
  func openJPEGFile() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Choose a .cbt_jpeg file"
    openPanel.showsResizeIndicator = true
    openPanel.showsHiddenFiles = false
    openPanel.canChooseDirectories = false
    openPanel.canCreateDirectories = false
    openPanel.allowsMultipleSelection = false
    openPanel.allowedFileTypes = ["cbt_jpeg"]
    
    if (openPanel.runModal() == NSModalResponseOK) {
      guard let result = openPanel.url else {
        return
      }
      if currentState == .Loading {
        return
      }
      updateState(.Loading)
      loadJPEG(fromUrl: result) { [unowned self] image in
        if (image != nil) {
          self.setImage(image: image)
          self.updateState(.JPEG)
        } else {
          self.updateState(.Undefined)
        }
      }
    }
  }
  
  func saveJPEGFile() {
    let savePanel = NSSavePanel()
    savePanel.title = "Choose a .cbt_jpeg file"
    savePanel.showsResizeIndicator = true
    savePanel.showsHiddenFiles = false
    savePanel.canCreateDirectories = false
    savePanel.allowedFileTypes = ["cbt_jpeg"]
    
    if (savePanel.runModal() == NSModalResponseOK) {
      guard let result = savePanel.url else {
        return
      }
      if currentState == .Loading {
        return
      }
      compressImage(url : result)
    }
  }
}
