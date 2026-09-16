// 本地快递数据存储（sqflite）。
//
// DAY5 起数据全本地化：读短信 → 解析 → 存这里 → 首页展示。
// 按短信 _id 去重（sms_id 唯一约束），增量扫描：已入库的短信不会重复插入。
// 不存短信原文，只存解析后结构化字段（隐私：原始短信不入库）。
// sms_date 存短信发送时间，用于按读取周期过滤 + 排序（体验改）。

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/express_info.dart';
import '../parsers/sms_parser.dart';

class ExpressStore {
  ExpressStore._();
  static final ExpressStore instance = ExpressStore._();

  Database? _db;

  Future<Database> _getDb() async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'express.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE express_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sms_id INTEGER UNIQUE NOT NULL,   -- 收件箱短信_id，去重键
            phone TEXT NOT NULL,
            company TEXT NOT NULL,
            station TEXT NOT NULL,
            pickup_code TEXT NOT NULL,
            status INTEGER NOT NULL DEFAULT 0, -- 0 未取，1 已取
            sms_date INTEGER,                 -- 短信发送时间（毫秒），过滤+排序用
            created_at INTEGER NOT NULL,       -- 入库时间（毫秒）
            updated_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // v2 加 sms_date 列；旧数据 sms_date 为 null，queryAll 按 sms_date 过滤会自动排除
          await db.execute(
              'ALTER TABLE express_info ADD COLUMN sms_date INTEGER');
        }
      },
    );
  }

  /// 批量入库：按 sms_id 去重，已存在的短信忽略（增量扫描）。
  /// 返回新插入条数。
  Future<int> upsertAll(
      Iterable<({int smsId, int? smsDate, ParsedSms parsed})> items) async {
    final db = await _getDb();
    final now = DateTime.now().millisecondsSinceEpoch;
    var inserted = 0;
    for (final it in items) {
      final res = await db.insert(
        'express_info',
        {
          'sms_id': it.smsId,
          'phone': it.parsed.phone,
          'company': it.parsed.company,
          'station': it.parsed.station,
          'pickup_code': it.parsed.pickupCode,
          'status': 0,
          'sms_date': it.smsDate,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // sms_id 重复则忽略
      );
      if (res > 0) inserted++;
    }
    return inserted;
  }

  /// 查询：按短信时间 >= sinceMs 过滤，按短信时间降序（最新在前）。
  /// sms_date 为 null 的旧数据（v1 入库的）自动排除。
  Future<List<ExpressInfo>> queryAll(int sinceMs) async {
    final db = await _getDb();
    final rows = await db.query(
      'express_info',
      where: 'sms_date >= ?',
      whereArgs: [sinceMs],
      orderBy: 'sms_date DESC',
    );
    return rows.map(_fromRow).toList();
  }

  /// 更新取件状态。
  Future<void> updateStatus(int id, int status) async {
    final db = await _getDb();
    await db.update(
      'express_info',
      {
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  ExpressInfo _fromRow(Map<String, Object?> row) {
    return ExpressInfo(
      id: row['id'] as int,
      phone: row['phone'] as String,
      company: row['company'] as String,
      station: row['station'] as String,
      pickUpCode: row['pickup_code'] as String,
      status: row['status'] as int,
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      smsDate: row['sms_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['sms_date'] as int)
          : null,
    );
  }
}
