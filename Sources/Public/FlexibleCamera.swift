import SwiftUI
import AVKit

/// Protocol for defining a custom camera screen.
public protocol FlexibleCameraView: View {
    /// The CameraManager instance driving the session.
    var manager: CameraManager { get }
    /// Controller for capture/retake actions.
    var controller: RawCameraController { get }
    /// Shared namespace for matched geometry.
    var namespace: Namespace.ID { get }
    /// Configuration options.
    var config: FlexibleCameraConfig { get }

    /// Called by the RawCamera host to construct the view.
    init(
        manager: CameraManager,
        controller: RawCameraController,
        namespace: Namespace.ID,
        config: FlexibleCameraConfig
    )
}

// MARK: - Helpers for RawCameraScreen
public extension FlexibleCameraView {
    /// Inserts the live preview and captured-media overlay in your layout.
    @ViewBuilder func createCameraOutputView() -> some View {
        controller.cameraOutputView(namespace: namespace)
    }
}

// MARK: - Camera Control API (like MCameraScreen)
public extension FlexibleCameraView {
    /// Capture current output (photo or video). Equivalent to `capture()`.
    func captureOutput() {
        Task { @MainActor in manager.captureOutput() }
    }
    /// Set photo vs video output type.
    func setOutputType(_ type: CameraOutputType) { manager.setOutputType(type) }
    /// Switch camera (front/back).
    func setCameraPosition(_ position: CameraPosition) async throws { try await manager.setCameraPosition(position) }
    /// Adjust zoom factor.
    func setZoomFactor(_ factor: CGFloat) throws { try manager.setCameraZoomFactor(factor) }
    /// Set flash mode.
    func setFlashMode(_ mode: CameraFlashMode) { manager.setFlashMode(mode) }
    /// Set torch/light mode.
    func setLightMode(_ mode: CameraLightMode) throws { try manager.setLightMode(mode) }
    /// Change resolution.
    func setResolution(_ preset: AVCaptureSession.Preset) { manager.setResolution(preset) }
    /// Set frame rate.
    func setFrameRate(_ fps: Int32) throws { try manager.setFrameRate(fps) }
    /// Control exposure duration.
    func setExposureDuration(_ duration: CMTime) throws { try manager.setExposureDuration(duration) }
    /// Control exposure bias.
    func setExposureTargetBias(_ bias: Float) throws { try manager.setExposureTargetBias(bias) }
    /// Control ISO.
    func setISO(_ iso: Float) throws { try manager.setISO(iso) }
    /// Control exposure mode.
    func setExposureMode(_ mode: AVCaptureDevice.ExposureMode) throws { try manager.setExposureMode(mode) }
    /// Control HDR mode.
    func setHDRMode(_ hdr: CameraHDRMode) throws { try manager.setHDRMode(hdr) }
    /// Apply CIFilters.
    func setCameraFilters(_ filters: [CIFilter]) { manager.setCameraFilters(filters) }
    /// Mirror output.
    func setMirrorOutput(_ mirror: Bool) { manager.setMirrorOutput(mirror) }
    /// Toggle grid overlay.
    func setGridVisibility(_ show: Bool) { manager.setGridVisibility(show) }
}

// MARK: - Camera State Properties
public extension FlexibleCameraView {
    var cameraOutputType: CameraOutputType { manager.attributes.outputType }
    var cameraPosition: CameraPosition { manager.attributes.cameraPosition }
    var zoomFactor: CGFloat { manager.attributes.zoomFactor }
    var flashMode: CameraFlashMode { manager.attributes.flashMode }
    var lightMode: CameraLightMode { manager.attributes.lightMode }
    var resolution: AVCaptureSession.Preset { manager.attributes.resolution }
    var frameRate: Int32 { manager.attributes.frameRate }
    var exposureDuration: CMTime { manager.attributes.cameraExposure.duration }
    var exposureTargetBias: Float { manager.attributes.cameraExposure.targetBias }
    var iso: Float { manager.attributes.cameraExposure.iso }
    var exposureMode: AVCaptureDevice.ExposureMode { manager.attributes.cameraExposure.mode }
    var hdrMode: CameraHDRMode { manager.attributes.hdrMode }
    var cameraFilters: [CIFilter] { manager.attributes.cameraFilters }
    var isOutputMirrored: Bool { manager.attributes.mirrorOutput }
    var isGridVisible: Bool { manager.attributes.isGridVisible }
    var deviceOrientation: AVCaptureVideoOrientation { manager.attributes.deviceOrientation }
}

/// Configuration for the RawCamera host.
public struct FlexibleCameraConfig {
    /// Called when an image is captured.
    public var onImageCaptured: ((UIImage, RawCameraController) -> Void)? = nil
    /// Called when capture is confirmed, passing original and processed images.
    public var onCaptureConfirmed: ((UIImage, RawCameraController) -> Void)? = nil
    /// Whether audio should be available.
    public var isAudioAvailable: Bool = true
    /// Default output type (photo/video).
    public var outputType: CameraOutputType = .photo
    /// Optional custom view builder for captured media (original + processed).
    public var capturedMediaView: ((MCameraMedia, RawCameraController) -> AnyView)? = nil
    /// Optional custom view builder for camera feed.
    public var cameraFeedView: ((CameraManager, RawCameraController, Namespace.ID) -> AnyView)? = nil
    /// Optional custom captured-media screen builder (MCapturedMediaScreen style).
    public var capturedMediaScreen: ((MCameraMedia, Namespace.ID, @escaping () -> Void, @escaping () -> Void) -> AnyView)? = nil
}

