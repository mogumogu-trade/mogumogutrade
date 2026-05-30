import SwiftUI
import CoreImage.CIFilterBuiltins

class QRCheckViewModel: ObservableObject {
    @Published var selectedTab = 1
    @Published var qrTokenString: String = "KM-sota-TEST"
    
    // 演出用の状態
    @Published var laserOffset: CGFloat = -95
    @Published var isShowingCelebration = false
    @Published var pointsForAnimation: Int = 350
    @Published var confettiAnimate = false
    
    func startLaserAnimation() {
        DispatchQueue.main.async {
            self.laserOffset = 95
        }
    }
    
    func startConfettiAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            self.confettiAnimate = true
        }
    }
    
    func onScanSuccess(scannedCode: String) {
        guard !isShowingCelebration else { return }
        print("ガチでQR読めた！中身: \(scannedCode)")
        isShowingCelebration = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.pointsForAnimation += 50
            }
        }
    }
    
    func resetCelebration() {
        laserOffset = -95
        confettiAnimate = false
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingCelebration = false
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}
