import SwiftUI

/// Places views left to right and wraps to a new row when a row is full.
struct FlowLayout: Layout {
    var spacing: Double = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(in: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(in: bounds.width, subviews: subviews) {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
                    proposal: .unspecified
                )
            }
        }
    }

    private struct Row {
        var items: [(index: Int, x: Double)] = []
        var y = 0.0
        var width = 0.0
        var height = 0.0
    }

    private func arrange(in maxWidth: Double, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        var x = 0.0
        var y = 0.0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                rows.append(row)
                y += row.height + spacing
                row = Row()
                row.y = y
                x = 0
            }
            row.items.append((index, x))
            row.y = y
            row.width = x + size.width
            row.height = max(row.height, size.height)
            x += size.width + spacing
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}
