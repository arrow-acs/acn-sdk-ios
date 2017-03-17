//
//  IotDataPublisher.swift
//  AcnSDK
//
//  Created by Michael Kalinin on 15/03/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

public class IotDataPublisher: NSObject, EDQueueDelegate {
    
    let UploadTaskIdentifier = "upload_task"
    
    var reachability: Reachability?
    
    // singleton
    public static let sharedInstance = IotDataPublisher()

    private override init() {        
        
    }
    
    public func start() {
        EDQueue.sharedInstance().delegate = self
        EDQueue.sharedInstance().start()
        
        setupReachability()
    }
    
    func setupReachability() {
       
        reachability = Reachability()

        reachability?.whenReachable = { reachability in
            EDQueue.sharedInstance().start()
        }
        reachability?.whenUnreachable = { reachability in
            EDQueue.sharedInstance().stop()
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    public func sendData(data: IotDataLoad) {
        EDQueue.sharedInstance().enqueue(withData: data.toDataDict(), forTask: UploadTaskIdentifier)
    }
    
    // MARK: EDQueueDelegate
    
    public func queue(_ queue: EDQueue!, processJob job: [AnyHashable : Any]!, completion block: AcnSDK.EDQueueCompletionBlock!) {
        print("[EDQueue] - EDQueueDelegate ...")
        let dataLoad = IotDataLoad(dataDict: (job["data"] as! [String: AnyObject]))
        doSendData(dataLoad: dataLoad, completion: block)
    }
   
    // MARK: private
    
    private func doSendData(dataLoad: IotDataLoad, completion block: AcnSDK.EDQueueCompletionBlock!) {
        var cloudPlatform = CloudPlatform.IotConnect
        if Profile.sharedInstance.cloudConfig != nil {
            cloudPlatform = CloudPlatform(rawValue: Profile.sharedInstance.cloudConfig!.cloudPlatform)!
        }
        switch cloudPlatform {
        case .Ibm:
            print("[doSendData] send to IBM ...")
            if Profile.sharedInstance.cloudConfig?.ibmConfig != nil {
                if !IotFoundation.sharedInstance.isConnected() {
                    IotFoundation.sharedInstance.connect()
                }
                IotFoundation.sharedInstance.sendTelemetries(data: dataLoad) { (success) -> Void in
                    if block != nil {
                        if (success) {
                            block(EDQueueResult.success)
                        } else {
                            block(EDQueueResult.fail)
                        }
                    }
                }
            } else {
                print("[doSendData] IBM configuration not found")
            }
        case .IotConnect:
            print("[doSendData] send to IotConnect ...")
            if !IotConnectService.sharedInstance.isMQTTConnected() {
                IotConnectService.sharedInstance.reconnectMQTT()
            }
            IotConnectService.sharedInstance.sendTelemetries(data: dataLoad) { (success) -> Void in
                if block != nil {
                    if (success) {
                        block(EDQueueResult.success)
                    } else {
                        block(EDQueueResult.fail)
                    }
                }
            }
        case .Azure:
            print("[doSendData] send to Azure ...")
            if Profile.sharedInstance.cloudConfig?.azureConfig != nil {
                if !AzureService.sharedInstance.isConnected() {
                    AzureService.sharedInstance.connect()
                }
                AzureService.sharedInstance.sendTelemetries(data: dataLoad) { success in
                    if block != nil {
                        if success {
                            block(EDQueueResult.success)
                        } else {
                            block(EDQueueResult.fail)
                        }
                    }
                }
            } else {
                print("[doSendData] Azure configuration not found")
            }
        default:
            print("[queue] cloudPlatform not supported: \(cloudPlatform)")
        }
    }
}
