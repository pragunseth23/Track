import SwiftUI

struct PieChartView: View {
    let data: [(name: String, value: Double, color: Color)]
    let size: CGFloat
    
    init(data: [(name: String, value: Double, color: Color)], size: CGFloat = 200) {
        self.data = data
        self.size = size
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            
            ZStack {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    PieSlice(
                        startAngle: angle(for: index),
                        endAngle: angle(for: index + 1)
                    )
                    .fill(item.color)
                    .frame(width: radius * 2, height: radius * 2)
                    .offset(x: center.x - radius, y: center.y - radius)
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    private func angle(for index: Int) -> Angle {
        let total = data.reduce(0) { $0 + $1.value }
        guard total > 0 else { return .zero }
        
        let cumulative = data.prefix(index).reduce(0) { $0 + $1.value }
        let percentage = cumulative / total
        return Angle(degrees: percentage * 360 - 90)
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

struct SpendingPieChart: View {
    let data: [(name: String, value: Double, color: Color)]
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            PieChartView(data: data, size: 200)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(data, id: \.name) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text(formatCurrency(item.value))
                            .font(.numericSmall)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ cents: Double) -> String {
        let dollars = cents / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}