/// Controller exposing capture/retake actions.
@MainActor public final class RawCameraController {
    private let manager: CameraManager
    private let config: FlexibleCameraConfig
    /// Last processed image provided on accept.
    private var processedImage: UIImage? = nil

    init(manager: CameraManager, config: FlexibleCameraConfig) {
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
//            try? await manager.setup()
//            manager.startSession()
        }
    }

    /// Accept the current capture, optionally supplying a processed image.
    public func accept() {
        guard let original = manager.attributes.capturedMedia?.getImage() else { return }
        // original callback
//        config.onImageCaptured?(original, self)
        // confirmed with processed
        config.onCaptureConfirmed?(original, self)
    }

    /// The live preview and captured-media overlay.
    @ViewBuilder public func cameraOutputView(namespace: Namespace.ID) -> some View {
        if let feedBuilder = config.cameraFeedView {
            feedBuilder(manager, self, namespace)
                .overlay {
                    if let media = manager.attributes.capturedMedia {
                        if let custom = config.capturedMediaView {
                            custom(media, self)
                        } else if let screenBuilder = config.capturedMediaScreen {
                            screenBuilder(media, namespace, { self.retake() }, { self.accept() })
                        } else if let uiImg = media.getImage() {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        } else if let url = media.getVideo() {
                            VideoPlayer(player: AVPlayer(url: url))
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        }
                    }
                }
                .clipped()
        } else {
            CameraBridgeView(cameraManager: manager)
                .overlay {
                    if let media = manager.attributes.capturedMedia {
                        if let custom = config.capturedMediaView {
                            custom(media, self)
                        } else if let screenBuilder = config.capturedMediaScreen {
                            screenBuilder(media, namespace, { self.retake() }, { self.accept() })
                        } else if let uiImg = media.getImage() {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        } else if let url = media.getVideo() {
                            VideoPlayer(player: AVPlayer(url: url))
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        }
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
public struct FlexibleCamera<Screen: FlexibleCameraView>: View {
    @StateObject private var manager = CameraManager(
        captureSession: AVCaptureSession(),
        captureDeviceInputType: AVCaptureDeviceInput.self
    )
    @Namespace private var namespace
    private var screenType: Screen.Type
    private var config: FlexibleCameraConfig

    /// Start with your custom screen type.
    public init(screen: Screen.Type = Screen.self) {
        self.screenType = screen
        self.config = FlexibleCameraConfig()
    }

    /// Called when an image is captured.
    public func onImageCaptured(_ callback: @escaping (UIImage, RawCameraController) -> Void) -> FlexibleCamera {
        var copy = self
        copy.config.onImageCaptured = callback
        return copy
    }

    /// Called when capture is confirmed; provides original and processed images.
    public func onCaptureConfirmed(_ callback: @escaping (UIImage, RawCameraController) -> Void) -> FlexibleCamera {
        var copy = self
        copy.config.onCaptureConfirmed = callback
        return copy
    }

    /// Enable or disable audio support.
    public func setAudioAvailability(_ value: Bool) -> FlexibleCamera {
        var copy = self
        copy.config.isAudioAvailable = value
        return copy
    }

    /// Choose .photo or .video.
    public func setCameraOutputType(_ type: CameraOutputType) -> FlexibleCamera {
        var copy = self
        copy.config.outputType = type
        return copy
    }

    /// Provide a custom view for captured media overlay.
    public func setCapturedMediaView<Content: View>(@ViewBuilder _ builder: @escaping (MCameraMedia, RawCameraController) -> Content) -> FlexibleCamera {
        var copy = self
        copy.config.capturedMediaView = { media, controller in AnyView(builder(media, controller)) }
        return copy
    }

    /// Provide a custom view for the camera feed.
    public func setCameraFeedView<Content: View>(@ViewBuilder _ builder: @escaping (CameraManager, RawCameraController, Namespace.ID) -> Content) -> FlexibleCamera {
        var copy = self
        copy.config.cameraFeedView = { manager, controller, namespace in AnyView(builder(manager, controller, namespace)) }
        return copy
    }

    /// Provide a custom captured-media screen conforming to MCapturedMediaScreen protocol.
    public func setCapturedMediaScreen<Content: MCapturedMediaScreen>(_ builder: @escaping (MCameraMedia, Namespace.ID, @escaping () -> Void, @escaping () -> Void) -> Content) -> FlexibleCamera {
        var copy = self
        copy.config.capturedMediaScreen = { media, namespace, retake, accept in AnyView(builder(media, namespace, retake, accept)) }
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
        }
}
