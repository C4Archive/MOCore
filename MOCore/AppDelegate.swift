//
//  AppDelegate.swift
//  MOCore
//
//  Created by travis on 2015-07-17.
//  Copyright (c) 2015 C4. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate  {
    //The service used to broadcast the core, peripherals will find this and connect to it
    var netService : NSNetService?
    //The core's main socket, all peripherals will connect to this one
    var asyncSocket : GCDAsyncSocket?
    //A list of sockets that keeps track of peripherals that have successfully connected
    var connectedSockets = [GCDAsyncSocket]()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        //creates the primary socket, on the main queue
        asyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        
        //tells the socket to begin listening and accepting connections
        var error : NSError?
        if asyncSocket?.acceptOnPort(0, error: &error) == true {
            //if the socket is able to accept, and has a valid local port number
            if let port : UInt16 = asyncSocket?.localPort {
                //then set up the service to be published
                netService = NSNetService(domain: "local.", type: "_m-o._tcp.", name: "m-o-centralService", port: Int32(port))
                netService?.delegate = self
                netService?.publish()
            }
        } else {
            //couldn't set up the socket to accept connections
            println("Error in acceptOnPort:error: -> \(error)")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }
}

