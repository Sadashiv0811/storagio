import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_image.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/category/m_category.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_item.dart';
import 'package:storagio/inventory/p_item_image.dart';
import 'package:storagio/inventory/p_selected_c_r.dart';
import 'package:storagio/room/m_rooms.dart';
import 'package:storagio/settings/vm_settings.dart';
import 'package:storagio/user/m_user.dart';
import 'package:storagio/user/vm_user.dart';
import 'package:uuid/uuid.dart';

extension ItemUnitExtension on ItemUnit {
  String get label {
    switch (this) {
      case ItemUnit.unit:
        return 'Unit';

      case ItemUnit.piece:
        return 'Piece';

      case ItemUnit.kg:
        return 'Kg';

      case ItemUnit.gram:
        return 'Gram';

      case ItemUnit.litre:
        return 'Litre';

      case ItemUnit.ml:
        return 'mL';

      case ItemUnit.packet:
        return 'Packet';

      case ItemUnit.box:
        return 'Box';

      case ItemUnit.bottle:
        return 'Bottle';

      case ItemUnit.can:
        return 'Can';

      case ItemUnit.meter:
        return 'Meter';

      case ItemUnit.cm:
        return 'Cm';

      case ItemUnit.dozen:
        return 'Dozen';

      case ItemUnit.pair:
        return 'Pair';

      case ItemUnit.roll:
        return 'Roll';

      case ItemUnit.set:
        return 'Set';
    }
  }
}

final addItemVMProvider = ChangeNotifierProvider.autoDispose<AddItemViewModel>((
  ref,
) {
  return AddItemViewModel(ref);
});

class AddItemViewModel extends ChangeNotifier {
  AddItemViewModel(this.ref) {
    _loadDefaultLowStockLimit();
  }

  final Ref ref;

  final addItemFK = GlobalKey<FormState>();

  bool _initialized = false;

  MItem? _editingItem;
  MUser? user;

  // ---------------- Controllers ----------------
  final itemNameTEC = TextEditingController();
  final notesTEC = TextEditingController();
  final quantityTEC = TextEditingController();
  final lowStockTEC = TextEditingController();
  final lastPaymentAmountTEC = TextEditingController();

  // ---------------- Category and Room DD ----------------
  MCategory? selectedCategory;
  MRoom? selectedRoom;

  String? _itemCategoryName;
  String? _itemRoomId;

  // ---------------- Dates ----------------
  DateTime? _purchaseDate;
  DateTime? _warrantyDate;

  // ---------------- Image ----------------
  String? currentImagePath;

  // ---------------- Quantity, Low Stock Limit and Unit ----------------
  String _selectedUnit = ItemUnit.unit.label;

  String get selectedUnit => _selectedUnit;

  final List<String> unitItems = ItemUnit.values
      .map((unit) => unit.label)
      .toList();

  // ---------------- Loading ----------------
  bool _isPicking = false;
  bool _isDeleting = false;

  bool get isPicking => _isPicking;
  bool get isDeleting => _isDeleting;
  DateTime? get purchaseDate => _purchaseDate;
  DateTime? get warrantyDate => _warrantyDate;

  String get purchaseDateFormatted => _purchaseDate == null
      ? "Not selected"
      : DateFormat('dd/MM/yyyy').format(_purchaseDate!);

  String get warrantyDateFormatted => _warrantyDate == null
      ? "Not selected"
      : DateFormat('dd/MM/yyyy').format(_warrantyDate!);

  // When adding item
  void _loadDefaultLowStockLimit() {
    user = ref.read(userProvider).value;
    final lowLimit = ref.read(settingsVMProvider).lowStockThreshold;

    final categoryname = CategoryNames.bathroomEssentials;

    if (categoryname == CategoryNames.bathroomEssentials ||
        categoryname == CategoryNames.grocery ||
        categoryname == CategoryNames.hairEssentials ||
        categoryname == CategoryNames.kitchen) {
      lowStockTEC.text = (user?.lowStockLimit ?? lowLimit).toString();
    } else {
      lowStockTEC.text = "";
    }
  }

  // When editing item
  void initialize(MItem? item) {
    if (_initialized) return;

    _initialized = true;

    _editingItem = item;

    if (item == null) return;

    itemNameTEC.text = item.name;

    quantityTEC.text = item.quantity?.toString() ?? '';
    lowStockTEC.text = item.lowStockLimit?.toString() ?? '';
    lastPaymentAmountTEC.text = item.lastPaymentAmount?.toString() ?? '';

    _selectedUnit = item.unit != null
        ? ItemUnit.values.byName(item.unit!).label
        : ItemUnit.unit.label;
    notesTEC.text = item.notes ?? "";

    logger.d("purchase date $purchaseDate");

    _purchaseDate = item.purchaseDate;

    _warrantyDate = item.warrantyExpiry;

    currentImagePath = item.imagePath;

    _itemCategoryName = item.categoryName;
    _itemRoomId = item.roomId;

    notifyListeners();
  }

