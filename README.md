# 📦 Price Catalog App

A comprehensive **Flutter e-commerce platform** for B2B price catalog management, trader registration, and purchase order (PO) workflows. Admins manage products, catalogs, and pricing while traders browse catalogs and submit purchase requirements.

---

## 🎯 Key Features

### **Admin Features**
- ✅ Product catalog management (create, edit, delete products)
- ✅ Upload multiple catalogs & technical drawings (PDF support)
- ✅ Category & subcategory management
- ✅ Dynamic pricing with price history tracking
- ✅ Product images & specifications
- ✅ Trader approval & status management
- ✅ Purchase order review & counter-offer workflow
- ✅ Real-time notifications for trader activities

### **Trader Features**
- ✅ Browse product catalog with search & filtering
- ✅ View product details, specifications, and price history
- ✅ Download catalogs & technical drawings
- ✅ Add products to cart & create purchase orders (PO)
- ✅ Submit multi-product requirements with quantity & custom prices
- ✅ Respond to counter-offers from admin
- ✅ Track order status (pending, approved, rejected, counter-offer)
- ✅ Share products & catalogs via WhatsApp, email, etc.
- ✅ Profile management with company details

### **Core Features**
- 🔐 Role-based authentication (Admin/Trader)
- 📱 Responsive Material Design UI
- 🔔 Real-time notifications system
- 📊 Purchase order workflow with item-level approvals
- 💾 Cloud Firestore database integration
- ☁️ Firebase Storage for file management
- 🎨 Dynamic theming & animations

---

## 🏗️ Architecture

### **Clean Architecture Layers**

```
lib/
├── core/                  # Core utilities & constants
│   ├── constants/        # App-wide constants
│   ├── errors/           # Error handling
│   ├── services/         # Firebase, notification services
│   ├── theme/            # Color schemes, typography
│   └── utils/            # Helper functions
│
├── data/                  # Data layer (Firestore & Storage)
│   ├── datasources/       # Remote data sources
│   ├── models/            # Data models with serialization
│   └── repositories/      # Repository implementations
│
├── features/              # Feature modules (business logic)
│   ├── admin/            # Admin dashboard & product management
│   ├── auth/             # Authentication & registration
│   ├── splash/           # Splash screen
│   └── trader/           # Trader dashboard, catalog, cart, orders
│
├── providers/            # Riverpod state management
├── router/               # Route definitions (go_router)
├── shared/               # Shared widgets & dialogs
└── main.dart             # App entry point
```

---

## 🛠️ Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Framework** | Flutter | Latest |
| **Language** | Dart | 3.11.0+ |
| **State Management** | flutter_riverpod | 3.3.2 |
| **Database** | Cloud Firestore | 6.6.0 |
| **Storage** | Firebase Storage | 13.4.3 |
| **Routing** | go_router | 17.3.0 |
| **File Picking** | file_picker | 8.1.4 |
| **Sharing** | share_plus | 13.2.0 |
| **Image Caching** | cached_network_image | 3.4.1 |
| **UI/UX** | flutter_screenutil, flutter_animate | Latest |
| **Analytics** | Firebase Analytics | Latest |

---

## 📊 Database Structure

### **Collections**

#### 1. **users** - User profiles & account info
```dart
{
  uid: "user-123",
  name: "John Trader",
  email: "john@example.com",
  role: "trader",  // "admin" or "trader"
  traderStatus: "approved",  // "pending", "approved", "rejected"
  phone: "+923001234567",
  city: "Karachi",
  profileImage: "url-to-image",
  fcmToken: "notification-token",
  lastLogin: Timestamp,
  createdAt: Timestamp
}
```

