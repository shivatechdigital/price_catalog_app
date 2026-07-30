# 📦 Price Catalog App

A comprehensive **Flutter B2B platform** for price catalog management, trader registration, document verification, and purchase order (PO) workflows. Admins manage products, catalogs, pricing, and reports while traders browse catalogs, submit requirements, and track their business performance.

---

## 🎯 Features

### 🔑 Admin Features

| Feature | Description |
|---|---|
| Product Management | Add, edit, delete products with multi-step form |
| Stock Quantity | Set stock per product; auto-deducts on order, restores on reject |
| Real-time Price Summary | Live price preview updates as admin types |
| Product Images | Up to 10 images; tap any to set as main cover photo |
| Technical Drawings | Upload PDF **and** image files (camera/gallery) |
| Product Catalogs | Upload multiple PDFs; view & share with eye/share icons |
| Category Management | Create categories with icons, subcategories |
| Dynamic Pricing | Price history tracking with change reasons |
| Trader Approval | Review trader registrations with document images (front/back) |
| Requirements Review | Approve, reject, or counter-offer per-item or full requirement |
| Reports & Analytics | Sales stats, monthly trends, top products, top traders; export PDF/Excel |
| Notifications | Real-time FCM push notifications |
| Security | Password change with re-authentication |
| Export | Requirements export as PDF or Excel with date range filters |

### 🛒 Trader Features

| Feature | Description |
|---|---|
| Product Catalog | Browse with search, category filters, grid/list toggle |
| Add to Cart | `+` button on every product card; proceed bar with item count |
| Stock Limit | Cannot enter quantity beyond available stock |
| PDF View & Share | Eye icon opens PDF; share icon downloads & shares actual file |
| Multi-product PO | Select multiple products, set qty & price, proceed to submit |
| Single PO | Create requirement from product detail screen |
| Counter-offer | Accept or reject admin counter-offers |
| Document Upload | Submit Aadhar/PAN front & back with native crop support |
| My Reports | Stats, monthly trend, top customers, top products; export PDF/Excel |
| Notifications | Receive approval/rejection/counter-offer alerts |
| Profile Management | Edit name, phone, city, business details |

### ⚙️ Core Features

