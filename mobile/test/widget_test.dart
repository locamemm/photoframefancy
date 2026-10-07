import 'package:flutter_test/flutter_test.dart';
import 'package:photo_frame_mobile/main.dart';

void main() {
  testWidgets('PhotoFrameFancyApp loads cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoFrameFancyApp());
    expect(find.text('PhotoFrameFancy'), findsOneWidget);
  });
}
