import SwiftUI

struct BackgroundGradientLayer: View {
    var body: some View {
        let cssAngle = 177.0
        let r = cssAngle * .pi / 180.0
        let dx = sin(r)
        let dy = -cos(r)
        
        let start = UnitPoint(x: 0.5 - 0.5 * dx, y: 0.5 - 0.5 * dy)
        let end   = UnitPoint(x: 0.5 + 0.5 * dx, y: 0.5 + 0.5 * dy)
        
        let stops: [Gradient.Stop] = [
            .init(color: Color(red: 37.0/255.0, green: 61.0/255.0, blue: 87.0/255.0), location: 0.0452),
            .init(color: Color(red: 16.0/255.0, green: 41.0/255.0, blue: 68.0/255.0), location: 0.3129),
            .init(color: .black, location: 0.9638)
        ]
        
        return Rectangle()
            .fill(LinearGradient(gradient: Gradient(stops: stops), startPoint: start, endPoint: end))
            .ignoresSafeArea()
    }
}
