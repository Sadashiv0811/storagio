import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storagio/core/database/db_helper.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await DBHelper.instance.database;
});