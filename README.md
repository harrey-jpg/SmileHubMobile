# SmileHub Flutter App

A complete, clickable Flutter version of the SmileHub dental supplies mobile UI.

## Included

- Onboarding, Login, and Sign Up
- Scrollable Home screen
- 32-product catalog with search and category filters
- Product details, quantity selector, wishlist, and cart
- Coupon, checkout, shipping address, and payment method flows
- Order success and account/orders
- Personal information, saved addresses, payment methods
- Help and contact support
- Working light/dark mode toggle
- Responsive mobile layout that also runs on Flutter Web

## Run on Windows

1. Install Flutter and Android Studio or Chrome.
2. Extract this folder.
3. Open the folder in VS Code or Android Studio.
4. Open Terminal in the project folder.
5. Run:

```bash
flutter create . --platforms=android,web
flutter pub get
flutter run
```

For Chrome:

```bash
flutter run -d chrome
```

You can also double-click `RUN_WEB.bat` or `RUN_ANDROID.bat`.

## Main app code

All source code is inside `lib/`. The project intentionally uses only Flutter SDK widgets, so no third-party state-management or routing package is required.
