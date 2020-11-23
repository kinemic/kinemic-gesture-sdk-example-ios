//
//  SingleBandEngine.swift
//  kinemic-gesture-sdk-example-ios
//
//  Created by Fabian on 10.06.20.
//  Copyright © 2020 kinemic. All rights reserved.
//

import Foundation
import KinemicGesture

enum SearchState {
    case off
    case discovery
    case searchStrongest
}

class SingleBandModel: ObservableObject {
    
    @Published fileprivate(set) var band: String?
    @Published fileprivate(set) var connectionState: ConnectionState = .disconnected
    @Published fileprivate(set) var connectionStateChangeReason: ConnectionReason = .none
    @Published fileprivate(set) var activationState: ActivationState = .inactive
    @Published fileprivate(set) var searchState: SearchState = .off
    @Published fileprivate(set) var batteryCharge: Int = 0
    @Published fileprivate(set) var isCharging: Bool = false
    @Published fileprivate(set) var isPowered: Bool = false
    @Published fileprivate(set) var streamQuality: Int = 0
    @Published fileprivate(set) var requiredPrecision: RequiredGesturePrecision = .medium
    @Published fileprivate(set) var handedness: Handedness = .rightHanded
    
    private let engine: Engine
    private lazy var stateObserver = StateObserver(model: self)
    fileprivate var searchRequested: SearchState = .off
    
    init(from engine: Engine) {
        self.engine = engine
        
        self.engine.register(searchCallback: stateObserver)
        self.engine.register(bandStateListener: stateObserver)
        
        var bands = engine.getBands()
        if bands.count > 0 {
            let first = bands.remove(at: 0)
            
            if bands.count > 0 {
                print("Warning: more than one band connected, disconnecting others...")
                for band in bands {
                    engine.disconnect(band)
                }
            }
            
            print("Found a connected band on startup, initialize state...")
            let state = engine.getConnectionState(first)
            stateObserver.engine(engine, didChangeConnectionState: state, of: first, reason: .success)
        }
    }
    
    deinit {
        self.engine.unregister(searchCallback: stateObserver)
        self.engine.unregister(bandStateListener: stateObserver)
    }
    
    public func connect(_ band: String) {
        disconnect()
        engine.connect(band)
    }
    
    public func disconnect() {
        engine.disconnect(band ?? "")
    }
    
    public func startSearch() {
        searchRequested = .discovery
        engine.startSearch()
    }
    
    public func stopSearch() {
        searchRequested = .off
        engine.stopSearch()
    }
    
    public func connectStrongest() {
        searchRequested = .searchStrongest
        engine.connectStrongest()
    }
    
    public func vibrate(for durationMs: Int) {
        engine.vibrate(band ?? "", for: durationMs)
    }
    
    public func setLed(_ led: Led) {
        engine.setLed(band ?? "", led: led)
    }
    
    public func setActivationState(_ state: ActivationState) {
        engine.setActivationState(band ?? "", state: state)
    }
    
    public func setHandedness(_ handedness: Handedness) {
        engine.setHandedness(band ?? "", handedness: handedness)
    }
    
    public func startAirmouse() {
        engine.startAirmouse(band ?? "")
    }
}

fileprivate class StateObserver: BandStateListener, SearchCallback {
    
    private weak var model: SingleBandModel?
    
    init(model: SingleBandModel) {
        self.model = model
    }
    
    func engine(_ engine: Engine, didChangeConnectionState connectionState: ConnectionState, of band: String, reason: ConnectionReason) {
        if connectionState == .disconnected {
            model?.band = nil
            
            model?.activationState = .inactive
            model?.isCharging = false
            model?.isPowered = false
            model?.streamQuality = 0
            model?.batteryCharge = 0
            model?.requiredPrecision = .medium
            model?.handedness = .rightHanded
        } else if (model?.band != band) {
            // new band
            model?.band = band
            
            model?.activationState = engine.getActivationState(band)
            model?.isCharging = engine.getBatteryCharging(band)
            model?.isPowered = engine.getBatteryPowered(band)
            model?.streamQuality = engine.getStreamQuality(band)
            model?.batteryCharge = engine.getBattery(band)
            model?.requiredPrecision = engine.getRequiredGesturePrecision(band)
            model?.handedness = engine.getHandedness(band)
        }
        
        model?.connectionState = connectionState
        model?.connectionStateChangeReason = reason
    }
    
    func engine(_ engine: Engine, didChangeButtonState pressed: Bool, of band: String) {
        if !pressed {
            engine.setActivationState(band, state: engine.getActivationState(band) == .active ? .inactive : .active)
        }
    }
    
    func engine(_ engine: Engine, didChangeActivationState activationState: ActivationState, of band: String) {
        assert(band == model?.band)
        model?.activationState = activationState
        
        switch activationState {
        case .active:
            engine.setLed(band, led: .blue)
        case .inactive:
            engine.setLed(band, led: .yellow)
        }
    }
    
    func engine(_ engine: Engine, didChangeBatteryCharge charge: Int, powered: Bool, charging: Bool, of band: String) {
        assert(band == model?.band)
        model?.batteryCharge = charge
        model?.isPowered = powered
        model?.isCharging = charging
    }
    
    func engine(_ engine: Engine, didChangeStreamQuality streamQuality: Int, of band: String) {
        assert(band == model?.band)
        model?.streamQuality = streamQuality
    }
    
    func engine(_ engine: Engine, didChangeHandedness handedness: Handedness, of band: String) {
        assert(band == model?.band)
        model?.handedness = handedness
    }
    
    // MARK: - Search state
    
    func engineDidStartSearch(_ engine: Engine) {
        assert(model?.searchState == .off)
        assert(model?.searchRequested != .off)
        
        model?.searchState = model!.searchRequested
        model?.searchRequested = .off
    }
    
    func engineDidStopSearch(_ engine: Engine) {
        assert(model?.searchState != .off)
        
        model?.searchState = .off
    }
    
    func engine(_ engine: Engine, didFindBand band: String, rssi: Int) {
        assert(model?.searchState == .discovery)
    }
    
    func engine(_ engine: Engine, didUpdateConfidence confidence: Int, of band: String) {
        //assert(model?.searchState == .searchStrongest) TODO: there is one update after search stopped
    }
}
