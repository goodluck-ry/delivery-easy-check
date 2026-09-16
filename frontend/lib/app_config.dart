// 编译期功能开关（dart-define 控制）。
//
// 调试与投放共用一套代码，不成熟或不想对外暴露的功能用开关包裹。
// 默认值取调试态（全开），发布时用 --dart-define 关闭对应开关。
//
// 用法：
//   flutter run --dart-define=ENABLE_BIND_FLOW=false
//   flutter build apk --release --dart-define=ENABLE_LOCAL_SMS=false
//
// 代码里读 AppConfig.enableXxx；开关值为编译期常量，关闭的功能
// 在 if (AppConfig.enableXxx) 分支里会被 tree-shaking 移除，不进包。

class AppConfig {
  AppConfig._();

  /// 本地模拟验证码绑定流程（输号→收码→验证→绑定）。
  /// 关闭则跳过绑定直接进首页。DAY5 task 22 落地后消费。
  static const bool enableBindFlow =
      bool.fromEnvironment('ENABLE_BIND_FLOW', defaultValue: true);

  /// 本地短信读取与解析（READ_SMS 收件箱扫描 + Dart 解析引擎）。
  /// 关闭则不申请短信权限、不读收件箱。DAY5 task 24+ 落地后消费。
  static const bool enableLocalSms =
      bool.fromEnvironment('ENABLE_LOCAL_SMS', defaultValue: true);
}
