import SwiftUI
import AVKit

/// Protocol for defining a custom camera screen.
public protocol RawCameraScreen: View {
    /// The CameraManager instance driving the session.
    var manager: CameraManager { get }
    /// Controller for capture/retake actions.
    var controller: RawCameraController { get }
    /// Shared namespace for matched geometry.
    var namespace: Namespace.ID { get }
    /// Configuration options.
    var config: RawCameraConfig { get }

    /// Called by the RawCamera host to construct the view.
    init(
        manager: CameraManager,
        controller: RawCameraController,
        namespace: Namespace.ID,
        config: RawCameraConfig
    )
}

// MARK: - Helpers for RawCameraScreen
public extension RawCameraScreen {
    /// Inserts the live preview and captured-media overlay in your layout.
    @ViewBuilder func createCameraOutputView() -> some View {
        controller.cameraOutputView(namespace: namespace)
    }
}

/// Configuration for the RawCamera host.
public struct RawCameraConfig {
    /// Called when an image is captured.
    public var onImageCaptured: ((UIImage, RawCameraController) -> Void)? = nil
    /// Whether audio should be available.
    public var isAudioAvailable: Bool = true
    /// Default output type (photo/video).
    public var outputType: CameraOutputType = .photo
}

/// Controller exposing capture/retake actions.
@MainActor public final class RawCameraController {
    private let manager: CameraManager
    private let config: RawCameraConfig

    init(manager: CameraManager, config: RawCameraConfig) {
        self.manager = manager
        self.config = config
    }

    /// Trigger a capture (photo or video toggle) on the main actor.
    public func capture() {
        Task { @MainActor in
            manager.captureOutput()
        }
    }

    /// Discards the current capture and restarts session on the main actor.
    public func retake() {
        Task { @MainActor in
            manager.setCapturedMedia(nil)
            try? await manager.setup()
            manager.startSession()
        }
    }

    /// The live preview and captured-media overlay.
    @ViewBuilder public func cameraOutputView(namespace: Namespace.ID) -> some View {
        ZStack {
            // camera feed
            CameraBridgeView(cameraManager: manager)
                .ignoresSafeArea()
                .overlay {
                    // show captured image over feed
                    if let uiImg = manager.attributes.capturedMedia?.getImage() {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                }
                .clipped()
        }
    }
}

/// A SwiftUI host that drives a custom RawCameraScreen.
/// Usage:
/// ```swift
/// RawCamera<CustomScreen>()
///   .onImageCaptured { image, controller in /* ... */ }
///   .setAudioAvailability(false)
///   .setCameraOutputType(.photo)
/// ```
public struct RawCamera<Screen: RawCameraScreen>: View {
    @StateObject private var manager = CameraManager(
        captureSession: AVCaptureSession(),
        captureDeviceInputType: AVCaptureDeviceInput.self
    )
    @Namespace private var namespace
    private var screenType: Screen.Type
    private var config: RawCameraConfig

    /// Start with your custom screen type.
    public init(screen: Screen.Type = Screen.self) {
        self.screenType = screen
        self.config = RawCameraConfig()
    }

    /// Called when an image is captured.
    public func onImageCaptured(_ callback: @escaping (UIImage, RawCameraController) -> Void) -> RawCamera {
        var copy = self
        copy.config.onImageCaptured = callback
        return copy
    }

    /// Enable or disable audio support.
    public func setAudioAvailability(_ value: Bool) -> RawCamera {
        var copy = self
        copy.config.isAudioAvailable = value
        return copy
    }

    /// Choose .photo or .video.
    public func setCameraOutputType(_ type: CameraOutputType) -> RawCamera {
        var copy = self
        copy.config.outputType = type
        return copy
    }

    /// Build the custom screen view.
    public func createCameraOutputView() -> some View {
        screenType.init(
            manager: manager,
            controller: RawCameraController(manager: manager, config: config),
            namespace: namespace,
            config: config
        )
    }

    public var body: some View {
        createCameraOutputView()
            .onAppear {
                Task {
                    try? await manager.setup()
                    manager.startSession()
                }
            }
            .onChange(of: manager.attributes.capturedMedia) { media in
                if let uiImg = media?.getImage() {
                    config.onImageCaptured?(uiImg, RawCameraController(manager: manager, config: config))
                }
            }
    }
}
