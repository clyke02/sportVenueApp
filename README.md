# SportVenue - Aplikasi Booking Venue Olahraga Bandung

<div align="center">
  <img src="assets/logo.png" alt="SportVenue Logo" width="200"/>
  
  **Aplikasi mobile untuk booking venue olahraga di Kota Bandung**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.24-blue.svg)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com/)
  [![Dart](https://img.shields.io/badge/Dart-3.5-blue.svg)](https://dart.dev/)
</div>

---

## 📋 Daftar Isi

- [Deskripsi](#-deskripsi)
- [Fitur Utama](#-fitur-utama)
- [Teknologi yang Digunakan](#-teknologi-yang-digunakan)
- [Database](#-database)
- [API & Layanan](#-api--layanan)
- [Alur Coding & Pengembangan](#-alur-coding--pengembangan)
- [Arsitektur Aplikasi](#-arsitektur-aplikasi)
- [Instalasi & Setup](#-instalasi--setup)
- [Cara Penggunaan](#-cara-penggunaan)
- [Struktur Project](#-struktur-project)
- [Kontribusi](#-kontribusi)

---

## 📝 Deskripsi

**SportVenue** adalah aplikasi mobile berbasis Flutter yang memungkinkan pengguna untuk mencari dan memesan venue olahraga di Kota Bandung. Aplikasi ini menggunakan data resmi sarana olahraga dari pemerintah dan menyediakan sistem booking yang terintegrasi dengan payment gateway.

---

## 🚀 Fitur Utama

### 🔐 **Autentikasi**

- Login/Register dengan Firebase Authentication
- Session persistence (tetap login setelah tutup app)
- Error handling yang user-friendly dalam Bahasa Indonesia

### 🏟️ **Manajemen Venue**

- Browse venue olahraga populer di Bandung
- Pencarian venue berdasarkan nama, lokasi, atau cabang olahraga
- Filter venue berdasarkan kategori olahraga
- Detail venue dengan rating, harga, dan informasi lengkap

### 📅 **Sistem Booking**

- Booking venue dengan pilihan tanggal dan waktu
- Manajemen booking (Upcoming & Past bookings)
- Status booking real-time (Pending, Confirmed, Cancelled, Completed)
- Notifikasi booking

### 💳 **Payment System**

- QR Code payment integration
- Multiple payment methods
- Payment status tracking
- Payment history

### 👤 **Profile Management**

- User profile management
- Booking history
- Account settings

---

## 🛠️ Teknologi yang Digunakan

### **Frontend**

- **Flutter 3.24+** - UI Framework
- **Dart 3.5+** - Programming Language
- **Provider** - State Management
- **Go Router** - Navigation

### **Backend & Database**

- **Firebase Core** - Backend as a Service
- **Firebase Authentication** - User Authentication
- **Cloud Firestore** - NoSQL Database (Primary)
- **Firebase Storage** - File Storage
- **SQLite** - Local Database (Legacy/Cache)

### **UI/UX Libraries**

- **Material Design 3** - Design System
- **Cupertino Icons** - iOS Style Icons
- **Flutter SVG** - SVG Support
- **Cached Network Image** - Image Caching

### **Utility Libraries**

- **QR Flutter** - QR Code Generation
- **UUID** - Unique ID Generation
- **Intl** - Internationalization
- **CSV** - CSV File Parsing
- **HTTP** - Network Requests

---

## 🗄️ Database

### **Primary Database: Cloud Firestore**

```
sportvenue-9686c (Firebase Project)
├── users/              # User profiles
├── venues/             # Venue data from CSV
├── bookings/           # Booking transactions
└── payments/           # Payment records
```

### **Database Schema:**

#### **Users Collection**

```javascript
{
  id: number,
  name: string,
  email: string,
  phone: string?,
  profileImageUrl: string?,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### **Venues Collection**

```javascript
{
  id: number,
  nama_prasarana_olahraga: string,
  alamat: string,
  cabang_olahraga: string,
  rating: number,
  price: number,
  luas_lahan: number,
  tahun: number,
  // ... data geografis lainnya
  keywords: array // untuk search functionality
}
```

#### **Bookings Collection**

```javascript
{
  id: string (Firestore doc ID),
  userId: string,
  venueId: number,
  bookingDate: timestamp,
  timeSlot: string,
  duration: number,
  totalPrice: number,
  status: number, // 0=pending, 1=confirmed, 2=cancelled, 3=completed
  notes: string?,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### **Payments Collection**

```javascript
{
  id: string,
  bookingId: string,
  amount: number,
  method: number,
  status: number,
  qr_code_data: string,
  transaction_id: string?,
  created_at: timestamp,
  expires_at: timestamp,
  completed_at: timestamp?
}
```

### **Legacy Database: SQLite**

- **File**: `sportvenue.db`
- **Location**: Application Documents Directory
- **Usage**: Local caching dan backup (sebagian besar digantikan Firestore)

---

## 🌐 API & Layanan

### **Firebase Services**

- **Authentication API**: Email/password authentication
- **Firestore API**: Real-time database operations
- **Storage API**: File upload/download

### **Mock Payment API**

```dart
// lib/services/payment_service.dart
class PaymentService {
  Future<PaymentResponse> processQRPayment(PaymentRequest request);
  Future<PaymentStatus> checkPaymentStatus(String paymentId);
}
```

### **Data Source**

- **CSV File**: `sarana_olahraga_di_kota_bandung_2.csv`
- **Source**: Data resmi sarana olahraga Kota Bandung
- **Import**: Otomatis ke Firestore saat first launch

---

## 🔄 Alur Coding & Pengembangan

### **Phase 1: Project Setup & Architecture**

```bash
1. flutter create sportvenue
2. Setup project structure (models, services, providers, screens)
3. Add dependencies (Firebase, Provider, etc.)
4. Configure Firebase project
5. Setup state management dengan Provider pattern
```

### **Phase 2: Data Layer Development**

```bash
1. Create data models (User, Venue, Booking, Payment)
2. Setup SQLite database helper (DatabaseHelper)
3. Implement CSV import service (CsvImportService)
4. Create Firestore service (FirestoreService)
5. Migrate from SQLite to Firestore
```

### **Phase 3: Authentication System**

```bash
1. Implement AuthProvider dengan Firebase Auth
2. Create login/register screens
3. Add session persistence
4. Implement error handling dengan pesan Bahasa Indonesia
```

### **Phase 4: UI Development**

```bash
1. Create splash screen dengan loading animation
2. Implement main navigation (BottomNavigationBar)
3. Build home screen dengan popular venues
4. Create search & filter functionality
5. Design venue detail screens
```

### **Phase 5: Booking System**

```bash
1. Implement booking flow (select date, time, duration)
2. Create BookingProvider untuk state management
3. Build booking management screens
4. Add booking status tracking
5. Integrate dengan venue data
```

### **Phase 6: Payment Integration**

```bash
1. Create payment models dan services
2. Implement QR code generation
3. Build payment screens
4. Add payment status tracking
5. Create mock payment API
```

### **Phase 7: Optimization & Polish**

```bash
1. Code optimization (lazy loading, caching)
2. Error handling improvements
3. UI/UX enhancements
4. Performance optimization
5. Testing & debugging
```

---

## 🏗️ Arsitektur Aplikasi

### **Pattern: MVVM + Provider**

```
├── Models/              # Data models
├── Views/               # UI Screens & Widgets
├── ViewModels/          # Providers (Business Logic)
├── Services/            # External API & Database
└── Utils/               # Helper functions
```

### **State Management Flow**

```
User Action → Provider → Service → Database/API
     ↓           ↓         ↓           ↓
   Widget ← notifyListeners() ← Response ← Data
```

### **Dependency Injection**

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => VenueProvider()),
    ChangeNotifierProvider(create: (_) => BookingProvider()),
  ],
  child: MyApp(),
)
```

---

## 📦 Instalasi & Setup

### **Prerequisites**

- Flutter SDK 3.24+
- Dart SDK 3.5+
- Android Studio / VS Code
- Firebase account

### **1. Clone Repository**

```bash
git clone https://github.com/username/sportvenue.git
cd sportvenue
```

### **2. Install Dependencies**

```bash
flutter pub get
```

### **3. Firebase Setup**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project
firebase init

# Download google-services.json ke android/app/
```

### **4. Configure Firebase**

- Buat Firebase project di console
- Enable Authentication (Email/Password)
- Setup Cloud Firestore
- Download `google-services.json` ke `android/app/`
- Add SHA-1 & SHA-256 fingerprints untuk Android

### **5. Run Application**

```bash
flutter run
```

---

## 📱 Cara Penggunaan

### **1. First Launch**

- App otomatis import data venue dari CSV ke Firestore
- Splash screen dengan loading animation
- Redirect ke login/register

### **2. Authentication**

```
Register → Input (Name, Email, Password) → Firebase Auth → Auto Login
Login → Input (Email, Password) → Firebase Auth → Main Screen
```

### **3. Browse Venues**

```
Home Screen → Popular Venues List
Search → Input query → Filter results
Category Filter → Select sport → Filtered venues
```

### **4. Booking Process**

```
Select Venue → Venue Detail → Book Now
Select Date & Time → Confirm Details → Create Booking
Payment → QR Code → Confirm Payment → Booking Confirmed
```

### **5. Manage Bookings**

```
Bookings Tab → Upcoming/Past Bookings
Booking Detail → View/Cancel/Pay
Payment Status → Track payment progress
```

### **6. User Profile**

```
Profile Tab → View/Edit Profile
Booking History → Past bookings
Settings → Account preferences
Logout → Clear session
```

---

## 📁 Struktur Project

```
sportvenue/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── models/                      # Data models
│   │   ├── user.dart
│   │   ├── venue.dart
│   │   ├── booking.dart
│   │   ├── payment.dart
│   │   └── sport_category.dart
│   ├── providers/                   # State management
│   │   ├── auth_provider.dart
│   │   ├── venue_provider.dart
│   │   └── booking_provider.dart
│   ├── services/                    # External services
│   │   ├── database_helper.dart
│   │   ├── firestore_service.dart
│   │   ├── csv_import_service.dart
│   │   └── payment_service.dart
│   ├── screens/                     # UI Screens
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── main_screen.dart
│   │   ├── home_screen.dart
│   │   ├── search_screen.dart
│   │   ├── bookings_screen.dart
│   │   ├── profile_screen.dart
│   │   └── venue_detail_screen.dart
│   ├── widgets/                     # Reusable widgets
│   │   └── venue_image_widget.dart
│   └── utils/                       # Helper functions
├── assets/
│   ├── data/
│   │   └── sarana_olahraga_di_kota_bandung_2.csv
│   └── images/
├── android/
│   └── app/
│       └── google-services.json    # Firebase config
├── pubspec.yaml                    # Dependencies
└── README.md                       # This file
```

---

## 🤝 Kontribusi

### **Development Guidelines**

1. Follow Flutter/Dart best practices
2. Use Provider pattern untuk state management
3. Implement proper error handling
4. Write meaningful commit messages
5. Test pada multiple devices

### **Code Style**

- Use `dart format` untuk formatting
- Follow effective Dart guidelines
- Add comments untuk complex logic
- Use meaningful variable names

### **Pull Request Process**

1. Fork repository
2. Create feature branch
3. Implement changes
4. Test thoroughly
5. Submit pull request dengan deskripsi lengkap

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **Developer**: [Your Name]
- **UI/UX Designer**: [Designer Name]
- **Project Manager**: [PM Name]

---

## 📞 Contact & Support

- **Email**: support@sportvenue.com
- **GitHub Issues**: [Create Issue](https://github.com/username/sportvenue/issues)
- **Documentation**: [Wiki](https://github.com/username/sportvenue/wiki)

---

<div align="center">
  <p>Made with ❤️ for Bandung Sports Community</p>
  <p>© 2024 SportVenue. All rights reserved.</p>
</div>
