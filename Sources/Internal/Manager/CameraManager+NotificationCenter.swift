//
//  CameraManager+NotificationCenter.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import Foundation
import UIKit

@MainActor class CameraManagerNotificationCenter {
    private(set) weak var parent: CameraManager?
}

// MARK: Setup
extension CameraManagerNotificationCenter {
    func setup(parent: CameraManager) {
        self.parent = parent
        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: parent.captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeSession), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
}
private extension CameraManagerNotificationCenter {
    @objc func handleSessionWasInterrupted() {
        parent?.attributes.lightMode = .off
        parent?.videoOutput.reset()
    }
    @objc private func resumeSession() {
        let session = parent?.captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            if session?.isRunning == false {
                session?.startRunning() // Restart session when app enters foreground
            }
        }
    }
}

// MARK: Reset
extension CameraManagerNotificationCenter {
    func reset() {
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionWasInterrupted, object: parent?.captureSession)
    }
}