  // ---------------- Quantity, Low Stock Limit and Unit ----------------
  void setUnit(String? value) {
    if (value == null) return;

    _selectedUnit = value;

    notifyListeners();
  }

  // ---------------- Category and Room ----------------
  void setCategory(MCategory category) {
    selectedCategory = category;
    notifyListeners();

    final categoryname = selectedCategory!.categoryName;

    if (categoryname == "Bathroom Essentials" ||
        categoryname == "Grocery" ||
        categoryname == "Hair Essentials" ||
        categoryname == "Kitchen") {
      lowStockTEC.text = (user?.lowStockLimit ?? 4).toString();
    } else {
      lowStockTEC.text = "";
    }
  }

  void setRoom(MRoom room) {
    selectedRoom = room;
    notifyListeners();
  }

  void setupSelections({
    required List<MCategory> categories,
    required List<MRoom> rooms,
  }) {
    // Prevent running again
    if (selectedCategory != null && selectedRoom != null) {
      return;
    }

    // ---------------- CATEGORY ----------------
    final selectedCategoryName = ref.watch(selectedCategoryProvider).value;
    if (selectedCategory == null && categories.isNotEmpty) {
      // EDIT MODE (Category name stored in item object)
      if (_itemCategoryName != null) {
        selectedCategory = categories.firstWhere(
          (e) => e.categoryName == _itemCategoryName,
        );
      }

      // ADD MODE (Category name stored in selectedCategoryProvider)
      selectedCategory = categories.firstWhere(
        (e) => e.categoryName == selectedCategoryName,
      );

      // If selectedCategory is still null
      selectedCategory = selectedCategory ?? categories.first;
    }

    // ---------------- ROOM ----------------
    final selectedRoomId = ref.watch(selectedRoomProvider).value;
    if (selectedRoom == null && rooms.isNotEmpty) {
      // EDIT MODE (Room id stored in item object)
      if (_itemRoomId != null) {
        selectedRoom = rooms.firstWhere((e) => e.id == _itemRoomId);
      }

      // ADD MODE (Room id stored in selectedRoomProvider)
      selectedRoom = rooms.firstWhere((e) => e.id == selectedRoomId);

      // If selectedRoom is still null
      selectedRoom = selectedRoom ?? rooms.first;
    }

    notifyListeners();
  }

  // ---------------- Image ----------------
  Future<void> pickImageFromGallery() async {
    _setIsPicking(true);

    try {
      final newPath = await ref
          .read(itemImageProvider)
          .pickImage(oldPath: currentImagePath);

      if (newPath != null) {
        currentImagePath = newPath;
        logger.d("Item image path: $newPath");
      }
    } catch (e) {
      logger.e("Image picking failed: $e");
    } finally {
      _setIsPicking(false);
    }
  }

  Future<void> deleteItemImage() async {
    _setIsDeleting(true);

    try {
      final ImageService imageService = ImageService();
      final bool result = await imageService.deleteImage(
        currentImagePath ?? '',
      );

      if (result == false) return;

      logger.d("Item image deleted");
      currentImagePath = null;
      notifyListeners();
    } catch (e) {
      logger.e("Image deletion failed: $e");
    } finally {
      _setIsDeleting(false);
    }
  }

  Future<void> imageFromCamera() async {
    _setIsPicking(true);

    try {
      final newPath = await ref
          .read(itemImageProvider)
          .captureImageFromCamera(oldPath: currentImagePath);

      if (newPath != null) {
        currentImagePath = newPath;
        logger.d("Item image path: $newPath");
      }
    } catch (e) {
      logger.e("Image picking failed: $e");
    } finally {
      _setIsPicking(false);
    }
  }

  void _setIsPicking(bool value) {
    _isPicking = value;
    notifyListeners();
  }

  void _setIsDeleting(bool value) {
    _isDeleting = value;
    notifyListeners();
  }

  void editItemImage(ImageSourceType? source) async {
    if (source == null) return;

    if (source == ImageSourceType.camera) {
      await imageFromCamera();
    } else {
      await pickImageFromGallery();
    }
  }

  // ---------------- Purchase and Warranty Date ----------------
  void setPurchaseDate(DateTime date) {
    _purchaseDate = date;
    notifyListeners();
  }

  void setExpirtOrWarrantyDate(DateTime date) {
    _warrantyDate = date;
    notifyListeners();
  }

