import SwiftUI
import SwiftData

/// A single recipe card for the main carousel.
///
/// Image display strategy
/// ──────────────────────
/// Every image — landscape OR portrait — is rendered as:
///   1. Blurred, darkened `scaledToFill` layer   → fills the card visually
///   2. Sharp `scaledToFit`   overlay            → shows the COMPLETE photo
///
/// Because `scaledToFit` never crops, the full food photo is always visible
/// regardless of its aspect ratio.  The bottom strip (Share / Edit) sits at
/// a hard-coded position at the bottom of the explicit `cardWidth × cardHeight`
/// frame, so it is *always* reachable.
///
/// Card dimensions are supplied by CarouselView, which derives them from the
/// space SwiftUI actually allocates to the carousel — no guessing, no GeometryReader
/// inside .background{}, no _ConditionalContent frame hacks.
struct RecipeCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe

    var cardWidth:  CGFloat = 300
    var cardHeight: CGFloat = 400
    var showContextMenu: Bool = true

    @State private var showDetail        = false
    @State private var isExtracting      = false
    @State private var favoriteAnimating = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            photoLayer
            favoritesBadge
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            bottomStrip
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .if(showContextMenu) { view in
            view.contextMenu {
                Button { toggleFavorite() } label: {
                    Label(
                        recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                    )
                }
                Button { showDetail = true } label: {
                    Label("Edit Recipe", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive) { modelContext.delete(recipe) } label: {
                    Label("Delete Recipe", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showDetail) { RecipeDetailView(recipe: recipe) }
    }

    // MARK: - Photo layer

    /// Blurred fill (visual interest) + sharp fit (full photo always visible).
    /// Both layers receive the explicit card frame — zero reliance on layout inference.
    @ViewBuilder
    private var photoLayer: some View {
        if let data = recipe.recipeImageData, let img = UIImage(data: data) {
            ZStack {
                // ① Blurred fill — hides letterbox bars for any aspect ratio
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                    .blur(radius: 22)
                    .saturation(0.70)
                    .brightness(-0.12)

                // ② Full image — always the complete photo, never cropped
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: cardWidth, height: cardHeight)
            }
            .frame(width: cardWidth, height: cardHeight)
        } else {
            // Gradient placeholder when no image is set
            LinearGradient(
                colors: [recipe.category.color.opacity(0.85),
                         recipe.category.color.opacity(0.40)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: cardWidth, height: cardHeight)
            .overlay {
                Text(recipe.category.icon)
                    .font(.system(size: 90))
                    .opacity(0.30)
                    .offset(x: 36, y: -36)
            }
        }
    }

    // MARK: - Favourite badge

    @ViewBuilder
    private var favoritesBadge: some View {
        if recipe.isFavorite {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.title3)
                .padding(9)
                .background(.ultraThinMaterial, in: Circle())
                .padding(12)
                .scaleEffect(favoriteAnimating ? 1.45 : 1.0)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Bottom strip (Share · Edit — always at the bottom of the card)

    private var bottomStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Label(recipe.category.rawValue, systemImage: "tag.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(recipe.name.isEmpty ? "Untitled Recipe" : recipe.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                Spacer()
                Text(recipe.category.icon)
                    .font(.system(size: 34))
            }

            HStack(spacing: 10) {
                // Share — eagerly extracts text (with progress indicator) then
                // presents the system share sheet via UIKit so the progress is
                // visible and Mac Catalyst works correctly.
                Button {
                    guard !isExtracting else { return }
                    isExtracting = true
                    Task {
                        let text = await TextExtractor.extract(from: recipe)
                        isExtracting = false
                        presentShareSheet(items: [text])
                    }
                } label: {
                    HStack(spacing: 5) {
                        if isExtracting {
                            ProgressView()
                                .scaleEffect(0.72)
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isExtracting ? "Extracting…" : "Share")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.white)
                    .opacity(isExtracting ? 0.75 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isExtracting)
                }
                .buttonStyle(.plain)

                Spacer()

                // Edit
                Button { showDetail = true } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .padding(9)
                        .background(.ultraThinMaterial, in: Circle())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.80)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Favourite toggle

    private func toggleFavorite() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            recipe.isFavorite.toggle()
            favoriteAnimating = true
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation { favoriteAnimating = false }
        }
    }
}

// MARK: - Conditional modifier helper

private extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Share Item

// MARK: - Previews

#Preview("Landscape 16:9") {
    let container = try! ModelContainer(for: Recipe.self,
                                        configurations: .init(isStoredInMemoryOnly: true))
    let ctx = ModelContext(container)
    let cW: CGFloat = 300, cH: CGFloat = 360

    let img = UIGraphicsImageRenderer(size: CGSize(width: 1920, height: 1080)).image { c in
        UIColor.systemBlue.setFill(); c.fill(CGRect(x:0,y:0,width:960,height:1080))
        UIColor.systemIndigo.setFill(); c.fill(CGRect(x:960,y:0,width:960,height:1080))
        "LANDSCAPE 16:9\nFull image always visible".draw(at: CGPoint(x:200,y:480),
            withAttributes: [.foregroundColor: UIColor.white,
                             .font: UIFont.boldSystemFont(ofSize: 55)])
    }
    let r = Recipe(name: "Salmon Pasta", category: .fish)
    r.recipeImageData = img.jpegData(compressionQuality: 0.9); ctx.insert(r)

    return ZStack {
        RecipeCardView(recipe: r, cardWidth: cW, cardHeight: cH, showContextMenu: false)
            .modelContext(ctx)
        RoundedRectangle(cornerRadius: 24).stroke(.red, lineWidth: 2)
            .frame(width: cW, height: cH)
    }
}

#Preview("Portrait 9:16") {
    let container = try! ModelContainer(for: Recipe.self,
                                        configurations: .init(isStoredInMemoryOnly: true))
    let ctx = ModelContext(container)
    let cW: CGFloat = 300, cH: CGFloat = 360

    let img = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1920)).image { c in
        UIColor.systemOrange.setFill(); c.fill(CGRect(x:0,y:0,width:1080,height:960))
        UIColor.systemRed.setFill(); c.fill(CGRect(x:0,y:960,width:1080,height:960))
        "PORTRAIT\n9:16\nFull image visible".draw(at: CGPoint(x:200,y:900),
            withAttributes: [.foregroundColor: UIColor.white,
                             .font: UIFont.boldSystemFont(ofSize: 80)])
    }
    let r = Recipe(name: "Beef Steak", category: .meat)
    r.recipeImageData = img.jpegData(compressionQuality: 0.9); ctx.insert(r)

    return ZStack {
        RecipeCardView(recipe: r, cardWidth: cW, cardHeight: cH, showContextMenu: false)
            .modelContext(ctx)
        RoundedRectangle(cornerRadius: 24).stroke(.red, lineWidth: 2)
            .frame(width: cW, height: cH)
    }
}
