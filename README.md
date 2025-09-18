# Delivery Management System

A Flutter-based mobile application for managing automotive parts delivery to workshops and mechanics. This system provides comprehensive job management features for delivery personnel.

## Features

### 🔐 Authentication
- Firebase Authentication integration
- Email-based sign-in/sign-up
- User profile management

### 📦 Job Management for Part Delivery Personnel

#### 1. Delivery Schedule View
- **Comprehensive Order List**: View all parts orders to be delivered
- **Destination Information**: Workshop name, bay number, and mechanic details
- **Time Management**: Required delivery time with urgency indicators
- **Order Details**: Complete order information including part quantities
- **Status Filtering**: Filter orders by delivery status (Pending, Picked Up, En Route, Delivered)
- **Real-time Updates**: Live updates using Firestore streams

#### 2. Delivery Status Update
- **Status Progression**: Update delivery status through workflow stages
  - Pending → Picked Up → En Route → Delivered
- **One-tap Updates**: Quick status updates with confirmation
- **Status History**: Track delivery progress over time
- **Visual Indicators**: Color-coded status badges and icons

#### 3. Delivery Confirmation
- **Digital Signature Capture**: Draw signatures directly on the device
- **Photo Documentation**: Take photos of delivered parts
- **Confirmation Details**: Add custom confirmation notes
- **Digital Records**: Store all confirmation data in Firestore
- **Gallery Integration**: Select photos from device gallery

#### 4. Part Request Details
- **Detailed Part Information**: Complete part specifications
- **Quantity Tracking**: Individual part quantities per order
- **Part Numbers**: Unique identifiers for each part
- **Pricing Information**: Unit prices and total calculations
- **Descriptions**: Detailed part descriptions and specifications

## Technical Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.9.2+
- **State Management**: StatefulWidget with setState
- **UI Components**: Material Design 3
- **Navigation**: Navigator 2.0 with MaterialPageRoute
- **Image Handling**: ImagePicker for camera/gallery access
- **File Management**: PathProvider for local file storage

### Backend (Firebase)
- **Database**: Cloud Firestore for real-time data
- **Authentication**: Firebase Auth with email/password
- **Storage**: Local device storage for signatures and photos
- **Real-time Sync**: Firestore streams for live updates

### Data Models
```dart
DeliveryOrder {
  - Order identification and tracking
  - Workshop and mechanic information
  - Delivery timeline and status
  - Parts list with quantities
  - Confirmation data (signature, photo, notes)
}

PartItem {
  - Part specifications and details
  - Quantity and pricing information
  - Unique identifiers
}
```

## Project Structure

```
lib/
├── models/
│   └── delivery_order.dart          # Data models for orders and parts
├── services/
│   └── delivery_service.dart        # Firestore operations and fake data
├── screens/
│   ├── delivery_schedule_screen.dart    # Main delivery list view
│   ├── delivery_details_screen.dart     # Order details and status updates
│   └── delivery_confirmation_screen.dart # Digital confirmation workflow
├── auth_gate.dart                   # Authentication wrapper
├── home.dart                        # Main dashboard
├── app.dart                         # App configuration
└── main.dart                        # App entry point
```

## Installation & Setup

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK 3.0 or higher
- Firebase project with Firestore enabled
- Android Studio / VS Code with Flutter extensions

### Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^4.1.0
  firebase_auth: ^6.0.2
  firebase_ui_auth: ^3.0.0
  cloud_firestore: 6.0.1
  path_provider: ^2.1.4
  permission_handler: ^11.3.1
  image_picker: ^1.1.2
```

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd delivery_ass
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project
   - Enable Authentication and Firestore
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place files in appropriate platform directories

4. **Run the application**
   ```bash
   flutter run
   ```

## Usage Guide

### For Delivery Personnel

1. **Sign In**: Use email/password authentication
2. **View Schedule**: Access the delivery schedule from the main dashboard
3. **Filter Orders**: Use the filter menu to view specific status orders
4. **Update Status**: Tap on orders to view details and update status
5. **Confirm Delivery**: Use digital signature and photo capture for delivery confirmation

### Sample Data
The app includes pre-populated sample data with:
- 5 sample delivery orders
- Various delivery statuses
- Different workshop and mechanic combinations
- Multiple parts per order
- Realistic timing and urgency scenarios

## Key Screens

### 1. Delivery Schedule Screen
- **Purpose**: Main dashboard for delivery personnel
- **Features**: Order list, status filtering, urgency indicators
- **Navigation**: Tap orders to view details

### 2. Delivery Details Screen
- **Purpose**: Detailed order information and status management
- **Features**: Part details, status updates, confirmation workflow
- **Actions**: Update status, view parts, confirm delivery

### 3. Delivery Confirmation Screen
- **Purpose**: Digital confirmation with signature and photo
- **Features**: Signature pad, camera integration, confirmation notes
- **Workflow**: Complete delivery with digital proof

## Mobile UX/UI Design

### Design Principles
- **Intuitive Navigation**: Clear hierarchy and logical flow
- **Touch-Friendly**: Large tap targets and gesture support
- **Status Visibility**: Color-coded status indicators
- **Offline Capability**: Local storage for signatures and photos
- **Responsive Design**: Adapts to different screen sizes

### Visual Elements
- **Color Coding**: Status-based color scheme
- **Icons**: Meaningful icons for quick recognition
- **Cards**: Information grouping with Material Design cards
- **Progress Indicators**: Visual status progression
- **Confirmation UI**: Clear success/error feedback

## Future Enhancements

### Planned Features
- **GPS Tracking**: Real-time location tracking during delivery
- **Push Notifications**: Status updates and new order alerts
- **Offline Mode**: Full offline functionality with sync
- **Barcode Scanning**: QR/barcode scanning for part verification
- **Route Optimization**: Efficient delivery route planning
- **Analytics Dashboard**: Delivery performance metrics

### Technical Improvements
- **State Management**: Implement Provider or Riverpod
- **Testing**: Unit and widget tests
- **CI/CD**: Automated testing and deployment
- **Performance**: Image optimization and caching
- **Security**: Enhanced data encryption and validation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.