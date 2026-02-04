import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flat_model.dart';
import '../core/constants/app_constants.dart';

class FlatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _flatsRef =>
      _firestore.collection(AppConstants.flatsCollection);

  // ============================================================
  // CREATE
  // ============================================================

  /// Create a new flat
  Future<String> createFlat(FlatModel flat) async {
    try {
      final docRef = await _flatsRef.add(flat.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create flat: $e');
    }
  }

  /// Create flat with specific ID
  Future<void> createFlatWithId(String flatId, FlatModel flat) async {
    try {
      await _flatsRef.doc(flatId).set(flat.toMap());
    } catch (e) {
      throw Exception('Failed to create flat: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  /// Get a single flat by ID
  Future<FlatModel?> getFlat(String flatId) async {
    try {
      final doc = await _flatsRef.doc(flatId).get();
      if (doc.exists && doc.data() != null) {
        return FlatModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get flat: $e');
    }
  }

  /// Get flat by flat number (supports both "A-101" format and just "101")
  Future<FlatModel?> getFlatByNumber(String flatNumber) async {
    try {
      // Parse block and number from input like "A-101"
      final block = _extractBlock(flatNumber);
      final number = _extractNumber(flatNumber);

      // Query by both block and flat number for accurate matching
      final snapshot = await _flatsRef
          .where(AppConstants.fieldBlock, isEqualTo: block)
          .where(AppConstants.fieldFlatNum, isEqualTo: number)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return FlatModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get flat by number: $e');
    }
  }

  /// Get all flats
  Future<List<FlatModel>> getAllFlats() async {
    try {
      final snapshot = await _flatsRef
          .orderBy(AppConstants.fieldBlock)
          .orderBy(AppConstants.fieldFlatNum)
          .get();
      return snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all flats: $e');
    }
  }

  /// Get flats by block
  Future<List<FlatModel>> getFlatsByBlock(String block) async {
    try {
      final snapshot = await _flatsRef
          .where(AppConstants.fieldBlock, isEqualTo: block)
          .orderBy(AppConstants.fieldFlatNum)
          .get();
      return snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get flats by block: $e');
    }
  }

  /// Get flats for a resident
  Future<List<FlatModel>> getFlatsForResident(String residentId) async {
    try {
      final snapshot = await _flatsRef
          .where(AppConstants.fieldResidentIds, arrayContains: residentId)
          .get();
      return snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get flats for resident: $e');
    }
  }

  /// Get flat number for a resident (returns first flat)
  Future<String?> getFlatNumberForResident(String residentId) async {
    try {
      final flats = await getFlatsForResident(residentId);
      if (flats.isNotEmpty) {
        return flats.first.flatNumber;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get flat number for resident: $e');
    }
  }

  // ============================================================
  // REAL-TIME STREAMS
  // ============================================================

  /// Stream all flats
  Stream<List<FlatModel>> streamAllFlats() {
    return _flatsRef
        .orderBy(AppConstants.fieldBlock)
        .orderBy(AppConstants.fieldFlatNum)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream flats for a resident
  Stream<List<FlatModel>> streamFlatsForResident(String residentId) {
    return _flatsRef
        .where(AppConstants.fieldResidentIds, arrayContains: residentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// Update flat details
  Future<void> updateFlat(String flatId, Map<String, dynamic> data) async {
    try {
      data[AppConstants.fieldUpdatedAt] = FieldValue.serverTimestamp();
      await _flatsRef.doc(flatId).update(data);
    } catch (e) {
      throw Exception('Failed to update flat: $e');
    }
  }

  /// Add resident to flat
  Future<void> addResidentToFlat(String flatId, String residentId) async {
    try {
      await _flatsRef.doc(flatId).update({
        AppConstants.fieldResidentIds: FieldValue.arrayUnion([residentId]),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add resident to flat: $e');
    }
  }

  /// Remove resident from flat
  Future<void> removeResidentFromFlat(String flatId, String residentId) async {
    try {
      await _flatsRef.doc(flatId).update({
        AppConstants.fieldResidentIds: FieldValue.arrayRemove([residentId]),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove resident from flat: $e');
    }
  }

  /// Assign resident to flat by flat number
  Future<void> assignResidentToFlatByNumber(
    String flatNumber,
    String residentId,
  ) async {
    try {
      // First check if flat exists
      final flat = await getFlatByNumber(flatNumber);

      if (flat != null) {
        // Flat exists, add resident
        await addResidentToFlat(flat.id, residentId);
      } else {
        // Create new flat with resident
        // Extract block (e.g., "A") and number (e.g., "101") from "A-101"
        final newFlat = FlatModel(
          id: '',
          flatNumber: _extractNumber(flatNumber),
          block: _extractBlock(flatNumber),
          residentIds: [residentId],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createFlat(newFlat);
      }
    } catch (e) {
      throw Exception('Failed to assign resident to flat: $e');
    }
  }

  /// Extract block from flat number (e.g., "A-101" -> "A")
  String _extractBlock(String flatNumber) {
    final parts = flatNumber.split('-');
    if (parts.length > 1) {
      return parts[0].toUpperCase();
    }
    return 'A'; // Default block
  }

  /// Extract number from flat number (e.g., "A-101" -> "101")
  String _extractNumber(String flatNumber) {
    final parts = flatNumber.split('-');
    if (parts.length > 1) {
      return parts[1];
    }
    return flatNumber; // Return as-is if no delimiter
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Delete a flat
  Future<void> deleteFlat(String flatId) async {
    try {
      await _flatsRef.doc(flatId).delete();
    } catch (e) {
      throw Exception('Failed to delete flat: $e');
    }
  }

  // ============================================================
  // QUERIES
  // ============================================================

  /// Get all unique blocks
  Future<List<String>> getAllBlocks() async {
    try {
      final snapshot = await _flatsRef.get();
      final blocks = snapshot.docs
          .map((doc) => doc.data()[AppConstants.fieldBlock] as String? ?? '')
          .where((block) => block.isNotEmpty)
          .toSet()
          .toList();
      blocks.sort();
      return blocks;
    } catch (e) {
      throw Exception('Failed to get blocks: $e');
    }
  }

  /// Check if flat number exists
  Future<bool> flatNumberExists(String flatNumber) async {
    try {
      final flat = await getFlatByNumber(flatNumber);
      return flat != null;
    } catch (e) {
      return false;
    }
  }

  /// Get total flat count
  Future<int> getTotalFlatCount() async {
    try {
      final count = await _flatsRef.count().get();
      return count.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get flat count: $e');
    }
  }

  /// Get flats with residents count
  Future<Map<String, int>> getFlatsWithResidentsCount() async {
    try {
      final snapshot = await _flatsRef.get();
      int withResidents = 0;
      int withoutResidents = 0;

      for (final doc in snapshot.docs) {
        final residents = doc.data()[AppConstants.fieldResidentIds] as List? ?? [];
        if (residents.isNotEmpty) {
          withResidents++;
        } else {
          withoutResidents++;
        }
      }

      return {
        'withResidents': withResidents,
        'withoutResidents': withoutResidents,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get flats count: $e');
    }
  }

  // ============================================================
  // ADMIN METHODS
  // ============================================================

  /// Search flats by flat number (partial match)
  Future<List<FlatModel>> searchFlats(String query) async {
    try {
      if (query.isEmpty) {
        return getAllFlats();
      }

      final snapshot = await _flatsRef.get();
      final queryLower = query.toLowerCase();

      return snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .where((flat) =>
              flat.flatNumber.toLowerCase().contains(queryLower) ||
              flat.block.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      throw Exception('Failed to search flats: $e');
    }
  }

  /// Get occupied flats (flats with at least one resident)
  Future<List<FlatModel>> getOccupiedFlats() async {
    try {
      final snapshot = await _flatsRef.get();

      return snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .where((flat) => flat.residentIds.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to get occupied flats: $e');
    }
  }

  /// Get vacant flats (flats with no residents)
  Future<List<FlatModel>> getVacantFlats() async {
    try {
      final snapshot = await _flatsRef.get();

      return snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .where((flat) => flat.residentIds.isEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to get vacant flats: $e');
    }
  }

  /// Get flats by floor (extracts floor from flat number, e.g., "A-101" -> floor 1)
  Future<List<FlatModel>> getFlatsByFloor(int floor) async {
    try {
      final snapshot = await _flatsRef.get();

      return snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .where((flat) => _extractFloor(flat.flatNumber) == floor)
          .toList();
    } catch (e) {
      throw Exception('Failed to get flats by floor: $e');
    }
  }

  /// Extract floor from flat number (e.g., "A-101" -> 1, "B-205" -> 2)
  int _extractFloor(String flatNumber) {
    final parts = flatNumber.split('-');
    if (parts.length > 1) {
      final numPart = parts[1];
      if (numPart.isNotEmpty) {
        // First digit is usually the floor
        return int.tryParse(numPart[0]) ?? 0;
      }
    }
    return 0;
  }

  /// Get all floors in the building
  Future<List<int>> getAllFloors() async {
    try {
      final snapshot = await _flatsRef.get();
      final floors = snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .map((flat) => _extractFloor(flat.flatNumber))
          .where((floor) => floor > 0)
          .toSet()
          .toList();
      floors.sort();
      return floors;
    } catch (e) {
      throw Exception('Failed to get floors: $e');
    }
  }

  /// Get flat statistics summary
  Future<Map<String, dynamic>> getFlatStatistics() async {
    try {
      final snapshot = await _flatsRef.get();
      final flats = snapshot.docs
          .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
          .toList();

      int occupied = 0;
      int vacant = 0;
      int totalResidents = 0;
      final blockCounts = <String, int>{};

      for (final flat in flats) {
        if (flat.residentIds.isNotEmpty) {
          occupied++;
          totalResidents += flat.residentIds.length;
        } else {
          vacant++;
        }

        blockCounts[flat.block] = (blockCounts[flat.block] ?? 0) + 1;
      }

      return {
        'totalFlats': flats.length,
        'occupied': occupied,
        'vacant': vacant,
        'totalResidents': totalResidents,
        'occupancyRate': flats.isNotEmpty ? (occupied / flats.length * 100).toStringAsFixed(1) : '0',
        'blockCounts': blockCounts,
      };
    } catch (e) {
      throw Exception('Failed to get flat statistics: $e');
    }
  }

  /// Bulk create flats (for initial setup)
  Future<void> bulkCreateFlats(List<FlatModel> flats) async {
    try {
      final batch = _firestore.batch();

      for (final flat in flats) {
        final docRef = _flatsRef.doc();
        batch.set(docRef, flat.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk create flats: $e');
    }
  }

  /// Update flat with full model
  Future<void> updateFlatModel(String flatId, FlatModel flat) async {
    try {
      final data = flat.toMap();
      data[AppConstants.fieldUpdatedAt] = FieldValue.serverTimestamp();
      await _flatsRef.doc(flatId).update(data);
    } catch (e) {
      throw Exception('Failed to update flat: $e');
    }
  }
}
