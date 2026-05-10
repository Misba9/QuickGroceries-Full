# Firestore Indexes — Dynamic Homepage

The new home pipeline (`lib/view/home/`) executes the following queries.
Most of them are single-field equality + `limit()`, which Firestore
auto-indexes — but a few need composite indexes the first time they run.
When a missing-index error fires in console, Firebase prints a one-click
URL to create it; this file is a checklist so you can pre-create them.

> Project console → **Firestore Database** → **Indexes** → **Composite**

## `products` collection

| Fields                                | Order | Used by                                         |
|---------------------------------------|-------|-------------------------------------------------|
| `isTrending`                          | =     | `HomeProductService.watchTrending`              |
| `isFeatured`                          | =     | `HomeProductService.watchFeatured`              |
| `special_cat`                         | =     | `HomeProductService.watchBySpecialCat` (legacy) |
| `product_index`                       | asc   | `HomeProductService.fetchExploreFirstPage`      |

> All four queries above use a single field — Firestore auto-creates the
> single-field index, **no manual setup needed**. They are listed here
> for awareness only.

### Optional composite indexes (recommended for scale)

If you want to filter the rails by availability server-side instead of
client-side (cheaper for large catalogs), create:

| Collection | Fields                                                 |
|------------|--------------------------------------------------------|
| `products` | `isTrending` (asc) + `isAvailable` (asc)               |
| `products` | `isFeatured` (asc) + `isAvailable` (asc)               |
| `products` | `special_cat` (asc) + `isAvailable` (asc)              |
| `products` | `product_index` (asc) + `isAvailable` (asc)            |

Then update the corresponding `where(...)` chain in
`lib/view/home/data/services/product_service.dart`.

## `categories` collection

| Fields  | Order | Used by                                       |
|---------|-------|-----------------------------------------------|
| `order` | asc   | `HomeCategoryService.watchActiveCategories`   |

Single-field index — auto-created.

### Optional

| Fields                              |
|-------------------------------------|
| `isActive` (asc) + `order` (asc)    |

Use this to filter inactive categories server-side.

## `banners` collection

| Fields     | Order | Used by                                  |
|------------|-------|------------------------------------------|
| `priority` | asc   | `HomeBannerService.watchActiveBanners`   |

Single-field — auto-created. The repository falls back gracefully when
legacy banner documents are missing the `priority` field.

## Schema reference (new fields)

These were added in Step 1 — Firestore is schemaless, so existing
documents without these fields keep working. Populate them from the
admin app to enable the new home rails.

```jsonc
// products/{id}
{
  "name": "string",
  "description": "string",
  "category": "string",          // legacy main category name
  "subcategory": "string",
  "categoryId": "string",         // (planned) reference to categories/{id}
  "images": ["url", "..."],
  "image": "url",                 // primary image
  "price": 99.0,
  "discountPrice": 79.0,          // alias of legacy `slashedPrice`
  "stock": 100,
  "rating": 4.5,
  "totalReviews": 120,
  "isTrending": true,             // drives "Trending Now" rail
  "isFeatured": true,             // drives "Featured For You" rail
  "isAvailable": true,            // soft availability flag
  "createdAt": Timestamp
}

// categories/{id}
{
  "name": "string",
  "image": "url",
  "order": 0,                     // sort order (asc)
  "isActive": true,
  "createdAt": Timestamp
}

// banners/{id}
{
  "image": "url",
  "video": "url",                 // optional
  "type": "image" | "video",
  "redirectType": "category" | "product" | "url" | "none",
  "redirectId": "string",         // category name / product id / URL
  "priority": 0,                  // sort order (asc)
  "isActive": true,
  "createdAt": Timestamp
}
```
