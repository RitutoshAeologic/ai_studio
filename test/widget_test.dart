import 'package:flutter_test/flutter_test.dart';
import 'package:ai_studio/app/app.dart';
import 'package:ai_studio/core/constants/app_strings.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AiStudioApp());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.welcomeBack), findsOneWidget);
  });
}
