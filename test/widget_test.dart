// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ilium_app/models/user_model.dart';
import 'package:ilium_app/models/progression_model.dart';
import 'package:ilium_app/models/freemium_limitations_model.dart';

void main() {
  group('Model Tests', () {
    test('UserModel creation', () {
      final progression = GlobalProgressionModel(
        totalXp: 100,
        currentLevel: 1,
        xpToNextLevel: 900,
        tier: UserTier.bronze,
        totalCoursCompleted: 5,
        totalQcmPassed: 10,
        totalStreakDays: 3,
        maxStreakDays: 7,
        currentStreak: 2,
        memberSince: DateTime.now(),
        lastLoginDate: DateTime.now(),
        subjectProgressions: {},
        achievements: [],
        overallAverageScore: 85.0,
      );

      final user = UserModel(
        uid: 'test-uid',
        pseudo: 'TestUser',
        email: 'test@example.com',
        niveau: 'Sixième',
        status: UserStatus.active,
        subscriptionType: SubscriptionType.free,
        badges: [],
        progression: progression,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: {'darkMode': false},
        limitations: FreemiumLimitationsModel.free(),
      );

      expect(user.uid, equals('test-uid'));
      expect(user.pseudo, equals('TestUser'));
      expect(user.niveau, equals('Sixième'));
      expect(user.progression.totalXp, equals(100));
    });

    test('FreemiumLimitationsModel creation', () {
      final limitations = FreemiumLimitationsModel.free();
      
      expect(limitations.maxCoursesPerDay, equals(3));
      expect(limitations.maxQcmPerDay, equals(5));
      expect(limitations.hasAdsRemoved, isFalse);
      expect(limitations.canDownloadPdf, isFalse);
    });
  });

  testWidgets('Basic widget creation test', (WidgetTester tester) async {
    // Test basic widget creation without Firebase
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Test')),
          body: const Center(child: Text('Hello World')),
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
  });
}
