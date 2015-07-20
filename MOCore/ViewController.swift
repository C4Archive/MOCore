//
//  ViewController.swift
//  MOCore
//
//  Created by travis on 2015-07-17.
//  Copyright (c) 2015 C4. All rights reserved.
//

import Cocoa

public class ViewController: NSViewController {
    //gets called when a mouse press occurs in the main view
    public override func mouseDown(theEvent: NSEvent) {
        //sends a "down" message, along with the event itself
        NSNotificationCenter.defaultCenter().postNotificationName("down", object: self, userInfo: ["event":theEvent])
    }
    //gets called when a mouse is dragged around the main view
    public override func mouseDragged(theEvent: NSEvent) {
        //sends a "dragged" message, along with the event itself, whenever the position of the mouse changes while pressed
        NSNotificationCenter.defaultCenter().postNotificationName("dragged", object: self, userInfo: ["event":theEvent])
    }
}

