import SwiftUI

/// A tappable xúc xắc (die) face with real pips (not a digit), matching the
/// standard 1-6 pip layouts.
struct DieView: View {
    let value: Int
    let isRollable: Bool
    let action: () -> Void

    private var pipPositions: [(CGFloat, CGFloat)] {
        switch value {
        case 1: return [(0.5, 0.5)]
        case 2: return [(0.26, 0.26), (0.74, 0.74)]
        case 3: return [(0.26, 0.26), (0.5, 0.5), (0.74, 0.74)]
        case 4: return [(0.26, 0.26), (0.74, 0.26), (0.26, 0.74), (0.74, 0.74)]
        case 5: return [(0.26, 0.26), (0.74, 0.26), (0.5, 0.5), (0.26, 0.74), (0.74, 0.74)]
        default: return [(0.26, 0.22), (0.74, 0.22), (0.26, 0.5), (0.74, 0.5), (0.26, 0.78), (0.74, 0.78)]
        }
    }

    var body: some View {
        Button(action: action) {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: geo.size.width * 0.18)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    ForEach(Array(pipPositions.enumerated()), id: \.offset) { _, p in
                        Circle()
                            .fill(Color.black)
                            .frame(width: geo.size.width * 0.16, height: geo.size.width * 0.16)
                            .position(x: p.0 * geo.size.width, y: p.1 * geo.size.height)
                    }
                }
            }
        }
        .disabled(!isRollable)
        .opacity(isRollable ? 1.0 : 0.5)
        .frame(width: 66, height: 66)
        .accessibilityLabel(Text("\(value)"))
    }
}

#Preview {
    DieView(value: 4, isRollable: true, action: {})
        .padding()
        .background(Color.black)
}
