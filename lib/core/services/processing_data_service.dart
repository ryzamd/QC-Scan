// // Cập nhật ProcessingDataService
// import 'package:architecture_scan_app/core/enums/enums.dart';
// import 'package:architecture_scan_app/features/process/data/models/processing_item_model.dart';

// class ProcessingDataService {
//   // Danh sách lưu trữ các item đã được xử lý - thêm static để dữ liệu được giữ xuyên suốt phiên làm việc
//   static final List<ProcessingItemModel> _items = [];

//   // Cache để kiểm tra xem item đã được thêm hay chưa
//   static final Set<String> _itemKeys = {};
  
//   // Thêm một item mới vào danh sách
//   void addItem(
//     Map<String, String> materialInfo,
//     String barcode,
//     String quantity,
//     int deduction,
//   ) {
//     final timestamp = DateTime.now().toString().substring(0, 19);
//     final orderNumber = barcode;
//     final itemName = materialInfo['Material Name'] ?? 'Unknown Material';
    
//     // Tạo key để kiểm tra trùng lặp
//     final key = '${orderNumber}_$itemName';
    
//     // Kiểm tra xem item đã tồn tại chưa
//     if (_itemKeys.contains(key)) {
//       // Cập nhật item hiện có thay vì thêm mới
//       final index = _items.indexWhere((item) => 
//           item.orderNumber == orderNumber && item.itemName == itemName);
      
//       if (index != -1) {
//         final existingItem = _items[index];
//         _items[index] = ProcessingItemModel(
//           itemName: existingItem.itemName,
//           orderNumber: existingItem.orderNumber,
//           quantity: int.tryParse(quantity) ?? 0,
//           exception: deduction,
//           timestamp: timestamp, // Cập nhật timestamp mới
//           status: existingItem.status, // Giữ nguyên status
//         );
//       }
//       return;
//     }
    
//     final newItem = ProcessingItemModel(
//       itemName: itemName,
//       orderNumber: orderNumber,
//       quantity: int.tryParse(quantity) ?? 0,
//       exception: deduction,
//       timestamp: timestamp,
//       status: SignalStatus.pending, // Mặc định là pending
//     );
    
//     _items.add(newItem);
//     _itemKeys.add(key);
//   }
  
//   // Lấy tất cả các item
//   List<ProcessingItemModel> getAllItems({bool forceRefresh = false}) {
//     if (forceRefresh) {
//       // Không làm gì thêm vì danh sách _items đã được lưu trữ tĩnh
//       // Có thể thêm logic đồng bộ từ storage local nếu cần
//     }
//     return List.from(_items);
//   }
  
//   // Xóa một item khỏi danh sách
//   void removeItem(String orderNumber, String itemName) {
//     final key = '${orderNumber}_$itemName';
//     _items.removeWhere((item) => item.orderNumber == orderNumber && item.itemName == itemName);
//     _itemKeys.remove(key);
//   }
  
//   // Xóa tất cả các item
//   void clearItems() {
//     _items.clear();
//     _itemKeys.clear();
//   }
  
//   // Cập nhật status của một item
//   void updateItemStatus(String orderNumber, String itemName, SignalStatus newStatus) {
//     final index = _items.indexWhere(
//       (item) => item.orderNumber == orderNumber && item.itemName == itemName
//     );
    
//     if (index != -1) {
//       final item = _items[index];
//       _items[index] = ProcessingItemModel(
//         itemName: item.itemName,
//         orderNumber: item.orderNumber,
//         quantity: item.quantity,
//         exception: item.exception,
//         timestamp: item.timestamp,
//         status: newStatus,
//       );
//     }
//   }
  
//   // Kiểm tra xem một item có tồn tại không
//   bool hasItem(String orderNumber, String itemName) {
//     final key = '${orderNumber}_$itemName';
//     return _itemKeys.contains(key);
//   }
  
//   // Lấy số lượng item
//   int get itemCount => _items.length;
// }