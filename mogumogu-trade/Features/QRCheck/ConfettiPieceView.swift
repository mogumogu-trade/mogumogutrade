import SwiftUI

struct ConfettiPieceView: View {
    var animate: Bool
    var index: Int
    
    let colors: [Color] = [.yellow, .pink, .blue, .green, .orange, .purple, .cyan]
    
    // 💡 bodyの外側で計算するように直したよ！
    var randomX: CGFloat {
        CGFloat(sin(Double(index) * 45.0) * 160.0)
    }
    
    var randomY: CGFloat {
        CGFloat(cos(Double(index) * 30.0) * 300.0) - (animate ? 50 : 0)
    }
    
    var randomRotation: Double {
        Double(index * 25)
    }
    
    var body: some View {
        Group {
            if index % 2 == 0 {
                Rectangle()
                    .fill(colors[index % colors.count])
                    .frame(width: CGFloat.random(in: 10...18), height: CGFloat.random(in: 10...18))
            } else {
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: CGFloat.random(in: 8...15), height: CGFloat.random(in: 8...15))
            }
        }
        .offset(x: animate ? randomX : 0, y: animate ? randomY : 150)
        .rotationEffect(.degrees(animate ? randomRotation + 360 : randomRotation))
        .opacity(animate ? 0.9 : 0.0)
        .animation(.easeOut(duration: Double.random(in: 0.8...1.5)).delay(Double.random(in: 0.0...0.1)), value: animate)
    }
}
