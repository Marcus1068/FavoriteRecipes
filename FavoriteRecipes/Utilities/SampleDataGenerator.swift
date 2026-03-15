import Foundation
import SwiftData
import UIKit

/// Generates a set of 12 sample recipes using images from the asset catalog.
/// The user can correct names, categories, and ingredient text afterwards.
enum SampleDataGenerator {

    struct SampleRecipe {
        let name: String
        let category: RecipeCategory
        let imageName: String   // Asset catalog name
        let ingredients: String
    }

    static let samples: [SampleRecipe] = [
        SampleRecipe(
            name: "Spaghetti Carbonara",
            category: .noodles,
            imageName: "sample_carbonara",
            ingredients: """
            400 g spaghetti
            200 g pancetta or guanciale, diced
            4 large eggs
            100 g Pecorino Romano, finely grated
            50 g Parmesan, finely grated
            2 cloves garlic
            Salt and black pepper to taste
            """
        ),
        SampleRecipe(
            name: "Grilled Ribeye Steak",
            category: .meat,
            imageName: "sample_steak",
            ingredients: """
            2 ribeye steaks (about 300 g each)
            2 tbsp olive oil
            4 cloves garlic, crushed
            3 sprigs fresh rosemary
            2 tbsp unsalted butter
            Salt and coarse black pepper
            """
        ),
        SampleRecipe(
            name: "Salmon with Lemon Butter",
            category: .fish,
            imageName: "sample_salmon",
            ingredients: """
            4 salmon fillets (150 g each)
            3 tbsp butter
            2 lemons, juiced and zested
            3 cloves garlic, minced
            2 tbsp fresh dill, chopped
            Salt and pepper to taste
            """
        ),
        SampleRecipe(
            name: "Caesar Salad",
            category: .vegetarian,
            imageName: "sample_caesar_salad",
            ingredients: """
            1 large romaine lettuce, chopped
            80 g Parmesan, shaved
            100 g croutons
            — Dressing —
            3 tbsp mayonnaise
            1 tbsp Dijon mustard
            2 tsp Worcestershire sauce
            1 clove garlic, minced
            Juice of 1 lemon
            Salt and pepper
            """
        ),
        SampleRecipe(
            name: "Vegan Buddha Bowl",
            category: .vegan,
            imageName: "sample_buddha_bowl",
            ingredients: """
            200 g cooked brown rice
            1 can chickpeas, drained
            1 sweet potato, cubed and roasted
            1 avocado, sliced
            100 g red cabbage, shredded
            2 tbsp tahini
            1 tbsp lemon juice
            1 tsp turmeric
            Salt and pepper
            """
        ),
        SampleRecipe(
            name: "Chicken Tikka Masala",
            category: .meat,
            imageName: "sample_tikka_masala",
            ingredients: """
            600 g chicken breast, cubed
            400 ml coconut milk
            1 can crushed tomatoes
            1 onion, diced
            4 cloves garlic, minced
            1 tbsp fresh ginger
            2 tbsp tikka masala paste
            1 tsp garam masala
            Fresh coriander to serve
            Cooked basmati rice
            """
        ),
        SampleRecipe(
            name: "Vegetable Pad Thai",
            category: .noodles,
            imageName: "sample_pad_thai",
            ingredients: """
            200 g flat rice noodles
            2 eggs, beaten
            200 g firm tofu, cubed
            100 g bean sprouts
            3 spring onions, sliced
            3 tbsp soy sauce
            2 tbsp lime juice
            1 tbsp brown sugar
            2 tbsp peanut oil
            50 g roasted peanuts, crushed
            """
        ),
        SampleRecipe(
            name: "Margherita Pizza",
            category: .vegetarian,
            imageName: "sample_margherita",
            ingredients: """
            — Dough —
            500 g bread flour
            7 g dried yeast
            10 g salt
            325 ml warm water
            — Topping —
            200 ml passata
            250 g fresh mozzarella, torn
            Fresh basil leaves
            2 tbsp olive oil
            """
        ),
        SampleRecipe(
            name: "Beef Ramen",
            category: .noodles,
            imageName: "sample_beef_ramen",
            ingredients: """
            300 g ramen noodles
            400 g beef sirloin, thinly sliced
            1.5 L beef broth
            3 tbsp soy sauce
            1 tbsp miso paste
            2 soft-boiled eggs, halved
            100 g bok choy
            4 spring onions, sliced
            1 sheet nori
            1 tbsp sesame oil
            """
        ),
        SampleRecipe(
            name: "Grilled Sea Bass",
            category: .fish,
            imageName: "sample_sea_bass",
            ingredients: """
            2 whole sea bass, cleaned
            4 tbsp olive oil
            1 lemon, sliced
            4 cloves garlic, minced
            1 bunch fresh thyme
            1 bunch fresh parsley
            Salt and black pepper
            """
        ),
        SampleRecipe(
            name: "Quinoa Power Bowl",
            category: .vegan,
            imageName: "sample_quinoa_bowl",
            ingredients: """
            200 g cooked quinoa
            1 can black beans, drained
            1 red bell pepper, diced
            1 cucumber, diced
            1 avocado, sliced
            50 g pumpkin seeds
            — Dressing —
            2 tbsp olive oil
            1 tbsp apple cider vinegar
            1 tsp maple syrup
            Salt and cumin
            """
        ),
        SampleRecipe(
            name: "Mushroom Risotto",
            category: .vegetarian,
            imageName: "sample_mushroom_risotto",
            ingredients: """
            350 g Arborio rice
            300 g mixed mushrooms, sliced
            1 onion, finely diced
            3 cloves garlic, minced
            150 ml dry white wine
            1.2 L warm vegetable stock
            60 g Parmesan, grated
            2 tbsp butter
            Fresh thyme and parsley
            Salt and pepper
            """
        )
    ]

    /// Inserts all sample recipes into the given model context.
    /// Skips any recipe whose name already exists to avoid duplicates.
    @MainActor
    static func generate(in context: ModelContext) {
        // Fetch existing names to avoid duplicates
        let existing = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        let existingNames = Set(existing.map { $0.name })

        for sample in samples {
            guard !existingNames.contains(sample.name) else { continue }

            let recipe = Recipe(name: sample.name, category: sample.category)
            recipe.ingredientsType = .text
            recipe.ingredientsText = sample.ingredients

            // Load the asset-catalog image and cap it at 1 MB
            if let image = UIImage(named: sample.imageName) {
                recipe.recipeImageData = image.jpegDataFitting()
            }

            context.insert(recipe)
        }
    }
}
