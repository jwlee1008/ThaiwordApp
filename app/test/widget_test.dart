import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:korthai_words/main.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> tapQuizTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('quiz_tab')));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> tapSettingsTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('settings_tab')));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> tapWordListQuizButton(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, '퀴즈'));
}

Set<String> _choiceTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(QuizChoiceButton),
          matching: find.byType(Text),
        ),
      )
      .map((widget) => widget.data)
      .whereType<String>()
      .toSet();
}

String _visibleQuestionAnswer(VocabularyData data) {
  for (final word in data.words) {
    if (find.text(word.korean).hitTestable().evaluate().isNotEmpty) {
      return word.thaiShort;
    }
  }
  throw StateError('No visible quiz question found.');
}

String _visibleThaiToKoreanAnswer(VocabularyData data) {
  for (final word in data.words) {
    if (find.text(word.thaiShort).hitTestable().evaluate().isNotEmpty) {
      return word.korean;
    }
  }
  throw StateError('No visible Thai to Korean quiz question found.');
}

Future<void> answerVisibleQuestion(
  WidgetTester tester,
  VocabularyData data,
) async {
  await tester.tap(
    find.descendant(
      of: find.byType(QuizChoiceButton),
      matching: find.text(_visibleQuestionAnswer(data)),
    ),
  );
  await tester.pump();
}

Future<void> answerVisibleThaiToKoreanQuestion(
  WidgetTester tester,
  VocabularyData data,
) async {
  await tester.tap(
    find.descendant(
      of: find.byType(QuizChoiceButton),
      matching: find.text(_visibleThaiToKoreanAnswer(data)),
    ),
  );
  await tester.pump();
}

