import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStatus {
  all,
  pending,
  pickedUp,
  enRoute,
  delivered,
  cancelled
}

class DeliveryOrder {
  final String id;
  final String orderNumber;
  final String workshopName;
  final String mechanicName;
  final String bayNumber;
  final DateTime requiredBy;
  final DateTime createdAt;
  final DeliveryStatus status;
  final List<PartItem> parts;
  final String notes;
  final String? deliveryConfirmation;
  final String? signaturePath;
  final String? photoPath;
  final DateTime? deliveredAt;

  DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.workshopName,
    required this.mechanicName,
    required this.bayNumber,
    required this.requiredBy,
    required this.createdAt,
    required this.status,
    required this.parts,
    this.notes = '',
    this.deliveryConfirmation,
    this.signaturePath,
    this.photoPath,
    this.deliveredAt,
  });

  factory DeliveryOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DeliveryOrder(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      workshopName: data['workshopName'] ?? '',
      mechanicName: data['mechanicName'] ?? '',
      bayNumber: data['bayNumber'] ?? '',
      requiredBy: (data['requiredBy'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: DeliveryStatus.values.firstWhere(
        (e) => e.toString() == 'DeliveryStatus.${data['status']}',
        orElse: () => DeliveryStatus.pending,
      ),
      parts: (data['parts'] as List<dynamic>?)
          ?.map((part) => PartItem.fromMap(part))
          .toList() ?? [],
      notes: data['notes'] ?? '',
      deliveryConfirmation: data['deliveryConfirmation'],
      signaturePath: data['signaturePath'],
      photoPath: data['photoPath'],
      deliveredAt: data['deliveredAt'] != null 
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'workshopName': workshopName,
      'mechanicName': mechanicName,
      'bayNumber': bayNumber,
      'requiredBy': Timestamp.fromDate(requiredBy),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
      'parts': parts.map((part) => part.toMap()).toList(),
      'notes': notes,
      'deliveryConfirmation': deliveryConfirmation,
      'signaturePath': signaturePath,
      'photoPath': photoPath,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  DeliveryOrder copyWith({
    String? id,
    String? orderNumber,
    String? workshopName,
    String? mechanicName,
    String? bayNumber,
    DateTime? requiredBy,
    DateTime? createdAt,
    DeliveryStatus? status,
    List<PartItem>? parts,
    String? notes,
    String? deliveryConfirmation,
    String? signaturePath,
    String? photoPath,
    DateTime? deliveredAt,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      workshopName: workshopName ?? this.workshopName,
      mechanicName: mechanicName ?? this.mechanicName,
      bayNumber: bayNumber ?? this.bayNumber,
      requiredBy: requiredBy ?? this.requiredBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      parts: parts ?? this.parts,
      notes: notes ?? this.notes,
      deliveryConfirmation: deliveryConfirmation ?? this.deliveryConfirmation,
      signaturePath: signaturePath ?? this.signaturePath,
      photoPath: photoPath ?? this.photoPath,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}

class PartItem {
  final String id;
  final String name;
  final String partNumber;
  final int quantity;
  final String description;
  final double unitPrice;

  PartItem({
    required this.id,
    required this.name,
    required this.partNumber,
    required this.quantity,
    required this.description,
    required this.unitPrice,
  });

  factory PartItem.fromMap(Map<String, dynamic> map) {
    return PartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      partNumber: map['partNumber'] ?? '',
      quantity: map['quantity'] ?? 0,
      description: map['description'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'partNumber': partNumber,
      'quantity': quantity,
      'description': description,
      'unitPrice': unitPrice,
    };
  }
}
