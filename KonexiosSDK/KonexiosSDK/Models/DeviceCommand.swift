//
//  DeviceCommand.swift
//  KonexiosSDK
//
//  Copyright (c) 2017 Arrow Electronics, Inc.
//  All rights reserved. This program and the accompanying materials
//  are made available under the terms of the Apache License 2.0
//  which accompanies this distribution, and is available at
//  http://apache.org/licenses/LICENSE-2.0
//
//  Contributors: Arrow Electronics, Inc.
//                Konexios, Inc.
//

import Foundation

public class DeviceCommand: RequestModel {

    public var command: String
    public var deviceHid: String
    public var payload: String
    
    public override var params: [String: AnyObject] {
        return [
            "command"   : command as AnyObject,
            "deviceHid" : deviceHid as AnyObject,
            "payload"   : payload as AnyObject
        ]
    }
    
    public init (command: ServerToGatewayCommand, deviceHid: String) {
        self.command   = command.rawValue
        self.deviceHid = deviceHid
        self.payload   = ""
    }
    
}