  // ---------------- Input Check ----------------
  void validate(BuildContext context) async {
    final isValid = addItemFK.currentState?.validate() ?? false;

    if (!isValid) return;

    final categoryError = validateCategoryFields();

    if (categoryError != null) {
      showSnackBar(categoryError, backgroundColor: Colors.red);
      return;
    }

    if (_purchaseDate != null && _warrantyDate != null) {
      // Normalize both dates to midnight (00:00:00.000) to strip the time
      final purchaseDayOnly = DateTime(
        _purchaseDate!.year,
        _purchaseDate!.month,
        _purchaseDate!.day,
      );
      final warrantyDayOnly = DateTime(
        _warrantyDate!.year,
        _warrantyDate!.month,
        _warrantyDate!.day,
      );

      // Trigger error if it's before OR the same day
      if (warrantyDayOnly.isBefore(purchaseDayOnly) ||
          warrantyDayOnly.isAtSameMomentAs(purchaseDayOnly)) {
        String message =
            "Warranty date cannot be before or the same as purchase date";

        if (selectedCategory!.categoryName == "Bills & Recharges") {
          message =
              "Due date cannot be before or the same as Last payment date";
        }

        showSnackBar(message, backgroundColor: Colors.red);
        return;
      }
    }

    try {
      final notifier = ref.read(itemProvider.notifier);

      final String? notes = notesTEC.text.trim().isEmpty
          ? null
          : notesTEC.text.trim();

      // Only user editable fields are changed.
      // Rest fields remain same, since their creation.
      final updatedItem = MItem(
        // KEEP OLD ID IN EDIT MODE
        id: _editingItem?.id ?? const Uuid().v4(),

        // KEEP OLD LOCAL ID IN EDIT MODE
        localId: _editingItem?.localId,

        name: itemNameTEC.text.trim(),

        categoryName: selectedCategory!.categoryName,

        roomId: isVisible(ItemField.room) ? selectedRoom?.id : null,

        quantity: isVisible(ItemField.quantity)
            ? double.tryParse(quantityTEC.text.trim())
            : null,

        lowStockLimit: isVisible(ItemField.lowStock)
            ? double.tryParse(lowStockTEC.text.trim())
            : null,

        unit: isVisible(ItemField.unit)
            ? ItemUnit.values
                  .firstWhere((unit) => unit.label == _selectedUnit)
                  .name
            : null,

        purchaseDate: isVisible(ItemField.purchaseDate) ? _purchaseDate : null,

        warrantyExpiry: isVisible(ItemField.warrantyDate)
            ? _warrantyDate
            : null,

        lastPaymentAmount: isVisible(ItemField.lastPaymentAmount)
            ? int.tryParse(lastPaymentAmountTEC.text.trim())
            : null,

        notes: isVisible(ItemField.notes) ? notes : null,

        imagePath: currentImagePath,

        synced: false,
      );

      final alreadyExists = await notifier.itemExists(
        itemNameTEC.text.trim(),
        updatedItem,
      );

      if (alreadyExists) {
        showSnackBar(
          "Item with this name already exists",
          backgroundColor: Colors.red,
        );
        return;
      }

      // =========================
      // EDIT
      // =========================
      if (_editingItem != null) {
        // OLD and  NEW item
        await notifier.updateItem(_editingItem as MItem, updatedItem);

        logger.i("Item updated");

        if (!context.mounted) return;

        showSnackBar("Item updated successfully");
      }
      // =========================
      // ADD
      // =========================
      else {
        await notifier.addItem(updatedItem);

        logger.i("Item added");

        if (!context.mounted) return;

        showSnackBar("Item added successfully");
      }

      await ref.read(itemProvider.notifier).refresh();

      // ---------------- Print All Inputs ----------------

      logger.d("""
    ITEM DATA

    Image Path: $currentImagePath
    Item Name: ${itemNameTEC.text.trim()}
    Category Name: ${selectedCategory!.categoryName}
    Quantity: ${quantityTEC.text.trim()}
    Low Stock Limit: ${lowStockTEC.text.trim()}
    Unit: $_selectedUnit
    Last Payment Amount: ${lastPaymentAmountTEC.text.trim()}
    Purchase Date: $purchaseDateFormatted
    Warranty Date: $warrantyDateFormatted
    Notes: ${notesTEC.text.trim()}
    """);

      if (selectedCategory?.categoryName != CategoryNames.billsRecharges) {
        logger.d("Room ID: ${selectedRoom!.id}");
      }

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      logger.e("Save item failed", error: e, stackTrace: stack);

      if (!context.mounted) return;

      showSnackBar("Failed to save item", backgroundColor: Colors.red);
    }
  }

