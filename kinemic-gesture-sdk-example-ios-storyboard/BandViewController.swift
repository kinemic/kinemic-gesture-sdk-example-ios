//
//  FirstViewController.swift
//  kinemic-gesture-sdk-example-ios-storyboard
//
//  Created by Fabian on 10.06.20.
//  Copyright © 2020 kinemic. All rights reserved.
//

import UIKit
import KinemicGesture
import Combine

class BandViewController: UIViewController {

    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var bandLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    var engine: SingleBandModel!
    var tokens: [AnyCancellable] = [AnyCancellable]()
    var bandToken: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        engine = SingleBandModel(from: AppDelegate.engine)
        
        tokens.append(engine.$connectionState.sink(receiveValue: {connectionState in
            
            self.stateLabel.text = "\(connectionState)"
            
            switch connectionState {
            case .connected:
                self.connectButton.setTitle("Disconnect", for: .normal)
                self.connectButton.isEnabled = true
            case .connecting, .reconnecting, .disconnecting:
                self.connectButton.setTitle("Disconnect", for: .disabled)
                self.connectButton.isEnabled = false
            case .disconnected:
                self.connectButton.setTitle("Connect Strongest", for: .normal)
                self.connectButton.isEnabled = true
            }
        }))
        
        tokens.append(engine.$band.sink(receiveValue: {band in
            self.bandLabel.text = String((band ?? "None").prefix(5))
        }))
    }

    
    @IBAction @objc func connectButtonClicked() {
        switch(engine.connectionState) {
        case .connected:
            engine.disconnect()
        case .disconnected:
            engine.connectStrongest()
        default:
            break
        }
    }
    
    
}

extension BandViewController: BandStateListener {
    func engine(_ engine: Engine, didChangeConnectionState connectionState: ConnectionState, of band: String, reason: ConnectionReason) {
        
    }
}

