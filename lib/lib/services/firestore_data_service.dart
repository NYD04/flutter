import 'package:cloud_firestore/cloud_firestore.dart';

class Workshop {
  final String id;
  final String name;
  final List<String> mechanics;
  final List<String> bay;

  Workshop({
    required this.id,
    required this.name,
    required this.mechanics,
    required this.bay,
  });

  factory Workshop.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Workshop(
      id: doc.id,
      name: data['name'] ?? '',
      mechanics: List<String>.from(data['mechanics'] ?? []),
      bay: List<String>.from(data['bay'] ?? []),
    );
  }
}

class Part {
  final String id;
  final String name;
  final String partNumber;
  final String description;
  final double unitPrice;

  Part({
    required this.id,
    required this.name,
    required this.partNumber,
    required this.description,
    required this.unitPrice,
  });

  factory Part.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Part(
      id: doc.id,
      name: data['name'] ?? '',
      partNumber: data['partNumber'] ?? '',
      description: data['description'] ?? '',
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
    );
  }
}

class FirestoreDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _workshopsCollection = 'workshops';
  static const String _partsCollection = 'parts';

  // Get all workshops
  static Future<List<Workshop>> getWorkshops() async {
    try {
      final snapshot = await _firestore.collection(_workshopsCollection).get();
      return snapshot.docs.map((doc) => Workshop.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching workshops: $e');
      return [];
    }
  }

  // Get all parts
  static Future<List<Part>> getParts() async {
    try {
      final snapshot = await _firestore.collection(_partsCollection).get();
      return snapshot.docs.map((doc) => Part.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching parts: $e');
      return [];
    }
  }

  // Get workshop names
  static Future<List<String>> getWorkshopNames() async {
    final workshops = await getWorkshops();
    return workshops.map((w) => w.name).toList();
  }

  // Get mechanics for a specific workshop
  static Future<List<String>> getMechanicsForWorkshop(String workshopName) async {
    final workshops = await getWorkshops();
    final workshop = workshops.firstWhere(
      (w) => w.name == workshopName,
      orElse: () => workshops.isNotEmpty ? workshops.first : Workshop(id: '', name: '', mechanics: [], bay: []),
    );
    return workshop.mechanics;
  }

  // Get bay numbers for a specific workshop
  static Future<List<String>> getBayNumbersForWorkshop(String workshopName) async {
    final workshops = await getWorkshops();
    final workshop = workshops.firstWhere(
      (w) => w.name == workshopName,
      orElse: () => workshops.isNotEmpty ? workshops.first : Workshop(id: '', name: '', mechanics: [], bay: []),
    );
    return workshop.bay;
  }

  // Get part by name
  static Future<Part?> getPartByName(String partName) async {
    try {
      final parts = await getParts();
      return parts.firstWhere((p) => p.name == partName);
    } catch (e) {
      return null;
    }
  }

  // Generate unique order number
  static String generateOrderNumber() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    
    return 'ORD-$year$month$day-$hour$minute$second';
  }
}
