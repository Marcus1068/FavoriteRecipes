# FavoriteRecipes

A food recipe management app for **iPhone**, **iPad**, and **Mac** (via Mac Catalyst), built with SwiftUI and SwiftData.

---

## Features

| Feature | Details |
|---|---|
| **3D Carousel** | Swipe between recipes with a perspective-animated card carousel |
| **iCloud Sync** | All data stored with SwiftData and synced via CloudKit |
| **Recipe Photos** | Pick from your photo library or take a new picture |
| **Ingredients** | Photo, PDF file, or plain text — your choice |
| **Categories** | Meat · Noodles · Fish · Vegetarian · Vegan |
| **Category Filter** | Filter the carousel to a single category instantly |
| **Inspire Me** | Randomly proposes a recipe with one tap |
| **Favourites** | Long-press (iOS) or right-click (Mac) to mark favourites; shown in a dedicated strip |
| **Share** | Sends ingredient text to Mail, Messages, etc. — OCR extracts text from photos and PDFs |
| **Image Cap** | Imported images are automatically compressed to ≤ 1 MB |
| **Sample Data** | Generate 12 sample recipes from the Options tab |

---

## Requirements

| | Minimum |
|---|---|
| iOS / iPadOS | 17.0 |
| macOS (Catalyst) | 14.0 |
| Xcode | 16.0 |
| Swift | 5.10 |

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-handle>/FavoriteRecipes.git
   cd FavoriteRecipes
   ```

2. Open **FavoriteRecipes.xcodeproj** in Xcode.

3. Select your target device or simulator and press **⌘R**.

> **iCloud Sync** requires a provisioning profile with the CloudKit entitlement.  
> For local development without iCloud, the app automatically falls back to on-device storage.

---

## Project Structure

```
FavoriteRecipes/
├── Models/
│   ├── Recipe.swift            SwiftData @Model
│   └── Enums.swift             RecipeCategory, IngredientsType
├── Views/
│   ├── RecipesView.swift       Main screen (filter, carousel, favourites)
│   ├── CarouselView.swift      3D perspective carousel + drag gesture
│   ├── RecipeCardView.swift    Individual recipe card
│   ├── FavoritesSection.swift  Horizontal favourites strip
│   ├── RecipeDetailView.swift  Create / edit a recipe
│   ├── OptionsView.swift       Sample data generator, statistics
│   └── AboutView.swift         Placeholder
└── Utilities/
    ├── TextExtractor.swift     Vision OCR + PDFKit text extraction
    ├── ShareSheet.swift        UIActivityViewController wrapper
    ├── DocumentPicker.swift    PDF file picker
    ├── CameraPickerView.swift  Camera capture wrapper
    ├── ImageExtensions.swift   UIImage compression (≤ 1 MB)
    └── SampleDataGenerator.swift
```

---

## Architecture

- **SwiftData** with `@Model` and `@Query` for reactive data binding  
- **CloudKit** container (`iCloud.com.marcus.FavoriteRecipes`) for cross-device sync  
- **No third-party dependencies** — pure SwiftUI + Apple frameworks  
- Layout uses `frame(maxHeight: .infinity)` on the carousel so every UI element (Share, Edit, Inspire Me) is always visible on screen, from iPhone SE to Mac  
- Images always rendered as *blurred scaledToFill background + scaledToFit overlay* so the full photo is visible regardless of its aspect ratio

---

## License

Licensed under the **Apache License, Version 2.0** — see [LICENSE.md](LICENSE.md) for details.