#### 2. **products** - Product catalog
```dart
{
  id: "prod-001",
  name: "Steel Coil",
  category: "category-123",
  subcategory: "subcategory-456",
  brand: "XYZ Steel",
  code: "SC-001",
  description: "High-quality steel coil",
  images: ["url1", "url2"],
  prices: {
    "wholesale": 1000,
    "retail": 1500,
    "special": 900
  },
  specifications: {"thickness": "2mm", "width": "1200mm"},
  availability: "In Stock",
  catalogUrls: ["catalog1.pdf", "catalog2.pdf"],  // Multiple catalogs
  drawingUrls: ["drawing1.pdf"],  // Technical drawings
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### 3. **categories** - Product categories
```dart
{
  id: "cat-001",
  name: "Steel & Iron",
  description: "Steel products",
  icon: "url-to-icon",
  subcategories: ["subcat-001", "subcat-002"],
  createdAt: Timestamp
}
```

#### 4. **requirements** - Single/Multi-product purchase requests
```dart
{
  id: "req-001",
  traderId: "user-123",
  productId: "prod-001",  // For single product (deprecated, use items)
  items: [  // For multiple products (current standard)
    {
      productId: "prod-001",
      quantity: 10,
      requestedPrice: 950,
      status: "pending",  // "pending", "approved", "rejected", "counterOffer"
      counterPrice: null
    }
  ],
  status: "pending",  // Overall requirement status
  requiresAdminConfirmation: false,
  adminNote: "Need approval",
  createdAt: Timestamp,
  actionTakenAt: Timestamp
}
```

#### 5. **orders** - Multi-product purchase orders (PO)
```dart
{
  id: "order-001",
  traderId: "user-123",
  items: [
    {
      productId: "prod-001",
      quantity: 10,
      requestedPrice: 950,
      itemStatus: "pending",  // "pending", "approved", "rejected", "counterOffer"
      counterPrice: null
    }
  ],
  orderStatus: "pending",  // "pending", "approved", "rejected", "partiallyApproved"
  approvedCount: 1,
  rejectedCount: 0,
  counterCount: 1,
  pendingCount: 1,
  approvedOrderValue: 15000,
  adminNote: "Processing PO",
  createdAt: Timestamp,
  lastActionAt: Timestamp
}
```

#### 6. **price_history** - Price tracking for products
```dart
{
  productId: "prod-001",
  historyId: "hist-001",
  prices: {
    "wholesale": 1000,
    "retail": 1500
  },
  changeReason: "Market rate update",
  changedBy: "admin-uid",
  changedAt: Timestamp
}
```

#### 7. **notifications** - User notifications
```dart
{
  userId: "user-123",
  notificationId: "notif-001",
  title: "PO Approved",
  message: "Your PO #123 has been approved",
  type: "order_approved",  // "order_approved", "status_change", "new_product"
  referenceId: "order-001",
  read: false,
  createdAt: Timestamp
}
```

#### 8. **app_settings** - Admin configuration
```dart
{
  id: "settings",
  appName: "Price Catalog",
  appVersion: "1.0.0",
  maintenanceMode: false,
  supportEmail: "support@example.com",
  contactPhone: "+923001234567"
}
```

---

## 🔐 Security & User Roles

### **Role-Based Access Control (RBAC)**

| Action | Admin | Approved Trader | Pending Trader | Not Authenticated |
|--------|-------|-----------------|---|---|
| View Products | ✅ | ✅ | ❌ | ❌ |
| Manage Products | ✅ | ❌ | ❌ | ❌ |
| Create PO | ✅ | ✅ | ❌ | ❌ |
| Approve Orders | ✅ | ❌ | ❌ | ❌ |
| View Own Profile | ✅ | ✅ | ✅ | ❌ |
| View All Users | ✅ | ❌ | ❌ | ❌ |

### **Firebase Security Rules**

#### Firestore Rules (`firestore.rules`)
- ✅ Users can only read their own profile (traders) or all profiles (admins)
- ✅ Only admins can create/edit/delete products with validation
- ✅ Products have optional `catalogUrls` and `drawingUrls` arrays
- ✅ Traders can only create orders for themselves
- ✅ Admin approval workflow for orders with counter-offer support
- ✅ Notifications are user-specific and secure

#### Storage Rules (`storage.rules`)
- ✅ Product Images: `products/{id}/images/` - Admin upload, all users read
- ✅ **Product Catalogs (PDF)**: `products/{id}/catalogs/` - Admin upload, max 50MB, all users read
- ✅ **Product Drawings (PDF)**: `products/{id}/drawings/` - Admin upload, max 50MB, all users read
- ✅ User Profiles: `users/{id}/` - User + admin upload, all users read
- ✅ Trader Catalogs: `traders/{id}/catalog/` - Trader + admin upload
- ✅ Order/Requirement Attachments: Support for images & PDFs

---

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK (latest version)
- Dart 3.11.0+
- Firebase Project setup
- Android Studio / Xcode for mobile development

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/shivatechdigital/price_catalog_app.git
   cd price_catalog_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   ```bash
   # Download your google-services.json (Android) and GoogleService-Info.plist (iOS)
   # Place them in: android/app/ and ios/Runner/ respectively
   
   # Or use FlutterFire CLI:
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### **Build for Release**

