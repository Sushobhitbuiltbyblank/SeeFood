# SeeFood - AI-Powered Food Recognition & Nutrition Tracking

SeeFood is an iOS app that uses Google's Gemini AI to analyze food images and provide nutritional information. Simply take a photo of your food, and the app will identify the items and their nutritional content.

## Project Demo
The following GIF showcases the core functionality of the project:

![Demo of functionality](https://raw.githubusercontent.com/Sushobhitbuiltbyblank/SeeFood/93aa253fa58c49ad7c76910c8594cbd57cb59a74/ScreenRecording_05-29-202500-00-30_111-ezgif.com-resize.gif)

## Features

- 📸 Take photos of food or select from photo library
- 🤖 AI-powered food recognition using Gemini Vision API
- 📊 Detailed nutritional breakdown (calories, protein, carbs, fats)
- 📅 Daily meal logging and tracking
- 📈 Nutritional summaries and trends

## Setup

### 1. Google Cloud Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Enable the Gemini API:
   - Navigate to "APIs & Services" → "Library"
   - Search for "Gemini API"
   - Click "Enable"
4. Create API credentials:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "API key"
   - Copy the generated API key
5. Restrict the API key (recommended):
   - Click the edit (pencil) icon next to your API key
   - Under "API restrictions", choose "Restrict key"
   - Select "Google Generative Language API"
   - Click "Save"

### 2. Project Setup

1. Clone the repository
2. Open `SeeFood.xcodeproj` in Xcode
3. Set up the API key in Xcode:
   - Click on your project in the navigator
   - Select your target
   - Click "Edit Scheme" (Product → Scheme → Edit Scheme)
   - Select "Run" from the left sidebar
   - Click on "Arguments" tab
   - Under "Environment Variables", add:
     - Name: `GEMINI_API_KEY`
     - Value: Your API key from Google Cloud Console
4. Build and run the project

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Google Cloud API key with Gemini Vision API enabled

## Usage

1. Open the app and tap the "Capture" tab
2. Take a photo of your food or select from your photo library
3. Wait for the AI analysis
4. Review the nutritional information
5. The meal will be automatically logged in your daily summary
6. View your daily logs in the "Daily Log" tab

## Security Note

The app uses secure storage (Keychain) for the API key in production. In development, it uses environment variables for easier debugging.

## Privacy

The app requires camera and photo library access to function. All image processing is done through Google's secure API endpoints. No images are stored permanently unless explicitly saved to your daily log.

## Contributing

Feel free to submit issues and enhancement requests! 
