import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper helper;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    helper = DatabaseHelper.instance;
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
  });

  test('creates the complete v5 schema', () async {
    final db = await _openDatabase();

    await helper.createSchemaForTest(db);

    final goalColumns = await db.rawQuery('PRAGMA table_info(savings_goals)');
    final allocationTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'budget_allocations'",
    );

    expect(
      goalColumns.map((column) => column['name']),
      contains('status'),
    );
    expect(allocationTables, hasLength(1));
    expect(
      await db.query('budget_allocations'),
      isEmpty,
    );
    await db.close();
  });

  test('migrates linked legacy savings transactions into allocations',
      () async {
    final db = await _openLegacyDatabase(includeLegacyColumns: true);
    final createdAt = DateTime(2026, 8, 4).millisecondsSinceEpoch;

    await db.insert('savings_logs', {
      'id': 'save-linked',
      'goal_id': 'goal-1',
      'amount': 600.0,
      'note': 'monthly saving',
      'created_at': createdAt,
      'deduct_from_budget': 1,
      'linked_transaction_id': 'tx_savings_save-linked',
    });
    await db.insert('transactions', {
      'id': 'tx_savings_save-linked',
      'amount': 600.0,
      'type': 'EXPENSE',
      'category_id': 'cat_savings',
      'category_name': '存钱',
      'category_icon': 'savings',
      'date': createdAt,
      'note': 'legacy pseudo transaction',
    });

    await helper.upgradeSchemaForTest(db, 4, 5);

    final allocations = await db.query('budget_allocations');
    final logs = await db.query('savings_logs');
    final transactions = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: ['tx_savings_save-linked'],
    );

    expect(allocations, hasLength(1));
    expect(allocations.single['period'], '2026-08');
    expect(allocations.single['allocated_amount'], 600.0);
    expect(logs.single['deduct_from_budget'], 0);
    expect(logs.single['linked_transaction_id'], isNull);
    expect(transactions, isEmpty);
    await db.close();
  });

  test('preserves unrelated transactions during migration', () async {
    final db = await _openLegacyDatabase(includeLegacyColumns: true);
    final createdAt = DateTime(2026, 8, 4).millisecondsSinceEpoch;

    await db.insert('savings_logs', {
      'id': 'save-orphan',
      'goal_id': 'goal-1',
      'amount': 300.0,
      'note': null,
      'created_at': createdAt,
      'deduct_from_budget': 1,
      'linked_transaction_id': null,
    });
    await db.insert('transactions', {
      'id': 'real-expense-1',
      'amount': 300.0,
      'type': 'EXPENSE',
      'category_id': 'cat_food',
      'category_name': '餐饮',
      'category_icon': 'fastfood',
      'date': createdAt,
      'note': 'unrelated real expense',
    });

    await helper.upgradeSchemaForTest(db, 4, 5);

    expect(await db.query('budget_allocations'), hasLength(1));
    expect(
      await db.query('transactions',
          where: 'id = ?', whereArgs: ['real-expense-1']),
      hasLength(1),
    );
    await db.close();
  });

  test('repairs incomplete legacy savings logs before migrating allocations',
      () async {
    final db = await _openLegacyDatabase(includeLegacyColumns: false);
    final createdAt = DateTime(2026, 8, 4).millisecondsSinceEpoch;

    await db.insert('savings_logs', {
      'id': 'save-incomplete',
      'goal_id': 'goal-1',
      'amount': 250.0,
      'note': null,
      'created_at': createdAt,
    });
    await db.insert('transactions', {
      'id': 'tx_savings_save-incomplete',
      'amount': 250.0,
      'type': 'EXPENSE',
      'category_id': 'cat_savings',
      'category_name': '存钱',
      'category_icon': 'savings',
      'date': createdAt,
      'note': 'legacy pseudo transaction',
    });

    await helper.upgradeSchemaForTest(db, 3, 5);

    final logs = await db.query('savings_logs');
    expect(logs.single['deduct_from_budget'], 0);
    expect(logs.single['linked_transaction_id'], isNull);
    expect(await db.query('budget_allocations'), hasLength(1));
    expect(
      await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: ['tx_savings_save-incomplete'],
      ),
      isEmpty,
    );
    await db.close();
  });

  test('is idempotent when the migration callback runs twice', () async {
    final db = await _openLegacyDatabase(includeLegacyColumns: true);
    final createdAt = DateTime(2026, 8, 4).millisecondsSinceEpoch;

    await db.insert('savings_logs', {
      'id': 'save-repeat',
      'goal_id': 'goal-1',
      'amount': 450.0,
      'note': null,
      'created_at': createdAt,
      'deduct_from_budget': 1,
      'linked_transaction_id': null,
    });

    await helper.upgradeSchemaForTest(db, 4, 5);
    await helper.upgradeSchemaForTest(db, 4, 5);

    expect(await db.query('budget_allocations'), hasLength(1));
    expect((await db.query('savings_logs')).single['deduct_from_budget'], 0);
    await db.close();
  });
}

Future<Database> _openDatabase() {
  return databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
}

Future<Database> _openLegacyDatabase(
    {required bool includeLegacyColumns}) async {
  final db = await _openDatabase();
  await db.execute('''
    CREATE TABLE transactions (
      id TEXT PRIMARY KEY,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category_id TEXT NOT NULL,
      category_name TEXT NOT NULL,
      category_icon TEXT NOT NULL,
      date INTEGER NOT NULL,
      note TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE savings_goals (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL NOT NULL DEFAULT 0,
      target_date INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
  if (includeLegacyColumns) {
    await db.execute('''
      CREATE TABLE savings_logs (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        deduct_from_budget INTEGER NOT NULL DEFAULT 0,
        linked_transaction_id TEXT
      )
    ''');
  } else {
    await db.execute('''
      CREATE TABLE savings_logs (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }
  return db;
}
