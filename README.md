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
- ✅ Security settings - Change password securely
- ✅ Export data functionality with date range filtering

### **Trader Features**
- ✅ Browse product catalog with search & filtering
- ✅ View product details, specifications, and price history
- ✅ Download catalogs & technical drawings
- ✅ Create purchase orders (PO) with multiple products
- ✅ Submit multi-product requirements with quantity & custom prices
- ✅ Respond to counter-offers from admin
- ✅ Track order status (pending, approved, rejected, counter-offer)
- ✅ Share products & catalogs via WhatsApp, email, etc.
- ✅ Profile management with company details
- ✅ Form validation before submission (mandatory fields check)
- ✅ Export requirements with custom date ranges

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

#### Storage Rules (`storage.rules`) - Enhanced Security
- ✅ **Product Images**: `products/{id}/images/` - Admin upload only, max 50MB, logged-in users read
- ✅ **Product Catalogs (PDF)**: `products/{id}/catalogs/` - Admin upload only, max 50MB, logged-in users read
- ✅ **Product Drawings (PDF)**: `products/{id}/drawings/` - Admin upload only, max 50MB, logged-in users read
- ✅ **User Profile Images**: `users/{id}/` - Self + admin upload, max 10MB, logged-in users read
- ✅ **Trader Catalogs**: `traders/{id}/catalog/` - Self + admin upload, images & PDFs, max 50MB
- ✅ **Requirement Attachments**: `requirements/{id}/` - Self + admin access only, images & PDFs, max 50MB
- ✅ **Order Attachments**: `orders/{id}/` - Self + admin access only, images & PDFs, max 50MB
- ✅ **Exports**: `exports/{id}/` - User-specific data exports, max 100MB
- ✅ **File Type Validation**: Strict MIME type checking with regex for PDFs
- ✅ **Default Deny**: All unlisted paths blocked (security best practice)

---

## ✅ Recent Improvements & Bug Fixes (v1.0.0)

### **Authentication & Profile**
- ✅ Fixed login flow race condition - splash screen now reactively watches auth state
- ✅ Fixed profile edit logout issue - users stay logged in when editing profile
- ✅ Added password change functionality with re-authentication

### **Product Management**
- ✅ Fixed PDF upload errors in product edit mode - catalogs & drawings now upload properly
- ✅ Added proper file size validation (max 50MB for PDFs, 10MB for images)
- ✅ Improved image display with CachedNetworkImage in trader home

### **Admin Features**
- ✅ Made category & trader stats dynamic on admin home (no more hardcoded values)
- ✅ Removed unimplemented "coming soon" menu items
- ✅ Added functional Security option for password management

### **Trader Features**
- ✅ Removed duplicate "+" cart button from product catalog (use top app bar only)
- ✅ Added mandatory field validation before requirement submission
- ✅ Product images now display properly in latest products section

### **Security & Storage**
- ✅ Enhanced Firestore rules with better permission checks
- ✅ Improved Storage rules with strict MIME type validation
- ✅ Added file size limits for all upload paths
- ✅ Added default deny rule for unlisted paths
- ✅ Better error handling for missing user documents

---

## 🔐 Security Best Practices Implemented

- ✅ Role-based access control (RBAC) on Firestore & Storage
- ✅ Only authenticated users can access resources
- ✅ File type validation (images: .jpg, .png; PDFs: strict checking)
- ✅ File size limits to prevent storage abuse
- ✅ User ownership verification for personal data
- ✅ Admin-only operations for product management
- ✅ Secure password re-authentication for profile changes
- ✅ Default deny for unspecified paths

---

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
3. Step 4: Upload catalogs (PDF) and drawings (PDF) - supports multiple files
4. Edit mode also supports adding new catalogs & drawings to existing products
5. Save → Files auto-upload to Firebase Storage
6. Product appears in trader catalog with download links
7. Images display properly with CachedNetworkImage for performance

### **Admin: Change Password**
1. Admin goes to Profile → Account Settings → Account → Change Password
2. Enter current password (must verify to proceed for security)
3. Enter new password (6+ characters, cannot match current)
4. Confirm password (must match exactly)
5. Submit → Auto-logout and prompt to re-login with new password
6. Enhanced security: Re-authentication required, no session continuation

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

### **Authentication & Login Issues**
- **Issue**: Login flow shows splash screen, then login page reappears
  - **Solution**: Cleared race condition in splash_screen.dart - now uses `ref.watch()` for reactive state management
- **Issue**: User logged out after profile edit
  - **Solution**: updateProfile() now restores previous auth state instead of logging out on error
- **Issue**: Password change doesn't work
  - **Solution**: Ensure current password is correct (re-authentication required)

### **Firebase Connection Issues**
- Verify `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct directories
- Check Firebase project settings match your app package name
- Ensure Firebase Firestore and Storage are enabled in Firebase Console
- Verify security rules are properly deployed (use Firebase Console → Rules tab)

### **File Upload Fails**
- **PDF upload error**: Check file size (max 50MB per storage rules)
- **Image upload fails**: Verify file size (max 10MB for profiles, 50MB for others)
- **"Unable to update product"**: Ensure admin is logged in and has upload permissions
- **Check file MIME type**: PDFs must be `application/pdf` or `application/x-pdf`
- Check Firebase Storage quota in Firebase Console

### **Notifications Not Working**
- Ensure FCM token is saved after login
- Check notification settings in app settings (admin panel)
- Verify Firebase Cloud Messaging is enabled
- Check notification permissions are granted on device

### **Orders/Requirements Not Appearing**
- Clear app cache and restart: `flutter clean` then `flutter run`
- Verify trader status is "approved" in Firestore `users` collection
- Check Firestore security rules are properly deployed
- Verify auth token is valid (re-login if needed)

### **Images Not Loading**
- Check internet connection
- Verify image URL is correct in Firestore
- Clear app cache: Settings → App Storage → Clear Cache
- Check if using CachedNetworkImage with proper error handling

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
### **Version**: 1.0.0 - Production Ready
### **Status**: All 8 critical issues fixed ✅

**Recent Fixes (Latest)**:
- ✅ Login flow race condition resolved
- ✅ Profile edit logout issue fixed
- ✅ PDF upload functionality restored
- ✅ Dynamic admin stats implemented
- ✅ Security password change added
- ✅ Form validation improvements
- ✅ Image display fixes
- ✅ Firestore & Storage rules enhanced

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)

---

**Happy Coding! 🚀**
