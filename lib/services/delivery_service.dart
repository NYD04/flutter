import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_order.dart';

class DeliveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'delivery_orders';

  // Get all delivery orders
  static Stream<List<DeliveryOrder>> getDeliveryOrders() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => DeliveryOrder.fromFirestore(doc))
              .toList();
          // Sort by requiredBy date after fetching
          orders.sort((a, b) => a.requiredBy.compareTo(b.requiredBy));
          return orders;
        });
  }

  // Get delivery orders by status
  static Stream<List<DeliveryOrder>> getDeliveryOrdersByStatus(DeliveryStatus status) {
    if (status == DeliveryStatus.all) {
      return getDeliveryOrders();
    }
    
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => DeliveryOrder.fromFirestore(doc))
              .toList();
          // Sort by requiredBy date after fetching
          orders.sort((a, b) => a.requiredBy.compareTo(b.requiredBy));
          return orders;
        });
  }

  // Update delivery status
  static Future<void> updateDeliveryStatus(String orderId, DeliveryStatus status) async {
    await _firestore.collection(_collection).doc(orderId).update({
      'status': status.toString().split('.').last,
      if (status == DeliveryStatus.delivered) 'deliveredAt': Timestamp.now(),
    });
  }

  // Add delivery confirmation
  static Future<void> addDeliveryConfirmation(
    String orderId,
    String confirmation,
    String? signaturePath,
    String? photoPath,
  ) async {
    await _firestore.collection(_collection).doc(orderId).update({
      'deliveryConfirmation': confirmation,
      'signaturePath': signaturePath,
      'photoPath': photoPath,
      'status': DeliveryStatus.delivered.toString().split('.').last,
      'deliveredAt': Timestamp.now(),
    });
  }

  // Initialize fake data
  static Future<void> initializeFakeData() async {
    try {
      // Check if data already exists
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Fake data already exists, skipping initialization');
        return;
      }

      print('Initializing fake data...');
      final fakeOrders = _generateFakeOrders();
      
      for (final order in fakeOrders) {
        await _firestore.collection(_collection).add(order.toFirestore());
        print('Added order: ${order.orderNumber}');
      }
      print('Fake data initialization completed successfully');
    } catch (e) {
      print('Error initializing fake data: $e');
      rethrow;
    }
  }

  // Get data count for debugging
  static Future<int> getDataCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      print('Total orders in database: ${snapshot.docs.length}');
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting data count: $e');
      return 0;
    }
  }

  static List<DeliveryOrder> _generateFakeOrders() {
    final now = DateTime.now();
    
    return [
      DeliveryOrder(
        id: '1',
        orderNumber: 'ORD-2024-001',
        workshopName: 'AutoCare Workshop',
        mechanicName: 'John Smith',
        bayNumber: 'Bay 3',
        requiredBy: now.add(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 1)),
        status: DeliveryStatus.pending,
        parts: [
          PartItem(
            id: 'p1',
            name: 'Brake Pads',
            partNumber: 'BP-001',
            quantity: 4,
            description: 'Front brake pads for Honda Civic',
            unitPrice: 45.99,
          ),
          PartItem(
            id: 'p2',
            name: 'Oil Filter',
            partNumber: 'OF-002',
            quantity: 1,
            description: 'Engine oil filter',
            unitPrice: 12.50,
          ),
        ],
        notes: 'Urgent delivery needed for brake repair',
      ),
      DeliveryOrder(
        id: '2',
        orderNumber: 'ORD-2024-002',
        workshopName: 'QuickFix Garage',
        mechanicName: 'Sarah Johnson',
        bayNumber: 'Bay 1',
        requiredBy: now.add(const Duration(hours: 4)),
        createdAt: now.subtract(const Duration(minutes: 30)),
        status: DeliveryStatus.pickedUp,
        parts: [
          PartItem(
            id: 'p3',
            name: 'Air Filter',
            partNumber: 'AF-003',
            quantity: 2,
            description: 'Engine air filter',
            unitPrice: 18.75,
          ),
        ],
        notes: 'Regular maintenance parts',
      ),
      DeliveryOrder(
        id: '3',
        orderNumber: 'ORD-2024-003',
        workshopName: 'Pro Auto Service',
        mechanicName: 'Mike Wilson',
        bayNumber: 'Bay 5',
        requiredBy: now.add(const Duration(hours: 6)),
        createdAt: now.subtract(const Duration(hours: 2)),
        status: DeliveryStatus.enRoute,
        parts: [
          PartItem(
            id: 'p4',
            name: 'Spark Plugs',
            partNumber: 'SP-004',
            quantity: 6,
            description: 'Iridium spark plugs',
            unitPrice: 8.99,
          ),
          PartItem(
            id: 'p5',
            name: 'Timing Belt',
            partNumber: 'TB-005',
            quantity: 1,
            description: 'Engine timing belt',
            unitPrice: 89.99,
          ),
        ],
        notes: 'Engine tune-up parts',
      ),
      DeliveryOrder(
        id: '4',
        orderNumber: 'ORD-2024-004',
        workshopName: 'Elite Motors',
        mechanicName: 'David Brown',
        bayNumber: 'Bay 2',
        requiredBy: now.add(const Duration(hours: 8)),
        createdAt: now.subtract(const Duration(hours: 3)),
        status: DeliveryStatus.delivered,
        parts: [
          PartItem(
            id: 'p6',
            name: 'Transmission Fluid',
            partNumber: 'TF-006',
            quantity: 3,
            description: 'Automatic transmission fluid',
            unitPrice: 24.99,
          ),
        ],
        notes: 'Transmission service',
        deliveryConfirmation: 'Delivered successfully',
        signaturePath: 'signatures/sig_2024_004.png',
        photoPath: 'photos/photo_2024_004.jpg',
        deliveredAt: now.subtract(const Duration(minutes: 15)),
      ),
      DeliveryOrder(
        id: '5',
        orderNumber: 'ORD-2024-005',
        workshopName: 'City Auto Repair',
        mechanicName: 'Lisa Davis',
        bayNumber: 'Bay 4',
        requiredBy: now.add(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(minutes: 45)),
        status: DeliveryStatus.pending,
        parts: [
          PartItem(
            id: 'p7',
            name: 'Battery',
            partNumber: 'BAT-007',
            quantity: 1,
            description: '12V Car Battery 60Ah',
            unitPrice: 129.99,
          ),
          PartItem(
            id: 'p8',
            name: 'Alternator',
            partNumber: 'ALT-008',
            quantity: 1,
            description: '100A Alternator',
            unitPrice: 199.99,
          ),
        ],
        notes: 'Electrical system repair - urgent',
      ),
    ];
  }
}
