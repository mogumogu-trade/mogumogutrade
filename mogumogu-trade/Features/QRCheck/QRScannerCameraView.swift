import SwiftUI
import AVFoundation

struct QRScannerCameraView: UIViewRepresentable {
    var onQrCodeFound: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 280, height: 280))
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch { return view }

        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        } else { return view }

        let metadataOutput = AVCaptureMetadataOutput()

        if (session.canAddOutput(metadataOutput)) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else { return view }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = CGRect(x: 0, y: 0, width: 280, height: 280)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublineLayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerCameraView

        init(parent: QRScannerCameraView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                DispatchQueue.main.async {
                    self.parent.onQrCodeFound(stringValue)
                }
            }
        }
    }
}

extension CALayer {
    func addSublineLayer(_ layer: CALayer) {
        self.addSublayer(layer)
    }
}