Future<void> answerVisibleQuestionIncorrectly(
  WidgetTester tester,
  VocabularyData data,
) async {
  final correctAnswer = _visibleQuestionAnswer(data);
  final wrongAnswer = _choiceTexts(tester).firstWhere(
    (choice) => choice != correctAnswer,
  );

  await tester.tap(
    find.descendant(
      of: find.byType(QuizChoiceButton),
      matching: find.text(wrongAnswer),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'interface_language': 'ko',
      'onboarding_complete': true,
    });
  });

  const sampleData = VocabularyData(
    categories: [
      Category(
        id: 'school_life',
        ko: '초급',
        th: 'ชีวิตในโรงเรียน',
        description: '학교, 수업, 공부',
      ),
    ],
    words: [
      WordEntry(
        id: 'krdict_73276',
        korean: '학교',
        thai: 'โรงเรียน, สถาบันศึกษา',
        thaiShort: 'โรงเรียน, สถาบันศึกษา',
        pronunciation: '학꾜',
        partOfSpeechKo: '명사',
        levelKo: '초급',
        definitionKo: '일정한 목적에 따라 학생을 교육하는 기관.',
        thaiDefinition: 'สถานศึกษา',
        categories: ['school_life', 'topik_beginner'],
        tags: ['place'],
      ),
      WordEntry(
        id: 'krdict_31670',
        korean: '학생',
        thai: 'นักเรียน',
        thaiShort: 'นักเรียน',
        pronunciation: '학쌩',
        partOfSpeechKo: '명사',
        levelKo: '초급',
        definitionKo: '학교에 다니면서 공부하는 사람.',
        thaiDefinition: 'นักเรียน',
        categories: ['school_life', 'topik_beginner'],
        tags: ['person'],
      ),
      WordEntry(
        id: 'krdict_advanced_sample',
        korean: '개념',
        thai: 'แนวคิด',
        thaiShort: 'แนวคิด',
        pronunciation: '개념',
        partOfSpeechKo: '명사',
        levelKo: '고급',
        definitionKo: '어떤 사물이나 현상에 대한 일반적인 지식.',
        thaiDefinition: 'แนวคิด',
        categories: ['academic'],
        tags: ['abstract'],
      ),
    ],
  );

  const quizData = VocabularyData(
    categories: [
      Category(
        id: 'daily',
        ko: '초급',
        th: 'ชีวิตประจำวัน',
        description: '기초 단어',
      ),
    ],
    words: [
      WordEntry(
        id: 'quiz_1',
        korean: '학교',
        thai: 'โรงเรียน',
        thaiShort: 'โรงเรียน',
        pronunciation: '학꾜',
        partOfSpeechKo: '명사',
        levelKo: '초급',
        definitionKo: '학생을 교육하는 기관.',
        thaiDefinition: 'สถานศึกษา',
        categories: ['daily'],
        tags: ['place'],
      ),
      WordEntry(
        id: 'quiz_2',
        korean: '학생',
        thai: 'นักเรียน',
        thaiShort: 'นักเรียน',
        pronunciation: '학쌩',
        partOfSpeechKo: '명사',
        levelKo: '초급',
        definitionKo: '학교에서 공부하는 사람.',
        thaiDefinition: 'นักเรียน',
        categories: ['daily'],
        tags: ['person'],
      ),
      WordEntry(
        id: 'quiz_3',
        korean: '책',
        thai: 'หนังสือ',
        thaiShort: 'หนังสือ',
        pronunciation: '책',
        partOfSpeechKo: '명사',
        levelKo: '초급',
        definitionKo: '글이나 그림을 묶은 것.',
        thaiDefinition: 'หนังสือ',
        categories: ['daily'],
        tags: ['object'],
      ),
      WordEntry(
        id: 'quiz_4',
        korean: '물',
        thai: 'น้ำ',
        thaiShort: 'น้ำ',
        pronunciation: '물',
        partOfSpeechKo: '명사',
        levelKo: '초급',
        definitionKo: '마시는 액체.',
        thaiDefinition: 'น้ำ',
        categories: ['daily'],
        tags: ['food'],
      ),
      WordEntry(
        id: 'quiz_5',
        korean: '밥',
        thai: 'ข้าว',
        thaiShort: 'ข้าว',
        pronunciation: '밥',
        partOfSpeechKo: '명사',
        levelKo: '초급',
        definitionKo: '끼니로 먹는 음식.',
        thaiDefinition: 'ข้าว',
        categories: ['daily'],
        tags: ['food'],
      ),
      WordEntry(
        id: 'quiz_6',
        korean: '집',
        thai: 'บ้าน',
        thaiShort: 'บ้าน',
        pronunciation: '집',
        partOfSpeechKo: '명사',
        levelKo: '초급',
        definitionKo: '사람이 사는 곳.',
        thaiDefinition: 'บ้าน',
        categories: ['daily'],
        tags: ['place'],
      ),
    ],
  );

  testWidgets('loads difficulty decks', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    expect(find.text('KorThai Words'), findsWidgets);
    expect(find.text('현재 코스'), findsOneWidget);
    expect(find.text('초급 첫걸음'), findsWidgets);
    expect(find.text('학습률 0%'), findsWidgets);
    expect(find.text('3 words'), findsOneWidget);
    expect(find.text('학습 로드맵'), findsOneWidget);
    expect(find.textContaining('다음 업데이트에서 열릴 예정'), findsNothing);
  });

  testWidgets('starts in Thai when no language preference is saved',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('เริ่มจากระดับที่เหมาะกับคุณ'));

    expect(find.text('เริ่มจากระดับที่เหมาะกับคุณ'), findsOneWidget);
    expect(find.text('ข้ามและเริ่มระดับต้น'), findsOneWidget);
  });

  testWidgets('skips placement test and opens beginner course',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'interface_language': 'ko',
    });

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('나에게 맞는 단계부터 시작'));

    await tester.tap(find.text('건너뛰고 초급부터'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('현재 코스'), findsOneWidget);
    expect(find.text('초급 첫걸음'), findsWidgets);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('onboarding_complete'), isTrue);
    expect(preferences.getString('course_stage_id'), 'beginner_foundation');
  });

  testWidgets('opens word list from difficulty deck',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('학교'), findsOneWidget);
    expect(find.text('학생'), findsOneWidget);
  });

  testWidgets('opens today review words', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'interface_language': 'ko',
      'onboarding_complete': true,
      'wrong_word_ids': <String>['krdict_31670'],
      'memory_ratings': <String>['krdict_73276:unsure'],
    });

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('오늘의 복습'));

    expect(find.text('오답과 애매한 단어 우선 · 2개'), findsOneWidget);

    await tester.tap(find.text('오늘의 복습'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오늘 먼저 볼 단어'), findsOneWidget);
    expect(find.text('학생'), findsOneWidget);
    expect(find.text('학교'), findsOneWidget);
    expect(find.text('카드 연습'), findsOneWidget);
  });

  testWidgets('answers a quiz question', (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tapWordListQuizButton(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('한국어 뜻 고르기'), findsOneWidget);

    await answerVisibleQuestion(tester, sampleData);

    expect(find.text('정답입니다'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('shows quiz result after final question',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tapWordListQuizButton(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await answerVisibleQuestion(tester, sampleData);
    await tester.tap(find.text('다음 문제'));
    await tester.pump();

    await answerVisibleQuestion(tester, sampleData);
    await tester.tap(find.text('결과 보기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('퀴즈 완료'), findsOneWidget);
    expect(find.text('2/2 · 100%'), findsOneWidget);
  });

  testWidgets('retries quiz from result screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tapWordListQuizButton(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await answerVisibleQuestion(tester, sampleData);
    await tester.tap(find.text('다음 문제'));
    await tester.pump();

    await answerVisibleQuestion(tester, sampleData);
    await tester.tap(find.text('결과 보기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('다시 풀기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('한국어 뜻 고르기'), findsOneWidget);
    expect(find.text('0/2'), findsOneWidget);
  });

  testWidgets('adds a favorite word', (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('즐겨찾기').first);
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('즐겨찾기'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('adds wrong answer to wrong note', (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tapWordListQuizButton(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await answerVisibleQuestionIncorrectly(tester, sampleData);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오답노트'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('removes a word from wrong note with check button',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'interface_language': 'ko',
      'onboarding_complete': true,
      'wrong_word_ids': <String>['krdict_31670'],
    });

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    await tester.tap(find.text('오답노트'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('학생'), findsOneWidget);

    await tester.tap(find.byTooltip('오답 제거'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('학생'), findsNothing);
  });

  testWidgets('restores saved study state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'interface_language': 'ko',
      'onboarding_complete': true,
      'favorite_word_ids': <String>['krdict_73276'],
      'wrong_word_ids': <String>['krdict_31670'],
    });

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    expect(find.text('즐겨찾기'), findsOneWidget);
    expect(find.text('오답노트'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
  });

  testWidgets('shows difficulty progress from saved state',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'interface_language': 'ko',
      'onboarding_complete': true,
      'seen_word_ids': <String>['krdict_73276'],
      'correct_word_ids': <String>['krdict_73276'],
    });

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    expect(find.textContaining('학습률 50% · 퀴즈 정답률 0/0 (0%)'), findsWidgets);
    expect(find.textContaining('다음 단계까지: 퀴즈 10문제 더'), findsWidgets);
  });

  testWidgets('opens quiz tab with multiple quiz types',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: quizData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    await tapQuizTab(tester);

    expect(find.text('퀴즈'), findsWidgets);
    expect(find.text('한국어 → 태국어 뜻'), findsWidgets);
    expect(find.text('태국어 뜻 → 한국어'), findsWidgets);
    expect(find.text('듣고 뜻 고르기'), findsWidgets);
  });

  testWidgets('locks quiz decks above the current course',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    await tapQuizTab(tester);

    expect(find.text('초급 첫걸음'), findsWidgets);
    expect(find.text('이전 단계 목표 달성 후 열림'), findsWidgets);
  });

  testWidgets('starts Thai to Korean quiz from quiz tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: quizData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    await tapQuizTab(tester);
    await tester.tap(find.text('태국어 뜻 → 한국어').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('한국어 단어 고르기'), findsOneWidget);
    expect(find.byType(QuizChoiceButton), findsNWidgets(4));

    await answerVisibleThaiToKoreanQuestion(tester, quizData);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('quiz_attempts_by_stage'),
      contains('beginner_foundation:1'),
    );
    expect(
      preferences.getStringList('quiz_correct_by_stage'),
      contains('beginner_foundation:1'),
    );
  });

  testWidgets('opens data attribution screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    await tapSettingsTab(tester);
    await tester.scrollUntilVisible(
      find.text('출처 및 라이선스'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -220),
    );
    await tester.pump();
    final attributionTile = find.ancestor(
      of: find.text('출처 및 라이선스'),
      matching: find.byType(ListTile),
    );
    await tester.tap(attributionTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('출처 및 라이선스'), findsWidgets);
    expect(find.text('국립국어원 한국어기초사전'), findsWidgets);
    expect(find.text('3개'), findsWidgets);
    expect(find.textContaining('https://krdict.korean.go.kr'), findsWidgets);
  });

  testWidgets('does not show standalone level quiz on the study tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: quizData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    expect(find.text('난이도별 퀴즈'), findsNothing);
    expect(find.text('초급 퀴즈'), findsNothing);
  });

  testWidgets('uses unique quiz choices', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: quizData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tapWordListQuizButton(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final firstChoices = _choiceTexts(tester);
    expect(firstChoices, hasLength(4));

    await answerVisibleQuestion(tester, quizData);
    await tester.tap(find.text('다음 문제'));
    await tester.pump();

    final secondChoices = _choiceTexts(tester);
    expect(secondChoices, hasLength(4));
  });

  testWidgets('shows Korean speech controls on word card',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('카드 연습'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('한국어 발음 듣기'), findsWidgets);
  });

  testWidgets('sets memory rating from word card', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('초급 첫걸음'));

    await tester.tap(find.text('초급 첫걸음').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('카드 연습'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('이 단어, 얼마나 기억나요?'), findsOneWidget);
    await tester.tap(find.text('몰라요'));
    await tester.pump();

    var preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('memory_ratings'),
      contains('krdict_73276:hard'),
    );
    expect(
      preferences.getStringList('wrong_word_ids'),
      contains('krdict_73276'),
    );

    await tester.tap(find.text('알아요'));
    await tester.pump();

    preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('memory_ratings'),
      contains('krdict_73276:known'),
    );
    expect(
      preferences.getStringList('correct_word_ids'),
      contains('krdict_73276'),
    );
    expect(
      preferences.getStringList('wrong_word_ids') ?? const <String>[],
      isNot(contains('krdict_73276')),
    );
  });

  testWidgets('changes interface language to Thai',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    await tapSettingsTab(tester);
    await tester.tap(find.byKey(const ValueKey('language_th_option')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ตั้งค่า'), findsWidgets);
    expect(find.text('ภาษาอินเทอร์เฟซ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('study_tab')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('คอร์สปัจจุบัน'), findsOneWidget);
    expect(find.text('ต้น · ก้าวแรก'), findsWidgets);
  });

  testWidgets('keeps course changes locked in settings',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    await tapSettingsTab(tester);

    expect(find.text('학습 코스 변경은 잠겨 있습니다'), findsOneWidget);
    expect(find.byKey(const ValueKey('course_beginner_foundation')),
        findsOneWidget);
  });

  testWidgets('opens settings and resets study state',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'interface_language': 'ko',
      'onboarding_complete': true,
      'favorite_word_ids': <String>['krdict_73276'],
      'wrong_word_ids': <String>['krdict_31670'],
      'seen_word_ids': <String>['krdict_73276'],
      'correct_word_ids': <String>['krdict_73276'],
    });

    await tester.pumpWidget(const ThaiKoreanWordApp(initialData: sampleData));
    await pumpUntilFound(tester, find.text('현재 코스'));

    await tapSettingsTab(tester);

    expect(find.text('설정'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('학습 상태'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('학습 상태'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('학습 기록 초기화'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('학습 기록 초기화'), findsOneWidget);
    expect(find.text('1개'), findsNWidgets(4));
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -160),
    );
    await tester.pump();

    final resetTile = find.ancestor(
      of: find.text('학습 기록 초기화'),
      matching: find.byType(ListTile),
    );
    await tester.tap(resetTile);
    await tester.pump();
    expect(find.text('즐겨찾기, 오답노트, 진행률을 모두 지웁니다.'), findsOneWidget);

    await tester.tap(find.text('초기화'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('0개'), findsNWidgets(4));
    expect(find.text('학습 기록을 초기화했습니다'), findsOneWidget);
  });
}
