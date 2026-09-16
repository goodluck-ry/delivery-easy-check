// 基础冒烟测试：验证应用骨架能正常构建并显示底部导航。
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_express/main.dart';

void main() {
  testWidgets('App renders bottom navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusExpressApp());

    // 应该能看到两个导航项标签
    expect(find.text('我的快递'), findsWidgets);
    expect(find.text('查询'), findsWidgets);
  });
}