  // Returns Error message
  String? validateCategoryFields() {
    final categoryName = selectedCategory?.categoryName;

    if (categoryName == null) {
      return "Please select category";
    }

    final rule = categoryRules[categoryName];

    if (rule == null) return null;

    // Name check
    if (rule.isRequired(ItemField.name) && itemNameTEC.text.trim().isEmpty) {
      String message = "Please enter item name";
      if (categoryName == CategoryNames.billsRecharges) {
        message = "Please enter product name";
      }
      return message;
    }

    // Room check
    if (rule.isRequired(ItemField.room) && selectedRoom == null) {
      return "Please select room";
    }

    // Note Check
    if (rule.isRequired(ItemField.notes) && notesTEC.text.trim().isEmpty) {
      String message = "Please enter notes";
      if (categoryName == CategoryNames.medicines) {
        message = "Please enter purpose";
      }
      return message;
    }

    // Unit Check
    if (rule.isRequired(ItemField.unit) && _selectedUnit.trim().isEmpty) {
      return "Please select unit";
    }

    // Quantity Check
    if (rule.isRequired(ItemField.quantity) &&
        quantityTEC.text.trim().isEmpty) {
      return "Please enter current quantity";
    }

    // Low Stock Limit Check
    if (rule.isRequired(ItemField.lowStock) &&
        lowStockTEC.text.trim().isEmpty) {
      return "Please enter low stock limit";
    }

    // Purchase date check
    if (rule.isRequired(ItemField.purchaseDate) && _purchaseDate == null) {
      String message = "Please select purchase date";
      if (categoryName == CategoryNames.billsRecharges) {
        message = "Please enter last payment date";
      }
      return message;
    }

    // Warranty/expiry date check
    if (rule.isRequired(ItemField.warrantyDate) && _warrantyDate == null) {
      String message = "Please select warranty date";
      if (categoryName == CategoryNames.billsRecharges) {
        message = "Please enter due date";
      }
      return message;
    }

    // Last payment amount check
    if (rule.isRequired(ItemField.lastPaymentAmount) &&
        lastPaymentAmountTEC.text.trim().isEmpty) {
      return "Please enter last payment amount";
    }

    return null;
  }

  bool isVisible(ItemField field) {
    final categoryName = selectedCategory?.categoryName;

    if (categoryName == null) return false;

    return categoryRules[categoryName]?.isVisible(field) ?? false;
  }

  @override
  void dispose() {
    itemNameTEC.dispose();
    notesTEC.dispose();
    quantityTEC.dispose();
    lowStockTEC.dispose();
    super.dispose();
  }
}

enum ItemField {
  imagePath,
  name,
  room,
  quantity,
  lowStock,
  unit,
  purchaseDate,
  warrantyDate,
  notes,
  lastPaymentAmount,
}

class CategoryValidationRule {
  final Set<ItemField> visibleFields;
  final Set<ItemField> requiredFields;

  const CategoryValidationRule({
    required this.visibleFields,
    required this.requiredFields,
  });

  bool isVisible(ItemField field) => visibleFields.contains(field);

  bool isRequired(ItemField field) => requiredFields.contains(field);
}

final categoryRules = {
  CategoryNames.bathroomEssentials: CategoryValidationRule(
    visibleFields: {
      ItemField.imagePath,
      ItemField.name,
      ItemField.room,
      ItemField.unit,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
      ItemField.notes,
    },
    requiredFields: {
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.unit,
    },
  ),

  CategoryNames.billsRecharges: CategoryValidationRule(
    visibleFields: {
      ItemField.name,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
      ItemField.lastPaymentAmount,
      ItemField.notes,
    },
    requiredFields: {
      ItemField.name,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
      ItemField.lastPaymentAmount,
    },
  ),

  CategoryNames.electronicAppliances: CategoryValidationRule(
    visibleFields: {
      ItemField.imagePath,
      ItemField.name,
      ItemField.room,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
      ItemField.notes,
    },
    requiredFields: {
      ItemField.name,
      ItemField.room,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
    },
  ),

  CategoryNames.grocery: CategoryValidationRule(
    visibleFields: {
      ItemField.imagePath,
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.unit,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
    },
    requiredFields: {
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.unit,
    },
  ),

  CategoryNames.hairEssentials: CategoryValidationRule(
    visibleFields: {
      ItemField.imagePath,
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.unit,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
      ItemField.notes,
    },
    requiredFields: {
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.unit,
    },
  ),

  CategoryNames.kitchen: CategoryValidationRule(
    visibleFields: {
      ItemField.imagePath,
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.unit,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
      ItemField.notes,
    },
    requiredFields: {
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.unit,
    },
  ),

  CategoryNames.medicines: CategoryValidationRule(
    visibleFields: {
      ItemField.imagePath,
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.lowStock,
      ItemField.unit,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
      ItemField.notes,
    },
    requiredFields: {
      ItemField.name,
      ItemField.room,
      ItemField.quantity,
      ItemField.unit,
      ItemField.purchaseDate,
      ItemField.warrantyDate,
      ItemField.notes,
    },
  ),
};
