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
//
//  CaptureDevice+AVCaptureDevice.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.
//

import AVKit

extension AVCaptureDevice: CaptureDevice {
  // MARK: Getters
  // Note: Many properties like `uniqueID`, `iso`, `exposureDuration`, etc.,
  // are already part of AVCaptureDevice and don't need to be re-declared.
  // Swift matches them to the protocol requirements automatically.

  public var minExposureDuration: CMTime {
    activeFormat.minExposureDuration
  }
  public var maxExposureDuration: CMTime {
    activeFormat.maxExposureDuration
  }
  public var minISO: Float {
    activeFormat.minISO
  }
  public var maxISO: Float {
    activeFormat.maxISO
  }
  public var minFrameRate: Float64? {
    activeFormat.videoSupportedFrameRateRanges.first?.minFrameRate
  }
  public var maxFrameRate: Float64? {
    activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate
  }

  // MARK: Getters & Setters
  // These were in a separate extension, causing the conformance error.
  // They are now moved here.
  public var lightMode: CameraLightMode {
    get { torchMode == .off ? .off : .on }
    set { torchMode = newValue == .off ? .off : .on }
  }
  public var hdrMode: CameraHDRMode {
    get {
      if automaticallyAdjustsVideoHDREnabled {
        return .auto
      } else if isVideoHDREnabled {
        return .on
      } else {
        return .off
      }
    }
    set {
      automaticallyAdjustsVideoHDREnabled = newValue == .auto
      if newValue != .auto {
        isVideoHDREnabled = newValue == .on
      }
    }
  }

  // MARK: Methods
  // The following methods are REMOVED because AVCaptureDevice already
  // implements them. Re-declaring them here causes a recursive loop.
  // Swift automatically satisfies the protocol requirement.
  //
  // public func setExposureModeCustom(duration:iso:completionHandler:)
  // public func setExposureTargetBias(_:completionHandler:)
}
