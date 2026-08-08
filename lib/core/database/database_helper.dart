import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 100% 本地存储数据库服务 (SQLite)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pocket_budget.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. 分类表
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        icon_name $textType,
        color_hex $textType,
        type $textType,
        is_custom INTEGER DEFAULT 0
      )
    ''');

    // 2. 交易记录表
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        amount $numType,
        type $textType,
        category_id $textType,
        category_name $textType,
        category_icon $textType,
        date $intType,
        note TEXT
      )
    ''');

    // 3. 存钱计划表
    await db.execute('''
      CREATE TABLE savings_goals (
        id $idType,
        title $textType,
        target_amount $numType,
        current_amount $numType DEFAULT 0,
        target_date $intType,
        created_at $intType
      )
    ''');

    // 4. 存钱/提取明细流水表 (新增)
    await db.execute('''
      CREATE TABLE savings_logs (
        id $idType,
        goal_id $textType,
        amount $numType,
        note TEXT,
        created_at $intType,
        deduct_from_budget INTEGER NOT NULL DEFAULT 0,
        linked_transaction_id TEXT
      )
    ''');

    // 5. 预算表
    await db.execute('''
      CREATE TABLE budgets (
        period $idType,
        total_budget $numType
      )
    ''');

    await db.execute('CREATE INDEX savings_logs_goal_created_idx ON savings_logs(goal_id, created_at DESC)');
    await db.execute('CREATE UNIQUE INDEX savings_logs_linked_transaction_idx ON savings_logs(linked_transaction_id) WHERE linked_transaction_id IS NOT NULL');

    // 初始化默认分类
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_logs (
          id TEXT PRIMARY KEY,
          goal_id TEXT NOT NULL,
          amount REAL NOT NULL,
          note TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE savings_logs ADD COLUMN deduct_from_budget INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE savings_logs ADD COLUMN linked_transaction_id TEXT');
      await db.execute('CREATE INDEX IF NOT EXISTS savings_logs_goal_created_idx ON savings_logs(goal_id, created_at DESC)');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS savings_logs_linked_transaction_idx ON savings_logs(linked_transaction_id) WHERE linked_transaction_id IS NOT NULL');

      final logs = await db.query('savings_logs', columns: ['id']);
      for (final log in logs) {
        final transactionId = 'tx_savings_${log['id']}';
        final matches = await db.query('transactions', columns: ['id'], where: 'id = ?', whereArgs: [transactionId], limit: 1);
        if (matches.isNotEmpty) {
          await db.update('savings_logs', {'deduct_from_budget': 1, 'linked_transaction_id': transactionId}, where: 'id = ?', whereArgs: [log['id']]);
        }
      }
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaults = [
      {'id': 'cat_food', 'name': '餐饮', 'icon_name': 'fastfood', 'color_hex': '#FF7675', 'type': 'EXPENSE'},
      {'id': 'cat_transport', 'name': '交通', 'icon_name': 'directions_bus', 'color_hex': '#74B9FF', 'type': 'EXPENSE'},
      {'id': 'cat_shopping', 'name': '购物', 'icon_name': 'shopping_bag', 'color_hex': '#A29BFE', 'type': 'EXPENSE'},
      {'id': 'cat_housing', 'name': '居住', 'icon_name': 'home', 'color_hex': '#FFEAA7', 'type': 'EXPENSE'},
      {'id': 'cat_entertainment', 'name': '娱乐', 'icon_name': 'sports_esports', 'color_hex': '#FD79A8', 'type': 'EXPENSE'},
      {'id': 'cat_salary', 'name': '工资收入', 'icon_name': 'account_balance_wallet', 'color_hex': '#55E6C1', 'type': 'INCOME'},
      {'id': 'cat_bonus', 'name': '理财/奖金', 'icon_name': 'trending_up', 'color_hex': '#00CEC9', 'type': 'INCOME'},
    ];

    for (var cat in defaults) {
      await db.insert('categories', cat);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
