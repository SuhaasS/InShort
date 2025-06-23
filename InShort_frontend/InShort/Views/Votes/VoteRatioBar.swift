import SwiftUI
import UIKit

/// A horizontal bar showing overall yes/no ratio with thumbs at each end and a center-point gradient.
struct VoteRatioBar: View {
    let votes: [StateVote]

    /// overall yes-vote ratio in [0,1], defaults to 0.5 if no votes
    private var yesRatio: Double {
        let totalYes = votes.reduce(0) { $0 + $1.yes }
        let totalNo  = votes.reduce(0) { $0 + $1.no  }
        let total    = totalYes + totalNo
        guard total > 0 else { return 0.5 }
        return Double(totalYes) / Double(total)
    }

    private var yesColor: Color {
        Color(UIColor(hex: "#82ca9d").withAlphaComponent(0.7))
    }
    private var noColor: Color {
        Color(UIColor(hex: "#8884d8").withAlphaComponent(0.7))
    }

    var body: some View {
        HStack(spacing: 8) {
            // thumbs-up at left
            Image(systemName: "hand.thumbsup.fill")
                .foregroundColor(yesColor)

            // gradient bar with movable cursor
            GeometryReader { geo in
                ZStack {
                    // gradient from yesColor → clear → clear → noColor
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: yesColor, location: 0),
                                    .init(color: yesColor.opacity(0), location: 0.5),
                                    .init(color: noColor.opacity(0), location: 0.5),
                                    .init(color: noColor, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)

                    // cursor indicator
                    Circle()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                        .position(
                            x: min(max(8, geo.size.width * yesRatio), geo.size.width - 8),
                            y: 8
                        )
                }
            }
            .frame(height: 16)

            // thumbs-down at right
            Image(systemName: "hand.thumbsdown.fill")
                .foregroundColor(noColor)
        }
        .frame(height: 24)
    }
}
