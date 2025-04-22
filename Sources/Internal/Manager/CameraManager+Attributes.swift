//
//  CameraManager+Attributes.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import AVKit

public struct CameraManagerAttributes {
    public var capturedMedia: MCameraMedia? = nil
    public var capturedProcessedMedia: MCameraMedia? = nil
    var error: MCameraError? = nil

    var outputType: CameraOutputType = .photo
    var cameraPosition: CameraPosition = .back
    public var isAudioSourceAvailable: Bool = false
    var zoomFactor: CGFloat = 1.0
    var flashMode: CameraFlashMode = .off
    var lightMode: CameraLightMode = .off
    var resolution: AVCaptureSession.Preset = .hd1920x1080
    var frameRate: Int32 = 30
    var cameraExposure: CameraExposure = .init()
    var hdrMode: CameraHDRMode = .auto
    var cameraFilters: [CIFilter] = []
    var mirrorOutput: Bool = false
    var isGridVisible: Bool = true

    var deviceOrientation: AVCaptureVideoOrientation = .portrait
    var frameOrientation: CGImagePropertyOrientation = .right
    var orientationLocked: Bool = false
    var userBlockedScreenRotation: Bool = false
}
