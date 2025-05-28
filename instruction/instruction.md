# 📄 Product Requirements Document (PRD)

## 📌 Project Overview

**App Name**: Seefood
**Platform**: iOS
**Purpose**: Simplify calorie tracking by using Gemini AI multimodal models to identify food and nutritional values from pictures.
**Target Users**: Health-focused individuals, fitness users, diet-conscious users.

---

## 🌟 Features

### 1. Food Capture

* Users can tap a button to open the camera and take a picture of their meal.
* Option to upload from photo gallery.

### 2. Food Analysis (via Gemini Multimodal AI)

* The app sends the image to Gemini AI.
* The AI returns:

  * List of ingredients.
  * Calorie, protein, fat, carb breakdown per ingredient.
* Results are editable by the user.

### 3. Daily Calorie Log View

* Top of screen: Horizontal date picker.
* For selected date:

  * Shows total calorie intake.
  * List of meals/food entries logged.
  * Breakdown chart (e.g., carbs/protein/fats).

---

## ✅ Feature Requirements

### 1. Food Capture

**UI Requirements:**

* Button: `+` (Add Meal)
* Camera View: Full-screen with shutter button
* Optional: Button to upload from photo library

**Dependencies**:

* `UIImagePickerController` or `AVCaptureSession`
* `PhotoKit` for gallery uploads

**Variables:**

```swift
var capturedImage: UIImage?
```

---

### 2. Food Analysis (Gemini AI)

**Workflow**:

1. After image is captured → Send to Gemini multimodal endpoint.
2. Receive structured response with food breakdown.
3. Show results in a structured UI with editable fields.

**Dependencies**:

* Google Gemini API via REST call or SDK
* JSON response parser
* Editable UI components (e.g., `UITextField`, `Stepper`)

**Variables**:

```swift
var ingredients: [FoodItem] = []
```

**FoodItem model:**

```swift
struct FoodItem: Codable {
    let name: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
}
```

**API Call:**

```http
POST /analyzeFood
Host: gemini.googleapis.com
Authorization: Bearer <token>
Content-Type: multipart/form-data

Body:
  - image: binary (captured image)

Response:
{
  "ingredients": [
    { "name": "Pancakes", "calories": 230, "protein": 6, "carbs": 35, "fats": 7 },
    { "name": "Blueberries", "calories": 85, "protein": 1, "carbs": 21, "fats": 0 },
    ...
  ]
}
```

---

### 3. Daily History View

**UI Requirements**:

* Date selector (scrollable horizontally)
* Daily summary card
* List of logged meals for the date
* Chart showing protein/carb/fat

**Dependencies**:

* Local DB (Core Data or Realm)
* Charting library (e.g., `Charts` or `SwiftUI Charts`)

**Variables:**

```swift
struct DailyLog: Identifiable {
    let id: UUID
    let date: Date
    var totalCalories: Int
    var meals: [MealEntry]
}

struct MealEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    var items: [FoodItem]
}
```

**Sample UI Flow**:

```swift
var selectedDate: Date
var dailyLog: DailyLog
```

---

## 🧩 Data Models

### `FoodItem`

```swift
struct FoodItem: Codable, Identifiable {
    let id: UUID = UUID()
    let name: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
}
```

### `MealEntry`

```swift
struct MealEntry: Identifiable, Codable {
    let id: UUID = UUID()
    let timestamp: Date
    var items: [FoodItem]
}
```

### `DailyLog`

```swift
struct DailyLog: Codable {
    let date: Date
    var meals: [MealEntry]
}
```

---

## 🔗 API Contracts

### Endpoint: Analyze Food Image

**Request:**

```http
POST /analyzeFood
Authorization: Bearer <your-api-key>
Content-Type: multipart/form-data
Body:
  - image: binary/jpeg or png
```

**Response:**

```json
{
  "ingredients": [
    {
      "name": "Pancakes",
      "calories": 230,
      "protein": 6,
      "carbs": 35,
      "fats": 7
    },
    {
      "name": "Blueberries",
      "calories": 85,
      "protein": 1,
      "carbs": 21,
      "fats": 0
    }
  ]
}
```

---

## 📦 Dependencies

| Component       | Dependency                                 |
| --------------- | ------------------------------------------ |
| Camera access   | `AVFoundation` / `UIImagePickerController` |
| AI Model        | Gemini AI via Google Cloud Multimodal API  |
| Data storage    | `Core Data`                   |
| Chart display   | `Swift Charts` or `Charts`                 |
| HTTP Networking | `URLSession` or `Alamofire`                |
| JSON Parsing    | `Codable`                                  |

---

Would you like a visual wireframe mockup next or a Swift-based MVVM architecture breakdown for engineering execution?
