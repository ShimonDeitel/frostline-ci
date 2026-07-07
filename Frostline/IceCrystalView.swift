import SwiftUI

/// A hexagonal ice-crystal drawn with Canvas that grows branches and sparkle
/// layers as the streak crosses milestones (3, 7, 14, 30, 60, 100 days).
/// On a streak break, `isShattering` drives a crack/shatter animation before
/// the crystal rebuilds from day 1.
struct IceCrystalView: View {
    let streak: Int
    var isShattering: Bool = false

    private var milestone: Milestone? {
        StreakMath.highestMilestone(for: streak)
    }

    /// Branch layers grow with milestone level: 0 (no streak) through 4 (100 days).
    private var layerCount: Int {
        switch milestone {
        case nil: return streak > 0 ? 1 : 0
        case .three: return 1
        case .seven: return 2
        case .fourteen: return 3
        case .thirty: return 3
        case .sixty: return 4
        case .oneHundred: return 5
        }
    }

    private var hasSparkle: Bool {
        milestone.map { $0.rawValue >= 30 } ?? false
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: hasSparkle ? 0.05 : 1)) { context in
            Canvas { gc, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 * 0.88

                if isShattering {
                    drawShatter(gc: gc, center: center, radius: radius)
                } else {
                    drawCrystal(gc: gc, center: center, radius: radius, time: context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: streak)
        .animation(.easeInOut(duration: 0.4), value: isShattering)
    }

    private func drawCrystal(gc: GraphicsContext, center: CGPoint, radius: CGFloat, time: Double) {
        let armCount = 6
        let baseColor = FrostTheme.cyan
        let deepColor = FrostTheme.frostBlue

        for arm in 0..<armCount {
            let angle = (Double(arm) / Double(armCount)) * 2 * .pi - .pi / 2
            drawArm(gc: gc, center: center, radius: radius, angle: angle, layers: layerCount, color: baseColor, deepColor: deepColor)
        }

        // Core hexagon.
        var corePath = Path()
        for i in 0..<6 {
            let a = (Double(i) / 6.0) * 2 * .pi - .pi / 2
            let point = CGPoint(x: center.x + CGFloat(cos(a)) * radius * 0.16, y: center.y + CGFloat(sin(a)) * radius * 0.16)
            if i == 0 { corePath.move(to: point) } else { corePath.addLine(to: point) }
        }
        corePath.closeSubpath()
        gc.fill(corePath, with: .color(baseColor.opacity(0.95)))

        if hasSparkle {
            drawSparkle(gc: gc, center: center, radius: radius, time: time)
        }
    }

    private func drawArm(gc: GraphicsContext, center: CGPoint, radius: CGFloat, angle: Double, layers: Int, color: Color, deepColor: Color) {
        let dx = CGFloat(cos(angle))
        let dy = CGFloat(sin(angle))
        let tip = CGPoint(x: center.x + dx * radius, y: center.y + dy * radius)

        var mainPath = Path()
        mainPath.move(to: center)
        mainPath.addLine(to: tip)
        gc.stroke(mainPath, with: .color(color), lineWidth: 4)

        guard layers > 0 else { return }

        // Branches perpendicular to the main arm, spaced along its length,
        // one pair per layer, growing shorter toward the tip.
        let perpAngle = angle + .pi / 2
        let pdx = CGFloat(cos(perpAngle))
        let pdy = CGFloat(sin(perpAngle))

        for layer in 1...layers {
            let t = CGFloat(layer) / CGFloat(layers + 1)
            let basePoint = CGPoint(x: center.x + dx * radius * t, y: center.y + dy * radius * t)
            let branchLength = radius * 0.32 * (1 - t * 0.4)

            for sign: CGFloat in [-1, 1] {
                let branchAngle = angle + (.pi / 3.4) * Double(sign)
                let bdx = CGFloat(cos(branchAngle))
                let bdy = CGFloat(sin(branchAngle))
                let branchTip = CGPoint(x: basePoint.x + bdx * branchLength, y: basePoint.y + bdy * branchLength)
                var branchPath = Path()
                branchPath.move(to: basePoint)
                branchPath.addLine(to: branchTip)
                gc.stroke(branchPath, with: .color(deepColor.opacity(0.85)), lineWidth: max(1, 3 - CGFloat(layer) * 0.4))
            }
            _ = (pdx, pdy)
        }
    }

    private func drawSparkle(gc: GraphicsContext, center: CGPoint, radius: CGFloat, time: Double) {
        let sparkleCount = 6
        for i in 0..<sparkleCount {
            let phase = time * 1.3 + Double(i) * (2 * .pi / Double(sparkleCount))
            let pulsing = (CGFloat(sin(phase)) + 1) / 2
            let dist = radius * (0.35 + 0.5 * CGFloat(i % 3) / 2)
            let angle = Double(i) / Double(sparkleCount) * 2 * .pi
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * dist, y: center.y + CGFloat(sin(angle)) * dist)
            let size = 3 + pulsing * 3
            let rect = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
            gc.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.4 + pulsing * 0.5)))
        }
    }

    private func drawShatter(gc: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Simple crack lines radiating outward with a gap, suggesting breakage.
        let crackCount = 8
        for i in 0..<crackCount {
            let angle = (Double(i) / Double(crackCount)) * 2 * .pi
            let dx = CGFloat(cos(angle))
            let dy = CGFloat(sin(angle))
            let start = CGPoint(x: center.x + dx * radius * 0.2, y: center.y + dy * radius * 0.2)
            let end = CGPoint(x: center.x + dx * radius * 0.9, y: center.y + dy * radius * 0.9)
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            gc.stroke(path, with: .color(FrostTheme.danger.opacity(0.7)), lineWidth: 2)
        }
    }
}

#Preview {
    ZStack {
        FrostTheme.backdrop.ignoresSafeArea()
        IceCrystalView(streak: 45)
            .frame(width: 240, height: 240)
    }
}
