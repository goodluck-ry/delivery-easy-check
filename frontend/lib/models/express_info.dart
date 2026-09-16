// 快递信息数据模型。
// 字段与本地 ExpressStore 表对应；fromJson/toJson 保留兼容后端（DAY5 后端搁置）。

class ExpressInfo {
  final int id;
  final String phone;
  final String company;
  final String station;
  final String pickUpCode;
  final int status; // 0 未取，1 已取
  final DateTime updatedAt;
  final DateTime? createdAt; // 本地入库时间（抓取时间），后端无此字段
  final DateTime? smsDate; // 短信送达时间（telephony m.date），比抓取时间更有价值

  const ExpressInfo({
    required this.id,
    required this.phone,
    required this.company,
    required this.station,
    required this.pickUpCode,
    required this.status,
    required this.updatedAt,
    this.createdAt,
    this.smsDate,
  });

  factory ExpressInfo.fromJson(Map<String, dynamic> json) {
    return ExpressInfo(
      id: json['id'] as int,
      phone: json['phone'] as String,
      company: json['company'] as String,
      station: json['station'] as String,
      pickUpCode: json['pickup_code'] as String,
      status: json['status'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'company': company,
      'station': station,
      'pickup_code': pickUpCode,
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 便捷拷贝：切换取件状态时用，避免手写一堆字段。
  ExpressInfo copyWith({
    int? id,
    String? phone,
    String? company,
    String? station,
    String? pickUpCode,
    int? status,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? smsDate,
  }) {
    return ExpressInfo(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      station: station ?? this.station,
      pickUpCode: pickUpCode ?? this.pickUpCode,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      smsDate: smsDate ?? this.smsDate,
    );
  }

  bool get isPicked => status == 1;
}
