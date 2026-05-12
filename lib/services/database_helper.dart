import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../owner_web/products/product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('perfumes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        price REAL NOT NULL,
        size TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        stock INTEGER NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertProduct(ProductModel product) async {
    final db = await instance.database;
    await db.insert(
      'products',
      {
        'id': product.id,
        'name': product.name,
        'brand': product.brand,
        'price': product.price,
        'size': product.size,
        'category': product.category,
        'description': product.description,
        'stock': product.stock,
        'isSynced': product.isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');

    return result.map((json) => ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      price: json['price'] as double,
      size: json['size'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      stock: json['stock'] as int,
      isSynced: (json['isSynced'] as int) == 1,
    )).toList();
  }

  Future<void> updateProduct(ProductModel product) async {
    final db = await instance.database;
    await db.update(
      'products',
      {
        'name': product.name,
        'brand': product.brand,
        'price': product.price,
        'size': product.size,
        'category': product.category,
        'description': product.description,
        'stock': product.stock,
        'isSynced': product.isSynced ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('products');
  }
}
