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

        //registers the app delegate to observer "down" messages from any object that sends one
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handle:"), name: "down", object: nil)

        //registers the app delegate to observer "dragged" messages from any object that sends one
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handle:"), name: "dragged", object: nil)
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
        //writes the data to the specified socket
        writeTo(sock, data: data)
    }

    func writeTo(sock: GCDAsyncSocket, data: NSData) {
        let data = NSMutableData(data: data)
        //appends an extra bit of data that acts as an "end point" for reading
        data.appendData(GCDAsyncSocket.CRLFData())
        //writes the full data to the socket
        sock.writeData(data, withTimeout: -1, tag: 0)
        //tells the socket to read until it reaches the "end point"
        sock.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
    }

    func writeToSockets(sockets: [GCDAsyncSocket], message: String) {
        println(__FUNCTION__)
        //converts the message to data
        let data = NSMutableData(data: message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        //writes the data to all the sockets
        writeToSockets(sockets, data: data)
    }

    func writeToSockets(sockets: [GCDAsyncSocket], data: NSData) {
        println(__FUNCTION__)
        //converts the message to data
        let data = NSMutableData(data: data)
        //appends an extra bit of data that acts as an "end point" for reading
        data.appendData(GCDAsyncSocket.CRLFData())
        //loops through the array of sockets
        for sock in sockets {
            //writes the full data to the socket
            sock.writeData(data, withTimeout: -1, tag: 0)
            //tells the socket to read until it reaches the "end point"
            sock.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
        }
    }

    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        println(__FUNCTION__)
        sock.readDataWithTimeout(-1, tag: 0)
    }

    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        let range = data.rangeOfData(GCDAsyncSocket.CRLFData(), options: .Backwards, range: NSMakeRange(0, data.length))
        let modData = data.subdataWithRange(NSMakeRange(0, range.location))

        var otherSockets = [GCDAsyncSocket]()

        for socket in connectedSockets {
            if socket != connectedSockets {
                otherSockets.append(socket)
            }
        }

        writeToSockets(otherSockets, data: modData)

        let s = NSString(data: data, encoding: NSUTF8StringEncoding)

        if let components = s?.componentsSeparatedByString("|") {
            if components.count > 1 {
                var state = ""
                if let s = components[2] as? String {
                    state = s
                }
                println("\(__FUNCTION__) name: \(components[0]) location: \(components[1]) state:\(state)")
            } else {
                println("\(__FUNCTION__) message: \(s)")
            }
        }

        sock.readDataWithTimeout(-1, tag: 0)
    }

    func handle(notification: NSNotification) {
        //checks to see if the notification is down or dragged
        if notification.name == "down" || notification.name == "dragged" {
            //if so, attempt to convert the notification's userInfo into a dictionary with the right types
            if let info = notification.userInfo as? Dictionary<String,NSEvent> {
                //check to see if the "event" actually exists
                if let event = info["event"] {
                    //if so, convert the event's location to a string
                    var location = "\(event.locationInWindow)"
                    relayMouseEvent(notification.name, location: location)
                }
                else {
                    println("no value for 'event'")
                }
            } else {
                println("wrong userInfo type")
            }
        }
    }

    func relayMouseEvent(name: String, location: String) {
        //converts the name and location of a mouse event into a string that can be sent to peripherals
        let message = "\(name):\(location)"
        //sends the message to all connected sockets
        writeToSockets(connectedSockets, message: message)
    }
}

