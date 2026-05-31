import CoreImage.CIFilterBuiltins
import Dependencies
import Foundation
import UIKit

/// QRトークンの生成・読み取り（パース）を扱う Client。
///
/// AGENTS.md 方針に従い、QR生成/読取は副作用として注入する。
/// View から `CIFilter` を直接呼ばない。
struct QRCodeClient: Sendable {
    /// `QRPayload` を JSON 化して QR 画像にする。
    var generate: @Sendable (_ payload: QRPayload) -> UIImage?
    /// 読み取った文字列を `QRPayload` に復元する。形式不正なら nil。
    var parse: @Sendable (_ string: String) -> QRPayload?
}

extension QRCodeClient: DependencyKey {
    static let liveValue = QRCodeClient(
        generate: { payload in
            guard
                let data = try? makeEncoder().encode(payload),
                let json = String(data: data, encoding: .utf8)
            else { return nil }
            return makeImage(from: json)
        },
        parse: { string in
            guard let data = string.data(using: .utf8) else { return nil }
            return try? makeDecoder().decode(QRPayload.self, from: data)
        }
    )

    static let previewValue = liveValue

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    private static func makeImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        guard let output = filter.outputImage else { return nil }
        // 拡大して粗いドット絵にならないようにする。
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension DependencyValues {
    var qrCodeClient: QRCodeClient {
        get { self[QRCodeClient.self] }
        set { self[QRCodeClient.self] = newValue }
    }
}
