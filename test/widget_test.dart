import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_movil/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows title and email field', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginScreen())));
    await tester.pump();

    expect(find.text('Pico y Placa EC'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
  });
}
