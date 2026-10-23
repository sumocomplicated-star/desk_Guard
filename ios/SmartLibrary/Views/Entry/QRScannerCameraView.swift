import AVFoundation
import SwiftUI

public struct QRScannerCameraView: View {
    @ObservedObject public var scannerService: QRCodeScannerService
    @State private var scanLineOffset: CGFloat = -110

    public init(scannerService: QRCodeScannerService) {
        self.scannerService = scannerService
    }

    public var body: some View {
        ZStack {
            // Camera Feed or Fallback
            if scannerService.isPermissionDenied {
                permissionDeniedView
            } else {
                CameraPreview(captureSession: scannerService.captureSession)
                    .onAppear {
                        scannerService.setupSessionIfNeeded()
                        scannerService.startScanning()
                    }
                    .onDisappear {
                        scannerService.stopScanning()
                    }

                // Viewfinder Overlay
                viewfinderOverlay
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    private var viewfinderOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)

            // Scanning Target Box
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 2.5)
                .frame(width: 220, height: 220)
                .background(Color.clear)

            // Animated Laser Scanline
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Theme.primary.opacity(0.8), Color.white, Theme.primary.opacity(0.8), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 210, height: 2.5)
                .offset(y: scanLineOffset)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true)
                    ) {
                        scanLineOffset = 110
                    }
                }

            // Locked / Processed flash indicator
            if scannerService.isLocked {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.available.opacity(0.3))
                    .frame(width: 220, height: 220)
                    .transition(.opacity)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 42))
                .foregroundColor(.secondary)

            Text("Camera Access Required")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Text("Please enable camera access in Settings to scan library QR codes.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
    }
}

public struct CameraPreview: UIViewRepresentable {
    public let captureSession: AVCaptureSession

    public init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        view.previewLayer.session = captureSession
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

public final class CameraPreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    public var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
