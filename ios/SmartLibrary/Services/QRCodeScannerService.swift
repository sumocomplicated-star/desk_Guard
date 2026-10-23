import AVFoundation
import SwiftUI

@MainActor
public final class QRCodeScannerService: NSObject, ObservableObject {
    @Published public private(set) var isSessionRunning: Bool = false
    @Published public private(set) var isPermissionDenied: Bool = false
    @Published public private(set) var isPermissionGranted: Bool = false
    @Published public var isLocked: Bool = false

    public let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.deskguard.scanner.sessionQueue")
    public var onCodeScanned: ((String) -> Void)?

    public override init() {
        super.init()
        checkPermission()
    }

    public func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isPermissionGranted = true
            isPermissionDenied = false
        case .notDetermined:
            isPermissionGranted = false
            isPermissionDenied = false
        case .denied, .restricted:
            isPermissionGranted = false
            isPermissionDenied = true
        @unknown default:
            isPermissionGranted = false
            isPermissionDenied = true
        }
    }

    public func requestPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                self?.isPermissionGranted = granted
                self?.isPermissionDenied = !granted
                completion(granted)
            }
        }
    }

    public func setupSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.captureSession.inputs.isEmpty || self.setupCaptureSession() else {
                return
            }
        }
    }

    private func setupCaptureSession() -> Bool {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("[QRCodeScannerService] Back camera not available (simulator or unsupported device)")
            return false
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                return false
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
                    metadataOutput.metadataObjectTypes = [.qr]
                }
            } else {
                return false
            }

            return true
        } catch {
            print("[QRCodeScannerService] Error setting up camera input: \(error)")
            return false
        }
    }

    public func startScanning() {
        isLocked = false
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                Task { @MainActor in
                    self.isSessionRunning = self.captureSession.isRunning
                }
            }
        }
    }

    public func stopScanning() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                Task { @MainActor in
                    self.isSessionRunning = false
                }
            }
        }
    }

    public func resumeScanning() {
        isLocked = false
    }
}

extension QRCodeScannerService: AVCaptureMetadataOutputObjectsDelegate {
    public nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let first = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              first.type == .qr,
              let stringValue = first.stringValue else {
            return
        }

        Task { @MainActor in
            guard !self.isLocked else { return }
            // Lock to prevent duplicate frames
            self.isLocked = true
            HapticFeedback.selection()
            self.onCodeScanned?(stringValue)
        }
    }
}
