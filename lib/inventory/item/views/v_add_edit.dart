import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/inventory/category/vm_category.dart';
import 'package:storagio/inventory/item/m_item.dart';
import 'package:storagio/inventory/item/viewmodels/vm_add_edit.dart';
import 'package:storagio/inventory/p_selected_c_r.dart';
import 'package:storagio/room/d_add_edit.dart';
import 'package:storagio/room/vm_room.dart';

class VAddEditItem extends ConsumerStatefulWidget {
  final MItem? item;
  final bool disableRoom;

  const VAddEditItem({super.key, this.item, required this.disableRoom});

  @override
  ConsumerState<VAddEditItem> createState() => _VAddEditItemState();
}

class _VAddEditItemState extends ConsumerState<VAddEditItem>
    with WidgetsBindingObserver {
  bool isGranted = false;
  bool _openedSettings = false;

  Future<void> checkCameraPermission() async {
    final status = await Permission.camera.status;

    isGranted = status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();

    isGranted = status.isGranted;

    if (status.isPermanentlyDenied) {
      _openedSettings = true;
      await openAppSettings();
    }

    return status.isGranted;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(addItemVMProvider);

      await checkCameraPermission();

      vm.initialize(widget.item);

      final categories = await ref.read(categoryProvider.future);
      final rooms = await ref.read(roomProvider.future);

      vm.setupSelections(categories: categories, rooms: rooms);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If user returns from device settings, automatically re-evaluate status
    if (state == AppLifecycleState.resumed && _openedSettings) {
      _openedSettings = false;
      checkCameraPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(addItemVMProvider);
    final categoryState = ref.watch(categoryProvider);
    final roomState = ref.watch(roomProvider);

    final selectedRoomId = ref.read(selectedRoomProvider).value;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedCategoryName = vm.selectedCategory?.categoryName;

    final isBills = selectedCategoryName == CategoryNames.billsRecharges;
    final isElectronic =
        selectedCategoryName == CategoryNames.electronicAppliances;

    final isDeleting = vm.isDeleting;

    final file = vm.currentImagePath == null
        ? null
        : File(vm.currentImagePath!);

    final appBarTitle = widget.item == null
        ? (isBills ? "Add Payment" : "Add Item")
        : (isBills ? "Edit Payment" : "Edit Item");

    final itemNameLabel = isBills ? "PRODUCT NAME" : "ITEM NAME";
    final showItemImage = !isBills;

    return Scaffold(
      appBar: AppBar(title: appBarText(appBarTitle)),
      body: SafeArea(
        child: Form(
          key: vm.addItemFK,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                if (isElectronic && widget.item == null) ...[
                  const SizedBox(height: 20),

                  Text(
                    "Add only those items with active warranty or regular maintenance.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],

                // Item Image
                if (showItemImage) ...[
                  const SizedBox(height: 20),

                  Center(
                    child: CustomPaint(
                      painter: _CDashedRectPainter(color: Colors.blue.shade100),
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              spreadRadius: 2,
                              blurRadius: 3,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: file == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  vm.isPicking
                                      ? CircularProgressIndicator()
                                      : Row(
                                          mainAxisAlignment: .center,
                                          children: [
                                            // Image from camera
                                            buildImageBtn(
                                              iconData: Icons.add_a_photo,
                                              onPressed: () async {
                                                if (isGranted ||
                                                    await requestCameraPermission()) {
                                                  await vm.imageFromCamera();
                                                }
                                              },
                                            ),
                                            SizedBox(width: 20),
                                            // Image from gallery
                                            buildImageBtn(
                                              iconData: Icons.image,

                                              onPressed: () async {
                                                await vm.pickImageFromGallery();
                                              },
                                            ),
                                          ],
                                        ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Add Item Photo",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const Text(
                                    "TAP TO BROWSE GALLERY",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Stack(
                                  children: [
                                    Image.file(
                                      file,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            logger.d("Image Error: $error");
                                            return const Center(
                                              child: Icon(Icons.broken_image),
                                            );
                                          },
                                    ),
                                    // Edit Image
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: buildImageActionBtn(
                                        isEditBtn: true,
                                        onPressed: () async {
                                          final source =
                                              await showImageSourceSheet(
                                                context,
                                              );
                                          vm.editItemImage(source);
                                        },
                                      ),
                                    ),
                                    // Delete Image
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      child: buildImageActionBtn(
                                        isEditBtn: false,
                                        isDeleting: isDeleting,
                                        onPressed: isDeleting
                                            ? null
                                            : () async {
                                                await vm.deleteItemImage();
                                              },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ],

                // Item Name
                const SizedBox(height: 20),

                CLabel(text: itemNameLabel, requiredField: true),

                CTextFormField(
                  controller: vm.itemNameTEC,
                  prefixIconData: Icons.label_important_rounded,
                  hint: "e.g. Dyson V15 Vacuum",
                ),

                // Item Category Dropdown
                const SizedBox(height: 20),

                categoryState.when(
                  data: (categoriesData) {
                    if (categoriesData.isEmpty) {
                      return SizedBox.shrink();
                    }

                    final categoryNames = List<String>.from(
                      categoriesData.map((e) => e.categoryName),
                    );

                    String? displayCategory = selectedCategoryName;

                    if (widget.disableRoom) {
                      // When going to add item in room:
                      // Remove billsRecharges category from dropdown
                      categoryNames.remove(CategoryNames.billsRecharges);

                      // If selectedCategory is billsRecharges then change it to Bathroom Essentials
                      if (displayCategory == CategoryNames.billsRecharges) {
                        displayCategory = CategoryNames.bathroomEssentials;
                      }
                    }

                    return Column(
                      crossAxisAlignment: .start,
                      children: [
                        CLabel(text: "CATEGORIES", requiredField: true),
                        CDropDown(
                          type: "CATEGORY",
                          value: displayCategory,
                          valueList: categoryNames,
                          onChanged: (String? value) {
                            if (value == null) return;

                            final selected = categoriesData.firstWhere(
                              (e) => e.categoryName == value,
                            );

                            vm.setCategory(selected);
                          },
                        ),
                      ],
                    );
                  },

                  loading: () => const LoadingDisplay(),

                  error: (error, stack) =>
                      ErrorDisplay(error: error, stack: stack),
                ),

                // Room dropdown for other categories except Bills & Recharges
                if (!isBills) ...[
                  const SizedBox(height: 10),
                  roomState.when(
                    data: (roomsData) {
                      if (roomsData.isEmpty) {
                        return EmptyRooms(
                          title: "ROOMS",
                          isRequired: true,
                          message:
                              "No rooms added yet. Tap + button to add room.",
                          topPadding: 0,
                          addCallback: () => showAddRoomDialog(context),
                        );
                      }

                      String roomName = '';
                      // Edit mode
                      if (widget.item != null) {
                        roomName =
                            roomsData.firstWhereOrNull((element) {
                              return element.id == widget.item!.roomId;
                            })?.roomName ??
                            '';
                      }
                      // Add mode
                      else {
                        roomName =
                            roomsData.firstWhereOrNull((element) {
                              return element.id == selectedRoomId;
                            })?.roomName ??
                            '';
                      }

                      return Column(
                        children: [
                          if (widget.disableRoom == true) SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            crossAxisAlignment: .end,
                            children: [
                              CLabel(
                                text: "ROOMS",
                                requiredField: true,
                                lowOpacity:
                                    widget.disableRoom && widget.item == null,
                              ),
                              if (widget.disableRoom == false)
                                IconButton(
                                  onPressed: () => showAddRoomDialog(context),
                                  icon: Icon(Icons.add),
                                ),
                            ],
                          ),
                          if (widget.disableRoom && widget.item == null)
                            _DefaultRoom(roomName: roomName)
                          else
                            CDropDown(
                              type: "ROOM",
                              value: vm.selectedRoom?.roomName,
                              valueList: roomsData
                                  .map((e) => e.roomName)
                                  .toList(),
                              onChanged: (String? value) {
                                if (value == null) return;

                                final selected = roomsData.firstWhere(
                                  (e) => e.roomName == value,
                                );

                                vm.setRoom(selected);
                              },
                            ),
                        ],
                      );
                    },

                    loading: () => const LoadingDisplay(),

                    error: (error, stack) =>
                        ErrorDisplay(error: error, stack: stack),
                  ),
                ],

                // Other fields based on selected category
                buildCategoryFields(vm),

                const SizedBox(height: 40),

                // Action Button
                Row(
                  children: [
                    Expanded(child: CCancelButton()),

                    const SizedBox(width: 10),

                    Expanded(
                      child: CPositiveButton(
                        text: widget.item == null ? "Save" : "Update",
                        iconData: widget.item == null ? Icons.save : Icons.edit,
                        callback: () {
                          vm.validate(context);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCategoryFields(AddItemViewModel vm) {
    switch (vm.selectedCategory?.categoryName) {
      case CategoryNames.bathroomEssentials:
        return buildCommonFields(
          vm: vm,
          uqlRequied: true,
          pwRequied: false,
          notesRequired: false,
        );

      case CategoryNames.billsRecharges:
        return Column(
          children: [
            buildPWFields(
              vm: vm,
              labelDate1: "LAST PAYMENT DATE",
              labelDate2: "DUE DATE",
              isRequired: true,
            ),

            _CNumberField(
              label: "LAST PAYMENT AMOUNT",
              hint: "e.g. 199 or 349",
              isDecimal: false,
              requiredField: true,
              controller: vm.lastPaymentAmountTEC,
              iconData: Icons.payment_outlined,
            ),

            buildNotesField(vm: vm, label: "NOTES", isRequired: false),
          ],
        );

      case CategoryNames.electronicAppliances:
        return Column(
          children: [
            buildPWFields(vm: vm, isRequired: true),

            buildNotesField(
              vm: vm,
              isRequired: false,
              label: "MAINTENANCE DETAILS",
            ),
          ],
        );

      case CategoryNames.grocery:
        return Column(
          children: [
            buildUQLField(vm: vm, isRequired: true),

            buildPWFields(vm: vm, isRequired: false),
          ],
        );

      case CategoryNames.hairEssentials:
        return buildCommonFields(
          vm: vm,
          uqlRequied: true,
          pwRequied: false,
          notesRequired: false,
        );

      case CategoryNames.kitchen:
        return buildCommonFields(
          vm: vm,
          uqlRequied: true,
          pwRequied: false,
          notesRequired: false,
        );

      case CategoryNames.medicines:
        return buildCommonFields(
          vm: vm,
          uqlRequied: true,
          pwRequied: true,
          notesRequired: true,
          noteLabel: "PURPOSE",
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildCommonFields({
    required AddItemViewModel vm,
    required bool uqlRequied,
    required bool pwRequied,
    required bool notesRequired,
    String noteLabel = "NOTES",
  }) {
    return Column(
      children: [
        buildUQLField(vm: vm, isRequired: uqlRequied),
        buildPWFields(vm: vm, isRequired: pwRequied),
        buildNotesField(vm: vm, label: noteLabel, isRequired: notesRequired),
      ],
    );
  }

  // Build Camera and Gallery Button
  Widget buildImageBtn({
    required VoidCallback onPressed,
    required IconData iconData,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(iconData, color: Colors.blue.shade800, size: 30),
      ),
    );
  }

  // Build Edit and Delete Button
  Widget buildImageActionBtn({
    required VoidCallback? onPressed,
    required bool isEditBtn,
    bool? isDeleting,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          iconSize: 25,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        icon: isDeleting != null && isDeleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isEditBtn ? Icons.edit : Icons.delete,
                color: isEditBtn ? Colors.white : Colors.red,
                size: 18,
              ),
      ),
    );
  }

  // Build Note field
  Widget buildNotesField({
    required AddItemViewModel vm,
    required bool isRequired,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const SizedBox(height: 20),

        CLabel(text: label, requiredField: isRequired),

        CTextFormField(
          controller: vm.notesTEC,
          prefixIconData: Icons.sticky_note_2_rounded,
          hint: "Any info related to the item.",
          multiline: true,
        ),
      ],
    );
  }

  // Builds Unit, Quantity, Low stock limit fields
  Widget buildUQLField({
    required AddItemViewModel vm,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const SizedBox(height: 20),

        CLabel(text: "UNIT", requiredField: isRequired),

        CDropDown(
          value: vm.selectedUnit,
          valueList: vm.unitItems,
          type: "UNIT",
          onChanged: vm.setUnit,
        ),

        _CNumberField(
          requiredField: isRequired,
          label: "CURRENT QUANTITY",
          hint: "e.g. 5 or 2.5",
          isDecimal: true,
          controller: vm.quantityTEC,
          iconData: Icons.inventory_2_outlined,
        ),

        _CNumberField(
          requiredField: vm.selectedCategory!.categoryName == "Medicines"
              ? false
              : isRequired,
          label: "LOW STOCK LIMIT",
          hint: "e.g. 7 or 3.5",
          isDecimal: true,
          controller: vm.lowStockTEC,
          iconData: Icons.production_quantity_limits_outlined,
        ),
      ],
    );
  }

  // Builds purchase date, warranty/expiry date fields
  Widget buildPWFields({
    required AddItemViewModel vm,
    required bool isRequired,
    String labelDate1 = "PURCHASE DATE",
    String labelDate2 = "WARRANTY/EXPIRY DATE",
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _CDateField(
          requiredField: isRequired,
          label: labelDate1,
          prefixIconData: Icons.calendar_today,
          controller: TextEditingController(text: vm.purchaseDateFormatted),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: vm.purchaseDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(DateTime.now().year + 100),
            );

            if (picked != null) {
              vm.setPurchaseDate(picked);
            }
          },
        ),

        _CDateField(
          requiredField: isRequired,
          label: labelDate2,
          prefixIconData: Icons.verified_user_rounded,
          controller: TextEditingController(text: vm.warrantyDateFormatted),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: vm.warrantyDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(DateTime.now().year + 100),
            );

            if (picked != null) {
              vm.setExpirtOrWarrantyDate(picked);
            }
          },
        ),
      ],
    );
  }

  Future<void> showAddRoomDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const AddEditRoomDialog(),
    );
  }

  Future<ImageSourceType?> showImageSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSourceType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Camera option
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Camera"),
                  onTap: () {
                    Navigator.pop(context, ImageSourceType.camera);
                  },
                ),

                // Gallery option
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text("Gallery"),
                  onTap: () {
                    Navigator.pop(context, ImageSourceType.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom Painter for Dashed Border
class _CDashedRectPainter extends CustomPainter {
  final Color color;
  _CDashedRectPainter({this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 5;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(30),
    );
    Path path = Path()..addRRect(rrect);

    for (
      double i = 0;
      i < path.computeMetrics().first.length;
      i += dashWidth + dashSpace
    ) {
      canvas.drawPath(
        path.computeMetrics().first.extractPath(i, i + dashWidth),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Stateless Widgets
class _CNumberField extends StatelessWidget {
  final String label;
  final String hint;
  final bool isDecimal;
  final TextEditingController controller;
  final IconData iconData;
  final bool requiredField;

  const _CNumberField({
    required this.label,
    required this.hint,
    required this.isDecimal,
    required this.controller,
    required this.iconData,
    required this.requiredField,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const SizedBox(height: 20),

        CLabel(text: label, requiredField: requiredField),

        CTextFormField(
          controller: controller,
          prefixIconData: iconData,
          hint: hint,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
      ],
    );
  }
}

class _CDateField extends StatelessWidget {
  final String label;
  final IconData prefixIconData;
  final TextEditingController controller;
  final VoidCallback onTap;
  final bool requiredField;

  const _CDateField({
    required this.label,
    required this.prefixIconData,
    required this.controller,
    required this.onTap,
    required this.requiredField,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const SizedBox(height: 20),

        CLabel(text: label, requiredField: requiredField),

        CTextFormField(
          prefixIconData: prefixIconData,
          hint: "dd/mm/yyyy",
          suffixIcon: Icons.calendar_month,
          controller: controller,
          onTap: () async {
            onTap();
          },
        ),
      ],
    );
  }
}

class _DefaultRoom extends StatelessWidget {
  final String roomName;
  const _DefaultRoom({required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surface,
        shadowColor: Theme.of(context).colorScheme.shadow,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Row(
            children: [
              Icon(Icons.room, color: Colors.blueGrey.shade300),
              SizedBox(width: 20),
              Text(
                roomName,
                overflow: .ellipsis,
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }
}
