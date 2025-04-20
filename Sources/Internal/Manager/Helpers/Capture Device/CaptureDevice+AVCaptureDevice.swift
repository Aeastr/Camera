//
//  CaptureDevice+AVCaptureDevice.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import AVKit

// MARK: Getters
extension AVCaptureDevice: CaptureDevice {
    public var minExposureDuration: CMTime { activeFormat.minExposureDuration }
    public var maxExposureDuration: CMTime { activeFormat.maxExposureDuration }
    public var minISO: Float { activeFormat.minISO }
    public var maxISO: Float { activeFormat.maxISO }
    public var minFrameRate: Float64? { activeFormat.videoSupportedFrameRateRanges.first?.minFrameRate }
    public var maxFrameRate: Float64? { activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate }
}

// MARK: Getters & Setters
extension AVCaptureDevice {
    public var lightMode: CameraLightMode {
        get { torchMode == .off ? .off : .on }
        set { torchMode = newValue == .off ? .off : .on }
    }
    public var hdrMode: CameraHDRMode {
        get {
            if automaticallyAdjustsVideoHDREnabled { return .auto }
            else if isVideoHDREnabled { return .on }
            else { return .off }
        }
        set {
            automaticallyAdjustsVideoHDREnabled = newValue == .auto
            if newValue != .auto { isVideoHDREnabled = newValue == .on }
        }
    }
}
