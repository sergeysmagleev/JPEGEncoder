//
//  AppDelegate.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 23/09/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var imageWindowController : ImageWindowController!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    imageWindowController = ImageWindowController(windowNibName: "ImageWindow")
    imageWindowController.showWindow(self)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}

