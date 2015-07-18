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

    //A list of all the sockets that have been connected
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
                netService = NSNetService(domain: "local.", type: "_m-o._tcp.", name: "m-o-core-service", port: Int32(port))

                //set the net service's delegate
                netService?.delegate = self

                //publish the service
                netService?.publish()
            }
        } else {
            //couldn't set up the socket to accept connections
            println("Error in acceptOnPort:error: -> \(error)")
        }
    }

    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        println("\(__FUNCTION__) from: \(newSocket.connectedHost):\(newSocket.connectedPort)")
        connectedSockets.append(newSocket)
        writeTo(newSocket, message: "handshake-from-central")
    }

    func writeTo(sock: GCDAsyncSocket, message: String) {
        println(__FUNCTION__)
        //converts the message to data
        let data = NSMutableData(data: message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        //appends an extra bit of data that acts as an "end point" for reading
        data.appendData(GCDAsyncSocket.CRLFData())
        //writes the full data to the socket
        sock.writeData(data, withTimeout: -1, tag: 0)
        //tells the socket to read until it reaches the "end point"
        sock.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
    }

    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        println(__FUNCTION__)
        sock.readDataWithTimeout(-1, tag: 0)
    }

    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        let s = NSString(data: data, encoding: NSUTF8StringEncoding)
        println("\(__FUNCTION__) message: \(s)")
    }
}

