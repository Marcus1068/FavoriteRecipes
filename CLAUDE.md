# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SwiftUI + SwiftData recipe app for iPhone, iPad and Mac (Mac Catalyst), synced via CloudKit (`iCloud.com.marcus.FavoriteRecipes`). No third-party dependencies. The project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so types are main-actor by default. Deployment target is iOS 26.2. `README.md` is partly outdated (deployment targets, project structure); trust the code.

## Commands

Schemes: `FavoriteRecipes` (app), `FavoriteRecipesShare` (share extension), `FavoriteRecipesWidgets` (timer Live Activity), `FavoriteRecipesUITests`.

```bash
xcodebuild -project FavoriteRecipes.xcodeproj -scheme FavoriteRecipes -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild ... test -only-testing:FavoriteRecipesTests/IngredientParserTests            # one test class
xcodebuild ... test -only-testing:FavoriteRecipesTests/IngredientParserTests/testName    # one test
swiftlint    # config in .swiftlint.yml; must be clean before committing
```

Prefer the Xcode MCP tools (`BuildProject`, `RunSomeTests`, `GetBuildLog`) when available. Unit tests are in `FavoriteRecipesTests`. UI tests are only for flows that can't be unit-tested.

## Architecture

- **Single `@Model`: `Recipe`** (`Models/`), extended by feature in `Recipe+*.swift` files (Cleanup, CookHistory, Copy, Sharing, Suggestion, Shopping). The schema is `Schema([Recipe.self])`, and the container is built by `ModelContainer.make` (`Utilities/ModelContainer+Setup.swift`), which falls back to an in-memory store as a last resort. Because of CloudKit, model properties need defaults or must be optional, relationships must be optional, and `@Attribute(.unique)` is not allowed.
- **Ingredients are structured** (`Ingredients/`): `IngredientParser` turns text into `Ingredient` values with `IngredientUnit`, which drives serving scaling, unit conversion (`UnitSystem`) and the shopping list.
- **App-wide state** is created in `FavoriteRecipesApp` as `@Observable` models and injected via `.environment`: `AppNavigation`, `UndoDeleteModel`, `ShoppingStore`, `TimerCenter`.
- **Navigation** (`Navigation/`): `AppNavigation.request(AppAction)` is the single entry point for deep links, keyboard shortcuts, App Intents and the share extension. Add new cross-cutting entry points as an `AppAction`, not ad hoc.
- **App Intents / Spotlight** (`AppIntents/`) share the same `ModelContainer` and `AppNavigation` through `AppDependencyManager` (registered in `FavoriteRecipesApp.init`).
- **Cooking mode** (`Cooking/`): `CookingParser` and `StepTimerParser` extract steps and timers. `TimerCenter` schedules them through the `TimerNotifying` and `TimerActivityManaging` protocols so tests can inject fakes. The Live Activity UI lives in `FavoriteRecipesWidgets`, and the shared `TimerActivityAttributes` is in `Shared/` (compiled into both targets).
- **Import / Exchange**: `Import/` handles web import (`RecipeWebImporter`, `SchemaRecipeParser` for schema.org JSON-LD). `Exchange/` handles the `.recipe` file format (`RecipeFile`, `UTType+Recipe`) for sharing. `FavoriteRecipesShare` is the share extension.
- **Assistant** (`Assistant/`): on-device recipe cleanup and suggestions.
- **Mac Catalyst** specifics: `MacSceneDelegate`, `MacWindowManager`, `KeyboardNavigationHandler`. Check these when changing windowing or shortcuts.

## Testing and UI-test mode

`Utilities/UITestSupport.swift` swaps in an isolated in-memory container, seeded defaults, a silent `TimerCenter` and a test `ShoppingStore` when the app is launched for UI tests. When adding app-level services, give them a UI-test variant there. `FavoriteRecipesTests/Support/SeededGenerator.swift` provides deterministic randomness.

## Conventions

- Localization uses the string catalogs (`Localizable.xcstrings`, `InfoPlist.xcstrings`, `AppShortcuts.xcstrings`) with symbol keys, accessed as `Text(.someKey)`.
- SwiftLint disables `colon` and `comma` on purpose, because the code aligns declarations in columns. Keep that alignment, and keep explicit `= nil` defaults on model properties.
