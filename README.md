# SmileHub Mobile (Flutter)

Flutter companion app for **SmileHub Dental Supplies**, connected to the same
Firebase project (`smilehub-ecommerce`) as the web store — accounts, products,
orders, carts, and wishlists are shared with the website.

## Features

- Onboarding, Login, and Sign Up (Firebase Auth)
- Home screen and product catalog with search and category filters
- Product details, quantity selector, wishlist, and cart
- Coupon, checkout, shipping address, and payment method flows
- Order success and account/orders
- Personal information, saved addresses, payment methods
- Help and contact support
- Light/dark mode toggle
- Runs on Android and Flutter Web

## Firebase setup

This app is bound to the `smilehub-ecommerce` Firebase project:

- `lib/firebase_options.dart` — web + Android options
- `android/app/google-services.json` — Android config (package: `com.smilehub.mobile`)
- Android application ID / namespace: `com.smilehub.mobile`

If the Firebase config ever needs regenerating, run `flutterfire configure`.

## Run

Requires Flutter installed. From this folder:

```bash
flutter pub get
flutter run                # Android device or emulator
flutter run -d chrome      # Web
```

You can also double-click `RUN_WEB.bat` or `RUN_ANDROID.bat`.

## Project structure

```
lib/
  main.dart            App entry point (Firebase initialization)
  app.dart             Root widget and theme wiring
  routes.dart          Named routes
  firebase_options.dart
  data/                Static fallback data
  models/              Product model
  screens/             All app screens
  services/            Auth, orders, addresses, profile services
  state/               Shared app state
  theme/               Light/dark themes
  widgets/             Reusable widgets
```