**Android:**
```bash
flutter build apk --release
# or
flutter build appbundle --release  # For Google Play
```

**iOS:**
```bash
flutter build ios --release
```

---

## 📁 Key Files Overview

| File | Purpose |
|------|---------|
| `lib/main.dart` | App initialization, Firebase setup, routing |
| `lib/providers/` | State management (Riverpod providers) |
| `lib/data/models/product_model.dart` | Product data model with catalog/drawing URLs |
| `lib/data/repositories/product_repository.dart` | Database & storage operations |
| `lib/features/admin/` | Admin dashboard & product management |
| `lib/features/trader/` | Trader catalog, cart, PO workflow |
| `firestore.rules` | Firestore security & validation rules |
| `storage.rules` | Firebase Storage access control |
| `pubspec.yaml` | Project dependencies |

---

## 📋 Workflow Examples

### **Admin: Upload Product with Catalogs**
1. Admin goes to Product Management → Add Product
2. Fill product details (name, category, pricing)
3. Step 4: Upload catalogs (PDF) and drawings (PDF)
4. Save → Files auto-upload to Firebase Storage
5. Product appears in trader catalog with download links

### **Trader: Create Purchase Order**
1. Trader browses catalog → Search/filter products
2. Click (+) button to add product to cart
3. Click "Create PO" → Multi-step checkout
4. Enter quantity, negotiated price, delivery location
5. Submit → Admin receives notification
6. Admin can approve, reject, or send counter-offer
7. Trader responds to counter-offer or order completes

### **Admin: Manage Orders**
1. Admin Dashboard → Purchase Orders
2. View pending orders with trader details
3. Approve/reject individual items (item-level granularity)
4. Send counter-offer with new price
5. Track approval stats (approved/rejected/pending/counter)

---

## 🔄 Purchase Order Workflow

```
Trader Submits PO
    ↓
Admin Receives Notification
    ↓
Admin Reviews Items
    ├─ Approve ✅ → Order Approved
    ├─ Reject ❌ → Trader Notified
    └─ Counter-Offer 💰 → Trader Responds
         ├─ Accept ✅ → Order Approved
         └─ Reject ❌ → Order Cancelled
```

---

## 🐛 Troubleshooting

### **Firebase Connection Issues**
- Verify `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct directories
- Check Firebase project settings match your app package name
- Ensure Firebase Firestore and Storage are enabled in Firebase Console

### **File Upload Fails**
- Check PDF file size (max 50MB per storage rules)
- Verify admin is logged in (required for uploads)
- Check Firebase Storage quota in Firebase Console

### **Notifications Not Working**
- Ensure FCM token is saved after login
- Check notification settings in app settings (admin panel)
- Verify Firebase Cloud Messaging is enabled

### **Orders Not Appearing**
- Clear app cache and restart
- Verify trader status is "approved" in Firestore
- Check Firestore security rules are properly deployed

---

## 📈 Future Enhancements

- [ ] Invoice generation & export
- [ ] Payment gateway integration (Stripe, JazzCash)
- [ ] Bulk import products via CSV
- [ ] Advanced analytics dashboard for admin
- [ ] Mobile app for trader order tracking
- [ ] Supplier integration for auto-pricing
- [ ] Multi-language support (Urdu, English)
- [ ] Wishlist feature for traders

---

## 📞 Support & Contact

For questions or support:
- 📧 Email: support@example.com
- 📱 WhatsApp: +923001234567
- 🐛 Report Issues: GitHub Issues

---

## 📄 License

This project is proprietary software. All rights reserved.

---

## 👨‍💻 Developer Info

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore + Storage + Auth)
- **State Management**: Riverpod
- **Architecture**: Clean Architecture with MVVM pattern

### **Last Updated**: July 2026
### **Version**: 1.0.0

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)

---

**Happy Coding! 🚀**
