import 'dart:core';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------- Shared Preference KEYS ----------------------------
final String notifyLowStockKey = 'notifyLowStock';
final String notifyExpiryKey = 'notifyExpiry';
final String defaultRoomKey = 'defaultRoom';
final String defaultCategoryKey = 'defaultCategory';
final String lowStockLimitKey = 'lowStockLimit';

final Logger logger = Logger();

// ########################### Room Icon List and Map ###########################

final List<IconData> iconsListRoom = [
  // 5
  Icons.bed_outlined, // Bedroom
  Icons.kitchen_outlined, // Kitchen
  Icons.bathtub_outlined, // Bathroom, Shower Room
  Icons.tv_outlined, // Hall / Common Room
  Icons.inventory_2_outlined, // Store room
];

final Map<String, String> roomIconNames = {
  Icons.bed_outlined.codePoint.toString(): 'bedroom',
  Icons.kitchen_outlined.codePoint.toString(): 'kitchen',
  Icons.bathtub_outlined.codePoint.toString(): 'bathroom',
  Icons.tv_outlined.codePoint.toString(): 'hall',
  Icons.inventory_2_outlined.codePoint.toString(): 'store room',
};

// ########################### Category Icon List and Map ###########################

final List<IconData> iconsListCategory = [
  // 7
  Icons.bathtub_outlined, // Bathroom Essentials
  Icons.receipt_long_outlined, // Bills & Recharges
  Icons.tv_outlined, // Electronics Appliances
  Icons.local_grocery_store_outlined, // Grocery
  Icons.content_cut_outlined, // Hair Essentials
  Icons.kitchen_outlined, // Kitchen
  Icons.medical_services_outlined, // Medicines
];

final Map<String, String> categoryIconNames = {
  Icons.bathtub_outlined.codePoint.toString(): 'bathroom essentials',
  Icons.receipt_long_outlined.codePoint.toString(): 'bills & recharges',
  Icons.tv_outlined.codePoint.toString(): 'electronics appliances',
  Icons.local_grocery_store_outlined.codePoint.toString(): 'grocery',
  Icons.content_cut_outlined.codePoint.toString(): 'hair essentials',
  Icons.kitchen_outlined.codePoint.toString(): 'kitchen',
  Icons.medical_services_outlined.codePoint.toString(): 'medicines',
};

class CategoryNames {
  static const String bathroomEssentials = "Bathroom Essentials";
  static const String billsRecharges = "Bills & Recharges";
  static const String electronicAppliances = "Electronic Appliances";
  static const String grocery = "Grocery";
  static const String hairEssentials = "Hair Essentials";
  static const String kitchen = "Kitchen";
  static const String medicines = "Medicines";

  static const List<String> categoryList = [
    "Bathroom Essentials",
    "Bills & Recharges",
    "Electronic Appliances",
    "Grocery",
    "Hair Essentials",
    "Kitchen",
    "Medicines",
  ];
}

// ########################### Color List ###########################

final List<Color> colorsList = [
  // 6
  const Color(0xFFEF5350), // Red
  const Color(0xFFFF7043), // Orange
  const Color.fromARGB(255, 196, 147, 0), // Golden
  const Color(0xFF66BB6A), // Green
  const Color(0xFF42A5F5), // Blue
  const Color(0xFF5C6BC0), // Indigo
];

final List<Color> stockColors = [
  Colors.red, // 0       → Out of Stock
  Colors.orange, // less than min limit
  Colors.green, // more than min limit
];

// ########################### Enums ###########################
enum StockStatus { empty, low, good }

enum ActivityEntityType { item, reminder, room }

enum ActivityActionType { added, updated, deleted }

enum FilterActivity { all, added, updated, deleted }

enum ImageSourceType { camera, gallery }

enum ItemUnit {
  unit,
  piece,

  kg,
  gram,

  litre,
  ml,

  packet,
  box,
  bottle,
  can,

  meter,
  cm,

  dozen,
  pair,

  roll,
  set,
}

// ########################### Common Function ###########################

String formatQuantity(double value) {
  // Used for formatting like this
  // 5 kg
  // 2.5 litre
  // 1 piece
  // 12 dozen
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}

Future<void> saveDefaultLowStockLimit(String key, double value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(key, value);
}