- 🔐 Role-based authentication (Admin / Trader)
- 📱 Responsive Material Design with `flutter_screenutil`
- 🔔 Real-time push notifications via Firebase Cloud Messaging
- 💾 Cloud Firestore with live stream providers
- ☁️ Firebase Storage for images, PDFs, and documents
- 🎨 Smooth animations with `flutter_animate`
- 📤 Share files natively via `share_plus`

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/          # AppColors, app constants
│   ├── services/           # Firebase, PDF, Excel, Share, Notification services
│   ├── theme/              # Color schemes, typography
│   └── utils/              # Permission helper, etc.
│
├── data/
│   ├── models/             # ProductModel, UserModel, RequirementModel, etc.
│   └── repositories/       # ProductRepository, RequirementRepository
│
├── features/
│   ├── admin/
│   │   ├── dashboard/      # Admin home with stats
│   │   ├── products/       # Add/edit product (4-step form)
│   │   ├── requirements/   # Approve/reject/counter requirements
│   │   ├── traders/        # Trader management
│   │   ├── reports/        # Admin reports & analytics
│   │   ├── settings/       # App settings & export
│   │   └── profile/        # Admin profile
│   │
│   ├── auth/
│   │   ├── register_screen.dart      # 3-step trader registration
│   │   ├── login_screen.dart
│   │   ├── pending_approval_screen.dart
│   │   └── profile_edit_screen.dart
│   │
│   └── trader/
│       ├── catalog/        # Product catalog with cart (+) buttons
│       ├── dashboard/      # Trader home screen
│       ├── requirements/   # Submit & track requirements
│       ├── reports/        # Trader reports & analytics
│       └── profile/        # Trader profile
│
├── providers/              # Riverpod providers (auth, product, requirement, etc.)
├── router/                 # GoRouter route definitions
├── shared/                 # Reusable widgets (CustomButton, Snackbar, etc.)
└── main.dart
```

---

## 🛠️ Technology Stack

| Layer | Package | Version |
|-------|---------|---------|
| Framework | Flutter | Latest stable |
| Language | Dart | ^3.10.0 |
| State Management | flutter_riverpod | ^3.3.2 |
| Routing | go_router | ^17.3.0 |
| Database | cloud_firestore | ^6.6.0 |
| Auth | firebase_auth | ^6.5.4 |
| Storage | firebase_storage | ^13.4.3 |
| Notifications | firebase_messaging | ^16.4.1 |
| Images | cached_network_image | ^3.4.1 |
| Image Picking | image_picker | ^1.2.3 |
| Image Cropping | image_cropper | ^9.1.0 |
| File Picking | file_picker | ^8.1.4 |
| PDF Generation | pdf | ^3.12.0 |
| Excel Export | excel | ^4.0.6 |
| Sharing | share_plus | ^12.0.2 |
| URL Launch | url_launcher | ^6.3.2 |
| Open File | open_file | ^3.1.0 |
| Animations | flutter_animate | ^4.5.2 |
| Responsive UI | flutter_screenutil | ^5.9.3 |
| Photo Viewer | photo_view | ^0.15.0 |

---

## 📊 Database Schema

### `users` collection
```json
{
  "uid": "user-abc123",
  "name": "Rajesh Sharma",
  "email": "rajesh@example.com",
  "phone": "9876543210",
  "businessName": "Rajesh Hardware",
  "city": "Pune",
  "role": "trader",
  "traderStatus": "approved",
  "documentFrontUrl": "https://storage.../front.jpg",
  "documentBackUrl": "https://storage.../back.jpg",
  "profileImage": "https://storage.../profile.jpg",
  "fcmToken": "fcm-token",
  "gstNumber": "27ABCDE1234F1Z5",
  "createdAt": "Timestamp",
  "lastLogin": "Timestamp"
}
```

### `products` collection
```json
{
  "id": "prod-001",
  "name": "Electric Motor 2HP",
  "productCode": "EM-001",
  "categoryId": "cat-001",
  "categoryName": "Motor",
  "brand": "Valsal",
  "description": "High efficiency electric motor",
  "unit": "piece",
  "images": ["url1", "url2"],
  "availability": "inStock",
  "stockQuantity": 500,
  "currentPrice": {
    "purchasePrice": 2000,
    "sellingPrice": 3500,
    "dealerPrice": 3000,
    "minAcceptedPrice": 2800,
    "updatedAt": "Timestamp",
    "updatedBy": "admin-uid"
  },
  "catalogUrls": ["https://storage.../catalog1.pdf"],
  "drawingUrls": ["https://storage.../drawing1.jpg"],
  "specifications": { "Power": "2HP", "Voltage": "415V" },
  "tags": ["motor", "electric"],
  "viewCount": 42,
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### `requirements` collection
```json
{
  "id": "req-001",
  "traderId": "user-abc123",
  "traderName": "Rajesh Sharma",
  "traderBusinessName": "Rajesh Hardware",
  "items": [
    {
      "productId": "prod-001",
      "productName": "Electric Motor 2HP",
      "productCode": "EM-001",
      "quantity": 10,
      "unit": "piece",
      "productCurrentPrice": 3500,
      "customerDemandedPrice": 3200,
      "traderOfferedPrice": 3300,
      "itemStatus": "approved"
    }
  ],
  "customerName": "Mahesh Hardware Store",
  "customerPhone": "9123456789",
  "customerBusinessName": "Mahesh Hardware",
  "customerCity": "Mumbai",
  "paymentType": "fullCash",
  "status": "approved",
  "submittedAt": "Timestamp",
  "actionTakenAt": "Timestamp"
}
```

---

## 🔐 Security & Access Control

### Role-Based Access

| Action | Admin | Approved Trader | Pending Trader |
|--------|-------|-----------------|----------------|
| Manage Products | ✅ | ❌ | ❌ |
| View Catalog | ✅ | ✅ | ❌ |
| Submit Requirements | ✅ | ✅ | ❌ |
| Approve/Reject Orders | ✅ | ❌ | ❌ |
| View All Traders | ✅ | ❌ | ❌ |
| View All Reports | ✅ | ❌ | ❌ |
| View Own Reports | ✅ | ✅ | ❌ |

### Security Implemented
- ✅ Firebase Auth token verification on all requests
- ✅ Firestore security rules with role checks
- ✅ Storage rules: admin-only upload, authenticated-only read
- ✅ Re-authentication required for password change
- ✅ Stock quantity via `FieldValue.increment` (atomic, tamper-proof)
- ✅ Trader document images stored in `trader_documents/` (private path)

---

## 🔄 Key Workflows

### Stock Management Flow
```
Admin sets stockQuantity on product (e.g. 500 TON)
    ↓
Trader views product → validator shows max available
    ↓
Trader cannot enter qty > stockQuantity
    ↓
Trader submits requirement
    ↓
stockQuantity -= qty  (FieldValue.increment, atomic)
    ↓
Admin rejects requirement
    ↓
stockQuantity += qty  (automatically restored)
```

### Cart & Purchase Order Flow
```
Trader taps + on product card → added to cart
    ↓
Proceed bar shows "N products selected → Proceed"
    ↓
Tap Proceed → SubmitMultiRequirementScreen
    ↓
Fill customer details, quantity, offered price
    ↓
Submit → Stock deducted → Admin notified
    ↓
Admin reviews per-item:
    ├── Approve ✅  → Trader notified
    ├── Reject ❌   → Stock restored, trader notified
    └── Counter 💰  → Trader accepts or rejects
```

### Trader Registration Flow
```
Step 1: Basic Info (Name, Phone, City)
    ↓
Step 2: Account Setup (Email, Password, Terms)
    ↓
Step 3: Document Verification
        (ID Front + Back — Camera/Gallery with native crop)
    ↓
Account created → Status: Pending
    ↓
Admin sees document thumbnails → Reviews
    ↓
Admin approves → Trader can login
```

---

## 📈 Reports & Analytics

### Admin Reports (`Profile → Reports & Analytics`)
| Section | Details |
|---|---|
| Overview Stats | Total, Approved, Rejected, Pending, Counter, Products |
| Deal Value Card | Total approved requirement value with gradient |
| Monthly Trend | Bar chart — last 6 months |
| Top Products | Top 5 demanded products with progress bars |
| Top Traders | Top 5 active traders |
| Status Breakdown | Percentage bars for each status |
| Export PDF | Full report shared as PDF |
| Export Excel | Summary sheet + Requirements sheet |

### Trader Reports (`Profile → My Reports`)
| Section | Details |
|---|---|
| My Stats | Total, Approved, Rejected, Pending, Counter, Customers |
| My Deal Value | Approved requirements total value |
| Monthly Activity | Last 6 months requirements bar chart |
| Status Breakdown | My requirement distribution |
| Top Customers | Top 5 customers by order count |
| Top Products | Top 5 products I order most |
| Export PDF | My requirements as shareable PDF |
| Export Excel | My requirements as Excel file |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart ^3.10.0
- Android Studio / VS Code
- Firebase project (Firestore + Auth + Storage + FCM)

### Installation

```bash
# 1. Clone
git clone https://github.com/shivatechdigital/price_catalog_app.git
cd price_catalog_app

# 2. Install dependencies
flutter pub get

# 3. Add Firebase config files
# → android/app/google-services.json
# → ios/Runner/GoogleService-Info.plist

# 4. Run
flutter run
```

### Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🐛 Common Issues

| Issue | Solution |
|---|---|
| PDF not opening | Check internet; Firebase Storage URLs need auth |
| Stock not deducting | Set `stockQuantity` on product (null = unlimited) |
| Document upload fails | Check Firebase Storage rules for `trader_documents/` path |
| Image cropper not showing | Grant camera/storage permissions |
| Reports showing 0 | Check Firestore rules for `requirements` collection read access |
| Cart not clearing | `selectedRequirementItemsProvider` resets on `SelectProductsScreen` open |

---

## 📋 Changelog

### v1.2.0 — July 2026 (Latest)
- ✅ **Reports Dashboard** — Admin & Trader analytics with PDF/Excel export
- ✅ **Document Verification** — 3-step registration with ID front/back + native crop
- ✅ **Stock Management** — Set stock; auto-deduct on submit, restore on reject
- ✅ **Cart Feature** — `+` buttons on product cards with animated proceed bar
- ✅ **Main Image Selection** — Tap any product image to set as cover photo
- ✅ **Technical Drawing Images** — Now accepts PDF and image files (camera/gallery)
- ✅ **Image Limit Enforcement** — Max 10 images with gallery `limit` parameter
- ✅ **Real-time Price Summary** — Live preview in pricing step
- ✅ **PDF View & Share** — Actual file download & share (not just link)
- ✅ **Admin Document Review** — Document thumbnails in trader approval cards

### v1.1.0 — June 2026
- ✅ Multi-product requirements (bulk PO)
- ✅ Per-item approve/reject/counter
- ✅ Price history tracking
- ✅ Firebase FCM notifications
- ✅ Requirement export PDF/Excel

### v1.0.0 — May 2026
- ✅ Role-based auth (Admin/Trader)
- ✅ Product catalog with categories
- ✅ Single product requirements
- ✅ Admin trader approval workflow

---

## 📁 Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, Firebase init |
| `lib/data/models/product_model.dart` | ProductModel with `stockQuantity` |
| `lib/data/models/user_model.dart` | UserModel with `documentFrontUrl/BackUrl` |
| `lib/data/repositories/product_repository.dart` | CRUD + `adjustStockQuantity()` |
| `lib/data/repositories/requirement_repository.dart` | Submit (deduct) & Reject (restore) stock |
| `lib/features/admin/products/screens/add_product_screen.dart` | 4-step product form |
| `lib/features/admin/reports/screens/admin_reports_screen.dart` | Admin analytics |
| `lib/features/trader/catalog/screens/trader_catalog_screen.dart` | Cart `+` buttons |
| `lib/features/trader/catalog/screens/trader_product_detail_screen.dart` | PDF view/share |
| `lib/features/trader/reports/screens/trader_reports_screen.dart` | Trader analytics |
| `lib/features/auth/screens/register_screen.dart` | 3-step registration + doc upload |
| `firestore.rules` | Firestore security rules |
| `storage.rules` | Firebase Storage access rules |

---

## 👨‍💻 Developer Info

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore + Storage + Auth + FCM)
- **State Management**: Riverpod (StateNotifier + StreamProvider + StateProvider)
- **Architecture**: Feature-first Clean Architecture
- **Version**: 1.2.0
- **Last Updated**: July 2026

---

## 📚 Resources

- [Flutter Docs](https://docs.flutter.dev/)
- [Firebase Flutter](https://firebase.flutter.dev/)
- [Riverpod Docs](https://riverpod.dev/)
- [Go Router](https://pub.dev/packages/go_router)
- [image_cropper](https://pub.dev/packages/image_cropper)

---

**Built with ❤️ using Flutter & Firebase**
