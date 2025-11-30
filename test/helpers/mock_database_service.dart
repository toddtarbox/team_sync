/// Mock DatabaseService for testing
///
/// This provides utilities for creating test data.
/// Note: For actual widget tests, you may need to mock the DatabaseService
/// at a higher level or use integration testing approaches.
class MockDatabaseService {
  /// Mock data storage
  static final Map<String, List<Map<String, dynamic>>> _mockData = {};

  /// Setup the mock database
  static void setup() {
    _mockData.clear();
  }

  /// Add mock data for a specific collection
  static void addMockData(String collection, List<Map<String, dynamic>> data) {
    _mockData[collection] = data;
  }

  /// Get mock data for a collection
  static List<Map<String, dynamic>> getMockData(String collection) {
    return _mockData[collection] ?? [];
  }

  /// Clear all mock data
  static void clear() {
    _mockData.clear();
  }

  /// Query mock data with filtering
  static List<Map<String, dynamic>> query(
    String collection, {
    String? orderByChild,
    dynamic equalTo,
  }) {
    final data = _mockData[collection] ?? [];

    if (orderByChild != null && equalTo != null) {
      return data.where((item) => item[orderByChild] == equalTo).toList();
    }

    return data;
  }
}
