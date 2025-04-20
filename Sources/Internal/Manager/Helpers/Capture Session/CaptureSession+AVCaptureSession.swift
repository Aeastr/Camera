//
//  CaptureSession+AVCaptureSession.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import AVKit

extension AVCaptureSession: @unchecked @retroactive Sendable {}
extension AVCaptureSession: CaptureSession {
    public var deviceInputs: [any CaptureDeviceInput] { inputs as? [any CaptureDeviceInput] ?? [] }
}


// MARK: - METHODS



extension AVCaptureSession {
    public func stopRunningAndReturnNewInstance() -> any CaptureSession {
        self.stopRunning()
        return AVCaptureSession()
    }
}
extension AVCaptureSession {
    public func add(input: (any CaptureDeviceInput)?) throws(MCameraError) {
        guard let input = input as? AVCaptureDeviceInput else { throw .cannotSetupInput }
        if canAddInput(input) { addInput(input) }
    }
    public func remove(input: (any CaptureDeviceInput)?) {
        guard let input = input as? AVCaptureDeviceInput else { return }
        removeInput(input)
    }
}
extension AVCaptureSession {
    public func add(output: AVCaptureOutput?) throws(MCameraError) {
        guard let output else { throw .cannotSetupOutput }
        if canAddOutput(output) { addOutput(output) }
    }
}
