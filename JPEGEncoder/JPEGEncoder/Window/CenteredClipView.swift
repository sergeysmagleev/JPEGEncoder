//
//  CenteredClipView.swift
//  JPEGEncoder
//
//  Created by Sergei Smagleev on 12/10/16.
//  Copyright © 2016 sergeysmagleev. All rights reserved.
//

import Cocoa

class CenteredClipView : NSClipView {
  override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
    
    var rect = super.constrainBoundsRect(proposedBounds)
    guard let containerView = self.documentView else {
      return rect
    }
    
    if (rect.size.width > containerView.frame.size.width) {
      rect.origin.x = (containerView.frame.width - rect.width) / 2
    }
    
    if (rect.size.height > containerView.frame.size.height) {
      rect.origin.y = (containerView.frame.height - rect.height) / 2
    }
    
    return rect
  }
}
