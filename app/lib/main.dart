import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ThaiKoreanWordApp());
}

enum InterfaceLanguage {
  ko,
  th,
}

enum MemoryRating {
  hard,
  unsure,
  known,
}

class CourseStage {
  const CourseStage({
    required this.id,
    required this.levelKo,
    required this.step,
    required this.koTitle,
    required this.thTitle,
    required this.koDescription,
    required this.thDescription,
  });

  final String id;
  final String levelKo;
  final int step;
  final String koTitle;
  final String thTitle;
  final String koDescription;
  final String thDescription;

  String title(AppText t) => t.isThai ? thTitle : koTitle;
  String description(AppText t) => t.isThai ? thDescription : koDescription;
}

class CourseCatalog {
  CourseCatalog._();

  static const List<CourseStage> stages = [
    CourseStage(
      id: 'beginner_foundation',
      levelKo: '초급',
      step: 1,
      koTitle: '초급 첫걸음',
      thTitle: 'ต้น · ก้าวแรก',
      koDescription: '처음 시작하는 생활 핵심 단어',
      thDescription: 'คำพื้นฐานสำหรับเริ่มต้นชีวิตประจำวัน',
    ),
    CourseStage(
      id: 'beginner_daily',
      levelKo: '초급',
      step: 2,
      koTitle: '초급 생활',
      thTitle: 'ต้น · ชีวิตประจำวัน',
      koDescription: '일상 대화와 주변 사물 단어',
      thDescription: 'คำที่ใช้ในบทสนทนาและสิ่งรอบตัว',
    ),
    CourseStage(
      id: 'beginner_bridge',
      levelKo: '초급',
      step: 3,
      koTitle: '초급 확장',
      thTitle: 'ต้น · ขยายคำ',
      koDescription: '중급으로 넘어가기 전 확장 단어',
      thDescription: 'คำเสริมก่อนเข้าสู่ระดับกลาง',
    ),
    CourseStage(
      id: 'intermediate_foundation',
      levelKo: '중급',
      step: 1,
      koTitle: '중급 입문',
      thTitle: 'กลาง · เริ่มต้น',
      koDescription: '문장 이해에 필요한 중급 기본 단어',
      thDescription: 'คำพื้นฐานระดับกลางสำหรับอ่านประโยค',
    ),
    CourseStage(
      id: 'intermediate_core',
      levelKo: '중급',
      step: 2,
      koTitle: '중급 핵심',
      thTitle: 'กลาง · แกนหลัก',
      koDescription: '생활, 업무, 학습 맥락의 핵심 단어',
      thDescription: 'คำหลักในชีวิต งาน และการเรียน',
    ),
    CourseStage(
      id: 'intermediate_reading',
      levelKo: '중급',
      step: 3,
      koTitle: '중급 실전',
      thTitle: 'กลาง · ใช้งานจริง',
      koDescription: '읽기와 실전 상황에 쓰는 단어',
      thDescription: 'คำสำหรับการอ่านและสถานการณ์จริง',
    ),
    CourseStage(
      id: 'advanced_foundation',
      levelKo: '고급',
      step: 1,
      koTitle: '고급 입문',
      thTitle: 'สูง · เริ่มต้น',
      koDescription: '고급 읽기를 시작하는 추상 단어',
      thDescription: 'คำเชิงนามธรรมสำหรับเริ่มอ่านระดับสูง',
    ),
    CourseStage(
      id: 'advanced_deep',
      levelKo: '고급',
      step: 2,
      koTitle: '고급 심화',
      thTitle: 'สูง · เจาะลึก',
      koDescription: '사회, 기술, 학술 맥락의 심화 단어',
      thDescription: 'คำลึกในสังคม เทคโนโลยี และวิชาการ',
    ),
    CourseStage(
      id: 'advanced_master',
      levelKo: '고급',
      step: 3,
      koTitle: '고급 완성',
      thTitle: 'สูง · สมบูรณ์',
      koDescription: '긴 글과 시험 대비를 위한 완성 단어',
      thDescription: 'คำสำหรับบทอ่านยาวและการสอบ',
    ),
  ];

  static CourseStage get defaultStage => stages.first;

  static CourseStage byId(String? id) {
    return stages.firstWhere(
      (stage) => stage.id == id,
      orElse: () => defaultStage,
    );
  }

  static int indexOf(CourseStage stage) {
    return stages.indexWhere((candidate) => candidate.id == stage.id);
  }

  static List<WordEntry> wordsForStage(
    CourseStage stage,
    List<WordEntry> words,
  ) {
    final levelWords = words
        .where((word) => stage.levelKo == '초급'
            ? word.levelKo.isEmpty || word.levelKo == '초급'
            : word.levelKo == stage.levelKo)
        .toList()
      ..sort((a, b) {
        final koreanCompare = a.korean.compareTo(b.korean);
        if (koreanCompare != 0) {
          return koreanCompare;
        }
        return a.id.compareTo(b.id);
      });

    if (levelWords.isEmpty) {
      return const [];
    }
    if (levelWords.length < 9) {
      return levelWords;
    }

    final chunkSize = (levelWords.length / 3).ceil();
    final start = (stage.step - 1) * chunkSize;
    if (start >= levelWords.length) {
      return const [];
    }
    final end = (start + chunkSize).clamp(0, levelWords.length);
    return levelWords.sublist(start, end);
  }
}

class CourseStageStats {
  const CourseStageStats({
    required this.wordCount,
    required this.seenCount,
    required this.quizAttempts,
    required this.quizCorrect,
  });

  final int wordCount;
  final int seenCount;
  final int quizAttempts;
  final int quizCorrect;

  int get learningPercent =>
      wordCount == 0 ? 0 : (seenCount / wordCount * 100).round();

  int get quizAccuracyPercent =>
      quizAttempts == 0 ? 0 : (quizCorrect / quizAttempts * 100).round();

  int get requiredAttempts => CourseProgressPolicy.minimumQuizAttempts(
        wordCount,
      );

  int get remainingAttempts =>
      (requiredAttempts - quizAttempts).clamp(0, requiredAttempts);

  bool get canAdvance =>
      wordCount > 0 &&
      quizAttempts >= requiredAttempts &&
      quizAccuracyPercent >= CourseProgressPolicy.requiredQuizAccuracyPercent;
}

class CourseProgressPolicy {
  CourseProgressPolicy._();

  static const int requiredQuizAccuracyPercent = 80;

  static int minimumQuizAttempts(int wordCount) {
    if (wordCount <= 0) {
      return 0;
    }
    return (wordCount * 0.2).ceil().clamp(10, 30);
  }

  static CourseStageStats statsFor(
    CourseStage stage,
    List<WordEntry> allWords,
    StudyState studyState,
  ) {
    final words = CourseCatalog.wordsForStage(stage, allWords);
    return CourseStageStats(
      wordCount: words.length,
      seenCount:
          words.where((word) => studyState.seenIds.contains(word.id)).length,
      quizAttempts: studyState.quizAttemptsForStage(stage.id),
      quizCorrect: studyState.quizCorrectForStage(stage.id),
    );
  }

  static int unlockedStageIndex(
    List<WordEntry> allWords,
    StudyState studyState,
  ) {
    var unlocked = CourseCatalog.indexOf(studyState.courseStage);
    for (var index = 0; index < CourseCatalog.stages.length; index += 1) {
      final stats = statsFor(
        CourseCatalog.stages[index],
        allWords,
        studyState,
      );
      if (stats.canAdvance) {
        unlocked = unlocked < index + 1 ? index + 1 : unlocked;
      }
    }
    return unlocked.clamp(0, CourseCatalog.stages.length - 1);
  }
}

class AppSettings extends ChangeNotifier {
  AppSettings({this.persistenceEnabled = true});

  static const String _languageKey = 'interface_language';

  final bool persistenceEnabled;
  InterfaceLanguage _language = InterfaceLanguage.th;
  bool _loaded = false;

  InterfaceLanguage get language => _language;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (!persistenceEnabled) {
      _loaded = true;
      notifyListeners();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_languageKey);
    _language = savedLanguage == InterfaceLanguage.ko.name
        ? InterfaceLanguage.ko
        : InterfaceLanguage.th;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(InterfaceLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;
    notifyListeners();

    if (!persistenceEnabled) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, language.name);
  }
}

class AppTextScope extends InheritedWidget {
  const AppTextScope({
    required this.settings,
    required super.child,
    super.key,
  });

  final AppSettings settings;

  static AppSettings settingsOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTextScope>()!.settings;
  }

  static AppText textOf(BuildContext context) {
    return AppText(settingsOf(context).language);
  }

  @override
  bool updateShouldNotify(AppTextScope oldWidget) {
    return true;
  }
}

extension AppTextExtension on BuildContext {
  AppText get t => AppTextScope.textOf(this);
  AppSettings get appSettings => AppTextScope.settingsOf(this);
}

class AppText {
  const AppText(this.interfaceLanguageValue);

  final InterfaceLanguage interfaceLanguageValue;

  bool get isThai => interfaceLanguageValue == InterfaceLanguage.th;

  String get appTitle => 'KorThai Words';
  String get study => isThai ? 'เรียน' : '학습';
  String get quizTab => isThai ? 'แบบทดสอบ' : '퀴즈';
  String get settings => isThai ? 'ตั้งค่า' : '설정';
  String get difficulty => isThai ? 'ระดับ' : '난이도';
  String get studyIntro =>
      isThai ? 'ฝึกคำศัพท์เกาหลีจากระดับพื้นฐาน' : '초급부터 차근차근 쌓는 한국어 단어 연습';
  String get currentCourse => isThai ? 'คอร์สปัจจุบัน' : '현재 코스';
  String get courseMap => isThai ? 'เส้นทางการเรียน' : '학습 로드맵';
  String get courseSettings => isThai ? 'คอร์สการเรียน' : '학습 코스';
  String get courseSettingsDescription => isThai
      ? 'ล็อกไว้ก่อน ระหว่างเตรียมฟีเจอร์พรีเมียม'
      : '추후 유료 기능 전환 예정으로 잠겨 있습니다';
  String get courseChangeLocked =>
      isThai ? 'การเปลี่ยนคอร์สถูกล็อกไว้' : '학습 코스 변경은 잠겨 있습니다';
  String get courseChangeLockedDescription => isThai
      ? 'ตอนนี้เรียนตามเส้นทางที่เลือกไว้ก่อน'
      : '현재 선택된 코스 기준으로 학습을 이어갑니다';
  String get placementTitle =>
      isThai ? 'เริ่มจากระดับที่เหมาะกับคุณ' : '나에게 맞는 단계부터 시작';
  String get placementIntro =>
      isThai ? 'ตอบไม่กี่ข้อเพื่อเลือกคอร์สเริ่มต้น' : '짧은 테스트로 시작 코스를 정합니다';
  String get placementSkip => isThai ? 'ข้ามและเริ่มระดับต้น' : '건너뛰고 초급부터';
  String get placementQuestion => isThai ? 'เลือกความหมาย' : '뜻을 골라주세요';
  String get placementResult => isThai ? 'คอร์สเริ่มต้น' : '추천 시작 코스';
  String get placementStart => isThai ? 'เริ่มเรียน' : '학습 시작';
  String get lockedStage =>
      isThai ? 'เรียนคอร์สก่อนหน้าให้ถึงเป้าหมาย' : '이전 단계 목표 달성 후 열림';
  String courseProgress(int learningPercent, int correct, int attempts,
          int accuracyPercent) =>
      isThai
          ? 'เรียนแล้ว $learningPercent% · แบบทดสอบ $correct/$attempts ($accuracyPercent%)'
          : '학습률 $learningPercent% · 퀴즈 정답률 $correct/$attempts ($accuracyPercent%)';
  String advanceRequirement(int remainingAttempts, int requiredPercent) {
    if (remainingAttempts > 0) {
      return isThai
          ? 'เลื่อนระดับ: ทำแบบทดสอบอีก $remainingAttempts ข้อ และรักษาความถูกต้อง $requiredPercent%+'
          : '다음 단계까지: 퀴즈 $remainingAttempts문제 더 풀고 정답률 $requiredPercent% 이상 유지';
    }
    return isThai
        ? 'เลื่อนระดับ: ต้องรักษาความถูกต้อง $requiredPercent%+'
        : '다음 단계까지: 정답률 $requiredPercent% 이상 필요';
  }

  String get advanceReady => isThai ? 'พร้อมไปคอร์สถัดไป' : '다음 단계로 갈 준비 완료';
  String get beginner => isThai ? 'ระดับต้น' : '초급';
  String get intermediate => isThai ? 'ระดับกลาง' : '중급';
  String get advanced => isThai ? 'ระดับสูง' : '고급';
  String get beginnerSubtitle => isThai ? 'เริ่มจากคำพื้นฐาน' : '기초 단어부터 시작';
  String get beginnerDescription => isThai
      ? 'คำแรกที่ควรรู้ เช่น ทักทาย โรงเรียน ชีวิตประจำวัน และการเดินทาง'
      : '인사, 학교, 생활, 이동처럼 가장 먼저 익힐 단어';
  String get intermediateDescription => isThai
      ? 'ขยายคำศัพท์สำหรับชีวิตประจำวันและการอ่าน'
      : '일상 표현과 읽기 어휘를 넓히는 중급 단어';
  String get advancedDescription =>
      isThai ? 'คำศัพท์ระดับสูงสำหรับการอ่านและการสอบ' : '읽기와 시험 대비에 필요한 고급 단어';
  String get favorites => isThai ? 'รายการโปรด' : '즐겨찾기';
  String get favoritesSubtitle =>
      isThai ? 'คำที่อยากทบทวนอีกครั้ง' : '다시 보고 싶은 단어';
  String get todayReview => isThai ? 'ทบทวนวันนี้' : '오늘의 복습';
  String get todayReviewDescription =>
      isThai ? 'คำที่ควรฝึกก่อนในวันนี้' : '오늘 먼저 볼 단어';
  String todayReviewSubtitle(int count) => isThai
      ? 'คำผิดและคำที่ยังไม่มั่นใจ · $count คำ'
      : '오답과 애매한 단어 우선 · $count개';
  String get todayReviewEmpty =>
      isThai ? 'ยังไม่มีคำให้ทบทวนวันนี้' : '오늘 복습할 단어가 없습니다';
  String get wrongNote => isThai ? 'สมุดคำผิด' : '오답노트';
  String get wrongNoteSubtitle =>
      isThai ? 'คำที่ตอบผิดในแบบทดสอบ' : '퀴즈에서 틀린 단어';
  String get levelQuiz => isThai ? 'แบบทดสอบตามระดับ' : '난이도별 퀴즈';
  String get levelQuizSubtitle =>
      isThai ? 'เลือกคำถามแบบปรนัย 10 ข้อ' : '각 난이도에서 10문제 객관식으로 풀기';
  String get cardPractice => isThai ? 'ฝึกการ์ด' : '카드 연습';
  String get quiz => isThai ? 'แบบทดสอบ' : '퀴즈';
  String get quizKoTitle => isThai ? 'เลือกความหมายภาษาไทย' : '한국어 뜻 고르기';
  String get quizIntro =>
      isThai ? 'เลือกระดับและรูปแบบการฝึก' : '난이도와 문제 유형을 골라 연습';
  String get koreanToThaiQuiz =>
      isThai ? 'เกาหลี → ความหมายไทย' : '한국어 → 태국어 뜻';
  String get thaiToKoreanQuiz =>
      isThai ? 'ความหมายไทย → เกาหลี' : '태국어 뜻 → 한국어';
  String get listeningQuiz => isThai ? 'ฟังเสียง → ความหมายไทย' : '듣고 뜻 고르기';
  String get listeningPrompt =>
      isThai ? 'ฟังเสียงแล้วเลือกความหมาย' : '소리를 듣고 뜻 고르기';
  String get thaiToKoreanPrompt => isThai ? 'เลือกคำภาษาเกาหลี' : '한국어 단어 고르기';
  String get startQuiz => isThai ? 'เริ่ม' : '시작';
  String get correct => isThai ? 'ถูกต้อง' : '정답입니다';
  String answerPrefix(String answer) =>
      isThai ? 'คำตอบ: $answer' : '정답: $answer';
  String get nextQuestion => isThai ? 'ข้อถัดไป' : '다음 문제';
  String get showResult => isThai ? 'ดูผลลัพธ์' : '결과 보기';
  String get quizComplete => isThai ? 'ทำแบบทดสอบเสร็จแล้ว' : '퀴즈 완료';
  String get noWrongWords => isThai ? 'ไม่มีคำที่ตอบผิด' : '틀린 단어가 없습니다';
  String wrongSaved(int count) =>
      isThai ? 'บันทึกคำผิด $count คำแล้ว' : '오답노트에 $count개가 저장되었습니다';
  String get retry => isThai ? 'ทำอีกครั้ง' : '다시 풀기';
  String get wordList => isThai ? 'รายการคำศัพท์' : '단어 목록으로';
  String get searchHint =>
      isThai ? 'ค้นหาภาษาเกาหลี ไทย หรือความหมาย' : '한국어, 태국어, 뜻 검색';
  String get clearSearch => isThai ? 'ล้างคำค้นหา' : '검색어 지우기';
  String get noSearchResults => isThai ? 'ไม่พบผลการค้นหา' : '검색 결과가 없습니다';
  String get studyStatus => isThai ? 'สถานะการเรียน' : '학습 상태';
  String get totalWords => isThai ? 'คำทั้งหมด' : '전체 단어';
  String get seenWords => isThai ? 'เรียนแล้ว' : '학습한 단어';
  String get correctWords => isThai ? 'ตอบถูก' : '정답 단어';
  String get resetProgress => isThai ? 'รีเซ็ตประวัติการเรียน' : '학습 기록 초기화';
  String get resetDescription =>
      isThai ? 'ลบรายการโปรด สมุดคำผิด และความคืบหน้า' : '즐겨찾기, 오답노트, 진행률 삭제';
  String get resetDialogDescription => isThai
      ? 'ลบรายการโปรด สมุดคำผิด และความคืบหน้าทั้งหมด'
      : '즐겨찾기, 오답노트, 진행률을 모두 지웁니다.';
  String get cancel => isThai ? 'ยกเลิก' : '취소';
  String get reset => isThai ? 'รีเซ็ต' : '초기화';
  String get resetDone =>
      isThai ? 'รีเซ็ตประวัติการเรียนแล้ว' : '학습 기록을 초기화했습니다';
  String get dataAttribution => isThai ? 'ที่มาและลิขสิทธิ์' : '출처 및 라이선스';
  String get krdict => isThai
      ? 'พจนานุกรมพื้นฐานภาษาเกาหลี สถาบันภาษาเกาหลีแห่งชาติ'
      : '국립국어원 한국어기초사전';
  String get interfaceLanguage => isThai ? 'ภาษาอินเทอร์เฟซ' : '인터페이스 언어';
  String get languageDescription => isThai ? 'เกาหลี / ไทย' : '한국어 / 태국어';
  String get korean => isThai ? 'เกาหลี' : '한국어';
  String get thai => isThai ? 'ไทย' : '태국어';
  String get source => isThai ? 'ที่มา' : '출처';
  String get data => isThai ? 'ข้อมูล' : '데이터';
  String get language => isThai ? 'ภาษา' : '언어';
  String get license => isThai ? 'ลิขสิทธิ์' : '라이선스';
  String get officialLinks => isThai ? 'ลิงก์ทางการ' : '공식 링크';
  String get previous => isThai ? 'ก่อนหน้า' : '이전';
  String get next => isThai ? 'ถัดไป' : '다음';
  String get speakKorean => isThai ? 'ฟังเสียงเกาหลี' : '한국어 발음 듣기';
  String get showMeaning => isThai ? 'ดูความหมาย' : '뜻 보기';
  String get hideMeaning => isThai ? 'ซ่อน' : '가리기';
  String get memoryQuestion => isThai ? 'จำคำนี้ได้แค่ไหน?' : '이 단어, 얼마나 기억나요?';
  String get memoryHard => isThai ? 'ยังไม่รู้' : '몰라요';
  String get memoryUnsure => isThai ? 'ยังไม่แน่ใจ' : '애매해요';
  String get memoryKnown => isThai ? 'จำได้' : '알아요';
  String get removeWrong => isThai ? 'ลบจากคำผิด' : '오답 제거';
  String get readySoon => isThai ? 'กำลังเตรียม' : '준비 중';
  String get preparingData => isThai ? 'กำลังเตรียมชุดคำศัพท์' : '데이터팩 준비 중';

  String wordsLabel(int count) => isThai ? '$count คำ' : '$count개';
  String collected(int count) =>
      isThai ? 'กำลังตรวจ · รวบรวม $count คำ' : '검수 중 · $count개 수집';
  String learnable(int count) =>
      isThai ? 'พร้อมเรียน · $count คำ' : '학습 가능 · $count개';
  String progress(int seen, int count, int correct) {
    return isThai
        ? 'เรียน $seen/$count · ถูก $correct'
        : '학습 $seen/$count · 정답 $correct';
  }

  String progressRate(int percent) =>
      isThai ? 'เรียนแล้ว $percent%' : '학습률 $percent%';

  String dataLoadFailed(Object error) =>
      isThai ? 'โหลดข้อมูลไม่สำเร็จ\n$error' : '데이터를 불러오지 못했습니다.\n$error';

  String quizTitle(String deckTitle) {
    return isThai ? 'แบบทดสอบ $deckTitle' : '$deckTitle 퀴즈';
  }
}

class KoreanSpeech {
  KoreanSpeech._();

  static final FlutterTts _tts = FlutterTts();
  static bool _configured = false;

  static Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (!_configured) {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.38);
      await _tts.setPitch(1.0);
      _configured = true;
    }

    await _tts.stop();
    await _tts.speak(trimmed);
  }

  static Future<void> stop() => _tts.stop();
}

class ThaiKoreanWordApp extends StatefulWidget {
  const ThaiKoreanWordApp({super.key, this.initialData});

  final VocabularyData? initialData;

  @override
  State<ThaiKoreanWordApp> createState() => _ThaiKoreanWordAppState();
}

class _ThaiKoreanWordAppState extends State<ThaiKoreanWordApp> {
  late final AppSettings _settings = AppSettings();
  late final Future<void> _settingsLoad = _settings.load();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KorThai Words',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF236860),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7F8),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Color(0xFFF5F7F8),
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFDDE4E1)),
            ),
          ),
        ),
        home: HomeScreen(
          initialData: widget.initialData,
          settingsLoad: _settingsLoad,
        ),
      ),
      builder: (context, child) {
        return AppTextScope(
          settings: _settings,
          child: child!,
        );
      },
    );
  }
}

class StudyState extends ChangeNotifier {
  StudyState({this.persistenceEnabled = true});

  static const String _favoriteKey = 'favorite_word_ids';
  static const String _wrongKey = 'wrong_word_ids';
  static const String _seenKey = 'seen_word_ids';
  static const String _correctKey = 'correct_word_ids';
  static const String _memoryRatingKey = 'memory_ratings';
  static const String _courseStageKey = 'course_stage_id';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _quizAttemptsByStageKey = 'quiz_attempts_by_stage';
  static const String _quizCorrectByStageKey = 'quiz_correct_by_stage';

  final bool persistenceEnabled;
  final Set<String> _favoriteIds = <String>{};
  final Set<String> _wrongIds = <String>{};
  final Set<String> _seenIds = <String>{};
  final Set<String> _correctIds = <String>{};
  final Map<String, MemoryRating> _memoryRatings = <String, MemoryRating>{};
  final Map<String, int> _quizAttemptsByStage = <String, int>{};
  final Map<String, int> _quizCorrectByStage = <String, int>{};
  CourseStage _courseStage = CourseCatalog.defaultStage;
  bool _onboardingComplete = false;
  bool _loaded = false;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  Set<String> get wrongIds => Set.unmodifiable(_wrongIds);
  Set<String> get seenIds => Set.unmodifiable(_seenIds);
  Set<String> get correctIds => Set.unmodifiable(_correctIds);
  Map<String, MemoryRating> get memoryRatings =>
      Map.unmodifiable(_memoryRatings);
  CourseStage get courseStage => _courseStage;
  bool get onboardingComplete => _onboardingComplete;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (!persistenceEnabled) {
      _loaded = true;
      notifyListeners();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    _favoriteIds
      ..clear()
      ..addAll(preferences.getStringList(_favoriteKey) ?? const []);
    _wrongIds
      ..clear()
      ..addAll(preferences.getStringList(_wrongKey) ?? const []);
    _seenIds
      ..clear()
      ..addAll(preferences.getStringList(_seenKey) ?? const []);
    _correctIds
      ..clear()
      ..addAll(preferences.getStringList(_correctKey) ?? const []);
    _memoryRatings
      ..clear()
      ..addAll(_parseMemoryRatings(
          preferences.getStringList(_memoryRatingKey) ?? const []));
    _quizAttemptsByStage
      ..clear()
      ..addAll(_parseCountMap(
          preferences.getStringList(_quizAttemptsByStageKey) ?? const []));
    _quizCorrectByStage
      ..clear()
      ..addAll(_parseCountMap(
          preferences.getStringList(_quizCorrectByStageKey) ?? const []));
    _courseStage = CourseCatalog.byId(preferences.getString(_courseStageKey));
    _onboardingComplete = preferences.getBool(_onboardingCompleteKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  bool isFavorite(String wordId) => _favoriteIds.contains(wordId);

  int quizAttemptsForStage(String stageId) =>
      _quizAttemptsByStage[stageId] ?? 0;

  int quizCorrectForStage(String stageId) => _quizCorrectByStage[stageId] ?? 0;

  Future<void> toggleFavorite(String wordId) async {
    if (_favoriteIds.contains(wordId)) {
      _favoriteIds.remove(wordId);
    } else {
      _favoriteIds.add(wordId);
    }
    notifyListeners();
    await _saveFavorites();
  }

  Future<void> markWrong(String wordId) async {
    final changed = _seenIds.add(wordId) | _wrongIds.add(wordId);
    if (!changed) {
      return;
    }
    notifyListeners();
    await _saveProgress();
  }

  Future<void> markCorrect(String wordId) async {
    final changed = _seenIds.add(wordId) | _correctIds.add(wordId);
    if (!changed) {
      return;
    }
    notifyListeners();
    await _saveProgress();
  }

  Future<void> recordQuizAnswer({
    required String? stageId,
    required String wordId,
    required bool isCorrect,
  }) async {
    _seenIds.add(wordId);
    if (isCorrect) {
      _correctIds.add(wordId);
      if (stageId != null) {
        _quizCorrectByStage[stageId] = (_quizCorrectByStage[stageId] ?? 0) + 1;
      }
    } else {
      _wrongIds.add(wordId);
    }

    if (stageId != null) {
      _quizAttemptsByStage[stageId] = (_quizAttemptsByStage[stageId] ?? 0) + 1;
    }

    notifyListeners();
    await _saveProgress();
  }

  Future<void> markSeen(String wordId) async {
    if (!_seenIds.add(wordId)) {
      return;
    }
    notifyListeners();
    await _saveProgress();
  }

  MemoryRating? memoryRating(String wordId) => _memoryRatings[wordId];

  Future<void> setMemoryRating(String wordId, MemoryRating rating) async {
    _memoryRatings[wordId] = rating;
    _seenIds.add(wordId);

    if (rating == MemoryRating.hard) {
      _wrongIds.add(wordId);
      _correctIds.remove(wordId);
    } else if (rating == MemoryRating.unsure) {
      _wrongIds.remove(wordId);
      _correctIds.remove(wordId);
    } else {
      _wrongIds.remove(wordId);
      _correctIds.add(wordId);
    }

    notifyListeners();
    await _saveProgress();
  }

  Future<void> setCourseStage(
    CourseStage stage, {
    bool completeOnboarding = false,
  }) async {
    _courseStage = stage;
    if (completeOnboarding) {
      _onboardingComplete = true;
    }
    notifyListeners();
    await _saveCourse();
  }

  Future<void> clearWrong(String wordId) async {
    if (_wrongIds.remove(wordId)) {
      notifyListeners();
      await _saveWrong();
    }
  }

  Future<void> resetProgress() async {
    _favoriteIds.clear();
    _wrongIds.clear();
    _seenIds.clear();
    _correctIds.clear();
    _memoryRatings.clear();
    _quizAttemptsByStage.clear();
    _quizCorrectByStage.clear();
    notifyListeners();

    if (!persistenceEnabled) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(_favoriteKey),
      preferences.remove(_wrongKey),
      preferences.remove(_seenKey),
      preferences.remove(_correctKey),
      preferences.remove(_memoryRatingKey),
      preferences.remove(_quizAttemptsByStageKey),
      preferences.remove(_quizCorrectByStageKey),
    ]);
  }

  Future<void> _saveFavorites() async {
    if (!persistenceEnabled) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
        _favoriteKey, _favoriteIds.toList()..sort());
  }

  Future<void> _saveWrong() async {
    if (!persistenceEnabled) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_wrongKey, _wrongIds.toList()..sort());
  }

  Future<void> _saveProgress() async {
    if (!persistenceEnabled) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setStringList(_wrongKey, _wrongIds.toList()..sort()),
      preferences.setStringList(_seenKey, _seenIds.toList()..sort()),
      preferences.setStringList(_correctKey, _correctIds.toList()..sort()),
      preferences.setStringList(_memoryRatingKey, _serializeMemoryRatings()),
      preferences.setStringList(
        _quizAttemptsByStageKey,
        _serializeCountMap(_quizAttemptsByStage),
      ),
      preferences.setStringList(
        _quizCorrectByStageKey,
        _serializeCountMap(_quizCorrectByStage),
      ),
    ]);
  }

  Map<String, int> _parseCountMap(List<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      final separator = value.indexOf(':');
      if (separator <= 0 || separator == value.length - 1) {
        continue;
      }
      final id = value.substring(0, separator);
      final count = int.tryParse(value.substring(separator + 1));
      if (count == null || count < 0) {
        continue;
      }
      counts[id] = count;
    }
    return counts;
  }

  List<String> _serializeCountMap(Map<String, int> counts) {
    return counts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}:${entry.value}')
        .toList()
      ..sort();
  }

  Map<String, MemoryRating> _parseMemoryRatings(List<String> values) {
    final ratings = <String, MemoryRating>{};
    for (final value in values) {
      final separator = value.indexOf(':');
      if (separator <= 0 || separator == value.length - 1) {
        continue;
      }
      final wordId = value.substring(0, separator);
      final ratingName = value.substring(separator + 1);
      for (final rating in MemoryRating.values) {
        if (rating.name == ratingName) {
          ratings[wordId] = rating;
          break;
        }
      }
    }
    return ratings;
  }

  List<String> _serializeMemoryRatings() {
    return _memoryRatings.entries
        .map((entry) => '${entry.key}:${entry.value.name}')
        .toList()
      ..sort();
  }

  Future<void> _saveCourse() async {
    if (!persistenceEnabled) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_courseStageKey, _courseStage.id),
      preferences.setBool(_onboardingCompleteKey, _onboardingComplete),
    ]);
  }
}

class Category {
  const Category({
    required this.id,
    required this.ko,
    required this.th,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      ko: json['ko'] as String,
      th: json['th'] as String,
      description: json['description'] as String,
    );
  }

  final String id;
  final String ko;
  final String th;
  final String description;
}

class WordEntry {
  const WordEntry({
    required this.id,
    required this.korean,
    required this.thai,
    required this.thaiShort,
    required this.pronunciation,
    required this.partOfSpeechKo,
    required this.levelKo,
    required this.definitionKo,
    required this.thaiDefinition,
    required this.categories,
    required this.tags,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      id: json['id'] as String,
      korean: json['korean'] as String,
      thai: json['thai'] as String,
      thaiShort: json['thaiShort'] as String? ?? json['thai'] as String,
      pronunciation: json['pronunciation'] as String? ?? '',
      partOfSpeechKo: json['partOfSpeechKo'] as String? ?? '',
      levelKo: json['levelKo'] as String? ?? '',
      definitionKo: json['definitionKo'] as String? ?? '',
      thaiDefinition: json['thaiDefinition'] as String? ?? '',
      categories: List<String>.from(json['categories'] as List<dynamic>? ?? []),
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? []),
    );
  }

  final String id;
  final String korean;
  final String thai;
  final String thaiShort;
  final String pronunciation;
  final String partOfSpeechKo;
  final String levelKo;
  final String definitionKo;
  final String thaiDefinition;
  final List<String> categories;
  final List<String> tags;
}

class VocabularyData {
  const VocabularyData({
    required this.categories,
    required this.words,
  });

  final List<Category> categories;
  final List<WordEntry> words;
}

class WordDeck {
  const WordDeck({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.words,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final List<WordEntry> words;
  final bool enabled;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.settingsLoad,
    super.key,
    this.initialData,
  });

  final VocabularyData? initialData;
  final Future<void> settingsLoad;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final StudyState _studyState = StudyState();
  late final Future<void> _studyStateLoad = _studyState.load();
  late final Future<VocabularyData> _data = widget.initialData != null
      ? Future.value(widget.initialData)
      : _loadData();

  Future<VocabularyData> get _readyData async {
    final data = await _data;
    await Future.wait([_studyStateLoad, widget.settingsLoad]);
    return data;
  }

  Future<VocabularyData> _loadData() async {
    final categoriesText =
        await rootBundle.loadString('assets/data/categories.json');
    final categoriesJson = jsonDecode(categoriesText) as List<dynamic>;
    final wordsJson = [
      ...await _loadWordAsset('assets/data/words_beginner.json'),
      ...await _loadWordAsset('assets/data/words_intermediate.json'),
      ...await _loadWordAsset('assets/data/words_advanced.json'),
    ];

    return VocabularyData(
      categories: categoriesJson
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList(),
      words: wordsJson
          .map((item) => WordEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<dynamic>> _loadWordAsset(String path) async {
    final text = await rootBundle.loadString(path);
    final data = jsonDecode(text) as List<dynamic>;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VocabularyData>(
      future: _readyData,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(context.t.appTitle)),
            body: Center(
              child: Text(context.t.dataLoadFailed(snapshot.error ?? '')),
            ),
          );
        }

        return AnimatedBuilder(
          animation: _studyState,
          builder: (context, _) {
            if (!_studyState.onboardingComplete) {
              return PlacementScreen(
                data: snapshot.data!,
                studyState: _studyState,
              );
            }

            return HomeShell(
              data: snapshot.data!,
              studyState: _studyState,
            );
          },
        );
      },
    );
  }
}

class PlacementScreen extends StatefulWidget {
  const PlacementScreen({
    required this.data,
    required this.studyState,
    super.key,
  });

  final VocabularyData data;
  final StudyState studyState;

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  late final List<WordEntry> _questions = _buildQuestions();
  int _index = 0;
  int _score = 0;
  String? _selectedAnswer;
  CourseStage? _recommendedStage;

  WordEntry get _word => _questions[_index];
  bool get _answered => _selectedAnswer != null;

  List<WordEntry> _buildQuestions() {
    final selected = <WordEntry>[];
    for (final stage in [
      CourseCatalog.stages[0],
      CourseCatalog.stages[1],
      CourseCatalog.stages[3],
      CourseCatalog.stages[4],
      CourseCatalog.stages[6],
      CourseCatalog.stages[7],
    ]) {
      final words = CourseCatalog.wordsForStage(stage, widget.data.words);
      if (words.isNotEmpty) {
        selected.add(words[(words.length / 2).floor()]);
      }
    }
    if (selected.length >= 2) {
      return selected;
    }
    return widget.data.words.take(6).toList();
  }

  List<String> get _choices {
    final correct = _word.thaiShort;
    final choices = <String>[correct];
    for (final word in widget.data.words) {
      if (word.id == _word.id || word.thaiShort == correct) {
        continue;
      }
      choices.add(word.thaiShort);
      if (choices.length == 4) {
        break;
      }
    }
    return _stableShuffle(choices);
  }

  List<String> _stableShuffle(List<String> values) {
    final seed = _hashText(_word.id);
    final result = [...values]
      ..sort((a, b) => _hashText('$seed:$a').compareTo(_hashText('$seed:$b')));
    return result;
  }

  int _hashText(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  void _choose(String answer) {
    if (_answered) {
      return;
    }
    setState(() {
      _selectedAnswer = answer;
      if (answer == _word.thaiShort) {
        _score += 1;
      }
    });
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index += 1;
        _selectedAnswer = null;
      });
      return;
    }
    setState(() {
      _recommendedStage = _stageForScore();
    });
  }

  CourseStage _stageForScore() {
    final ratio = _questions.isEmpty ? 0.0 : _score / _questions.length;
    if (ratio >= 0.84) {
      return CourseCatalog.stages[6];
    }
    if (ratio >= 0.67) {
      return CourseCatalog.stages[4];
    }
    if (ratio >= 0.50) {
      return CourseCatalog.stages[3];
    }
    if (ratio >= 0.34) {
      return CourseCatalog.stages[1];
    }
    return CourseCatalog.defaultStage;
  }

  Future<void> _start(CourseStage stage) {
    return widget.studyState.setCourseStage(stage, completeOnboarding: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final recommended = _recommendedStage;

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.appTitle)),
        body: Center(
          child: FilledButton(
            onPressed: () => _start(CourseCatalog.defaultStage),
            child: Text(t.placementSkip),
          ),
        ),
      );
    }

    if (recommended != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.placementResult)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 64,
                            color: Color(0xFF236860),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            recommended.title(t),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recommended.description(t),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF59615F)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$_score/${_questions.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _start(recommended),
                  icon: const Icon(Icons.school_outlined),
                  label: Text(t.placementStart),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.placementTitle),
        actions: [
          TextButton(
            onPressed: () => _start(CourseCatalog.defaultStage),
            child: Text(t.placementSkip),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Text(
              t.placementIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF59615F),
                  ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: (_index + 1) / _questions.length),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      t.placementQuestion,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF59615F),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _word.korean,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton.filledTonal(
                      tooltip: t.speakKorean,
                      onPressed: () => KoreanSpeech.speak(_word.korean),
                      icon: const Icon(Icons.volume_up_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final choice in _choices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuizChoiceButton(
                  text: choice,
                  isSelected: _selectedAnswer == choice,
                  isCorrect: choice == _word.thaiShort,
                  showResult: _answered,
                  onPressed: () => _choose(choice),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _answered ? _next : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(_index == _questions.length - 1
                  ? t.showResult
                  : t.nextQuestion),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.data,
    required this.studyState,
    super.key,
  });

  final VocabularyData data;
  final StudyState studyState;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudyTab(data: widget.data, studyState: widget.studyState),
      QuizTab(data: widget.data, studyState: widget.studyState),
      SettingsScreen(
        studyState: widget.studyState,
        wordCount: widget.data.words.length,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${widget.data.words.length} words',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            key: const ValueKey('study_tab'),
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: context.t.study,
          ),
          NavigationDestination(
            key: const ValueKey('quiz_tab'),
            icon: const Icon(Icons.quiz_outlined),
            selectedIcon: const Icon(Icons.quiz),
            label: context.t.quizTab,
          ),
          NavigationDestination(
            key: const ValueKey('settings_tab'),
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.t.settings,
          ),
        ],
      ),
    );
  }
}

class StudyTab extends StatelessWidget {
  const StudyTab({
    required this.data,
    required this.studyState,
    super.key,
  });

  final VocabularyData data;
  final StudyState studyState;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final decks = CourseCatalog.stages
        .map((stage) => _deckForStage(t, stage, data.words))
        .toList();
    final unlockedIndex =
        CourseProgressPolicy.unlockedStageIndex(data.words, studyState);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            t.currentCourse,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            t.studyIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF59615F),
                ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: studyState,
            builder: (context, _) {
              final favoriteWords = data.words
                  .where((word) => studyState.favoriteIds.contains(word.id))
                  .toList();
              final wrongWords = data.words
                  .where((word) => studyState.wrongIds.contains(word.id))
                  .toList();
              final currentWords = CourseCatalog.wordsForStage(
                  studyState.courseStage, data.words);
              final todayWords = _todayReviewWords(currentWords, studyState);
              final currentStats = CourseProgressPolicy.statsFor(
                studyState.courseStage,
                data.words,
                studyState,
              );

              return Column(
                children: [
                  _CurrentCourseCard(
                    stage: studyState.courseStage,
                    stats: currentStats,
                    onTap: currentWords.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WordListScreen(
                                  deck: _deckForStage(
                                      t, studyState.courseStage, data.words),
                                  words: currentWords,
                                  allWords: data.words,
                                  studyState: studyState,
                                ),
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 6),
                  QuickPracticeTile(
                    title: t.todayReview,
                    subtitle: todayWords.isEmpty
                        ? t.todayReviewEmpty
                        : t.todayReviewSubtitle(todayWords.length),
                    count: todayWords.length,
                    icon: Icons.today_outlined,
                    onTap: todayWords.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WordListScreen(
                                  deck: WordDeck(
                                    id: 'today_review',
                                    title: t.todayReview,
                                    subtitle: t
                                        .todayReviewSubtitle(todayWords.length),
                                    description: t.todayReviewDescription,
                                    words: const [],
                                  ),
                                  words: todayWords,
                                  allWords: data.words,
                                  studyState: studyState,
                                ),
                              ),
                            );
                          },
                  ),
                  QuickPracticeTile(
                    title: t.favorites,
                    subtitle: t.favoritesSubtitle,
                    count: favoriteWords.length,
                    icon: Icons.star_outline,
                    onTap: favoriteWords.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WordListScreen(
                                  deck: WordDeck(
                                    id: 'favorites',
                                    title: t.favorites,
                                    subtitle: t.favoritesSubtitle,
                                    description: t.favoritesSubtitle,
                                    words: const [],
                                  ),
                                  words: favoriteWords,
                                  allWords: data.words,
                                  studyState: studyState,
                                ),
                              ),
                            );
                          },
                  ),
                  QuickPracticeTile(
                    title: t.wrongNote,
                    subtitle: t.wrongNoteSubtitle,
                    count: wrongWords.length,
                    icon: Icons.report_gmailerrorred_outlined,
                    onTap: wrongWords.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WordListScreen(
                                  deck: WordDeck(
                                    id: 'wrong_note',
                                    title: t.wrongNote,
                                    subtitle: t.wrongNoteSubtitle,
                                    description: t.wrongNoteSubtitle,
                                    words: const [],
                                  ),
                                  words: wrongWords,
                                  allWords: data.words,
                                  studyState: studyState,
                                  showClearWrong: true,
                                ),
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 6),
                ],
              );
            },
          ),
          Text(
            t.courseMap,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          for (final deck in decks)
            AnimatedBuilder(
              animation: studyState,
              builder: (context, _) {
                final stageIndex = decks.indexOf(deck);
                final enabled = stageIndex <= unlockedIndex && deck.enabled;
                final stats = CourseProgressPolicy.statsFor(
                  CourseCatalog.stages[stageIndex],
                  data.words,
                  studyState,
                );

                return WordDeckTile(
                  deck: deck,
                  count: deck.words.length,
                  stats: stats,
                  onTap: !enabled
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WordListScreen(
                                deck: deck,
                                words: deck.words,
                                allWords: data.words,
                                studyState: studyState,
                              ),
                            ),
                          );
                        },
                );
              },
            ),
        ],
      ),
    );
  }

  WordDeck _deckForStage(
    AppText t,
    CourseStage stage,
    List<WordEntry> allWords,
  ) {
    final words = CourseCatalog.wordsForStage(stage, allWords);
    return WordDeck(
      id: stage.id,
      title: stage.title(t),
      subtitle: _deckSubtitle(t, words),
      description: stage.description(t),
      words: words,
      enabled: words.isNotEmpty,
    );
  }

  String _deckSubtitle(AppText t, List<WordEntry> words) {
    if (words.isEmpty) {
      return t.preparingData;
    }
    return t.learnable(words.length);
  }

  List<WordEntry> _todayReviewWords(
    List<WordEntry> words,
    StudyState studyState,
  ) {
    const limit = 18;
    final todaySeed = _todaySeed();

    final candidates = words
        .where((word) => word.korean.trim().isNotEmpty)
        .map((word) => _ReviewCandidate(
              word: word,
              priority: _reviewPriority(word, studyState),
              tieBreaker: _stableHash('$todaySeed:${word.id}'),
            ))
        .toList()
      ..sort((a, b) {
        final priorityCompare = a.priority.compareTo(b.priority);
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return a.tieBreaker.compareTo(b.tieBreaker);
      });

    return candidates.take(limit).map((candidate) => candidate.word).toList();
  }

  int _reviewPriority(WordEntry word, StudyState studyState) {
    final rating = studyState.memoryRating(word.id);
    if (studyState.wrongIds.contains(word.id) || rating == MemoryRating.hard) {
      return 0;
    }
    if (rating == MemoryRating.unsure) {
      return 1;
    }
    if (!studyState.seenIds.contains(word.id)) {
      return 2;
    }
    if (!studyState.correctIds.contains(word.id)) {
      return 3;
    }
    if (rating == MemoryRating.known) {
      return 5;
    }
    return 4;
  }

  String _todaySeed() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  int _stableHash(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _CurrentCourseCard extends StatelessWidget {
  const _CurrentCourseCard({
    required this.stage,
    required this.stats,
    required this.onTap,
  });

  final CourseStage stage;
  final CourseStageStats stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final requirement = stats.canAdvance
        ? t.advanceReady
        : t.advanceRequirement(
            stats.remainingAttempts,
            CourseProgressPolicy.requiredQuizAccuracyPercent,
          );
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.flag_outlined),
        title: Text(
          stage.title(t),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${stage.description(t)}\n'
          '${t.courseProgress(
            stats.learningPercent,
            stats.quizCorrect,
            stats.quizAttempts,
            stats.quizAccuracyPercent,
          )}\n'
          '$requirement',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ReviewCandidate {
  const _ReviewCandidate({
    required this.word,
    required this.priority,
    required this.tieBreaker,
  });

  final WordEntry word;
  final int priority;
  final int tieBreaker;
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.studyState,
    required this.wordCount,
    super.key,
  });

  final StudyState studyState;
  final int wordCount;

  Future<void> _confirmReset(BuildContext context) async {
    final t = context.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.resetProgress),
          content: Text(t.resetDialogDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.reset),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await studyState.resetProgress();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.resetDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            t.settings,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          _LanguageSettingsCard(text: t),
          const SizedBox(height: 12),
          _CourseSettingsCard(
            text: t,
            studyState: studyState,
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: studyState,
            builder: (context, _) {
              return InfoSection(
                title: t.studyStatus,
                children: [
                  InfoRow(label: t.totalWords, value: t.wordsLabel(wordCount)),
                  InfoRow(
                      label: t.seenWords,
                      value: t.wordsLabel(studyState.seenIds.length)),
                  InfoRow(
                      label: t.correctWords,
                      value: t.wordsLabel(studyState.correctIds.length)),
                  InfoRow(
                      label: t.favorites,
                      value: t.wordsLabel(studyState.favoriteIds.length)),
                  InfoRow(
                      label: t.wrongNote,
                      value: t.wordsLabel(studyState.wrongIds.length)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(
                t.resetProgress,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(t.resetDescription),
              onTap: () => _confirmReset(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                t.dataAttribution,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(t.krdict),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DataAttributionScreen(wordCount: wordCount),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSettingsCard extends StatelessWidget {
  const _LanguageSettingsCard({required this.text});

  final AppText text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.interfaceLanguage,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text.languageDescription,
                        style: const TextStyle(color: Color(0xFF59615F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('language_ko_option'),
                  label: Text(text.korean),
                  selected:
                      context.appSettings.language == InterfaceLanguage.ko,
                  onSelected: (_) {
                    context.appSettings.setLanguage(InterfaceLanguage.ko);
                  },
                ),
                ChoiceChip(
                  key: const ValueKey('language_th_option'),
                  label: Text(text.thai),
                  selected:
                      context.appSettings.language == InterfaceLanguage.th,
                  onSelected: (_) {
                    context.appSettings.setLanguage(InterfaceLanguage.th);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseSettingsCard extends StatelessWidget {
  const _CourseSettingsCard({
    required this.text,
    required this.studyState,
  });

  final AppText text;
  final StudyState studyState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.courseSettings,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text.courseSettingsDescription,
                        style: const TextStyle(color: Color(0xFF59615F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: studyState,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text.courseChangeLocked,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  text.courseChangeLockedDescription,
                                  style: const TextStyle(
                                    color: Color(0xFF59615F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final stage in CourseCatalog.stages)
                          ChoiceChip(
                            key: ValueKey('course_${stage.id}'),
                            label: Text(stage.title(text)),
                            selected: studyState.courseStage.id == stage.id,
                            onSelected: null,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class QuizTab extends StatelessWidget {
  const QuizTab({
    required this.data,
    required this.studyState,
    super.key,
  });

  final VocabularyData data;
  final StudyState studyState;

  static const int _questionCount = 10;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return SafeArea(
      child: AnimatedBuilder(
        animation: studyState,
        builder: (context, _) {
          final unlockedIndex = CourseProgressPolicy.unlockedStageIndex(
            data.words,
            studyState,
          );
          final decks = [
            for (var index = 0; index < CourseCatalog.stages.length; index += 1)
              _deckForStage(
                t,
                CourseCatalog.stages[index],
                enabled: index <= unlockedIndex,
              ),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                t.quizTab,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                t.quizIntro,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF59615F),
                    ),
              ),
              const SizedBox(height: 16),
              for (final deck in decks) ...[
                Text(
                  deck.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                QuizStartTile(
                  deck: deck,
                  mode: QuizMode.koreanToThai,
                  allWords: data.words,
                  studyState: studyState,
                  questionCount: _questionCount,
                ),
                QuizStartTile(
                  deck: deck,
                  mode: QuizMode.thaiToKorean,
                  allWords: data.words,
                  studyState: studyState,
                  questionCount: _questionCount,
                ),
                QuizStartTile(
                  deck: deck,
                  mode: QuizMode.listeningToThai,
                  allWords: data.words,
                  studyState: studyState,
                  questionCount: _questionCount,
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  WordDeck _deckForStage(
    AppText t,
    CourseStage stage, {
    required bool enabled,
  }) {
    final words = CourseCatalog.wordsForStage(stage, data.words);
    return WordDeck(
      id: stage.id,
      title: stage.title(t),
      subtitle: _deckSubtitle(t, words, enabled),
      description: stage.description(t),
      words: words,
      enabled: enabled && words.isNotEmpty,
    );
  }

  String _deckSubtitle(AppText t, List<WordEntry> words, bool enabled) {
    if (!enabled) {
      return t.lockedStage;
    }
    if (words.isEmpty) {
      return t.preparingData;
    }
    return t.learnable(words.length);
  }
}

class QuizStartTile extends StatelessWidget {
  const QuizStartTile({
    required this.deck,
    required this.mode,
    required this.allWords,
    required this.studyState,
    required this.questionCount,
    super.key,
  });

  final WordDeck deck;
  final QuizMode mode;
  final List<WordEntry> allWords;
  final StudyState studyState;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canStart = deck.enabled && deck.words.length >= 4;
    final title = mode.title(t);
    final quizWords = _quizWords();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: canStart,
        leading: Icon(mode.icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          canStart
              ? (t.isThai
                  ? '${quizWords.length} ข้อ · ${deck.title}'
                  : '${quizWords.length}문제 · ${deck.title}')
              : deck.subtitle,
        ),
        trailing: Icon(canStart ? Icons.play_arrow : Icons.lock_outline),
        onTap: !canStart
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => QuizScreen(
                      words: quizWords,
                      allWords: allWords,
                      deckName: '${deck.title} · $title',
                      studyState: studyState,
                      mode: mode,
                      stageId: deck.id,
                    ),
                  ),
                );
              },
      ),
    );
  }

  List<WordEntry> _quizWords() {
    final result = [...deck.words]..shuffle();
    return result.take(questionCount).toList();
  }
}

class DataAttributionScreen extends StatelessWidget {
  const DataAttributionScreen({required this.wordCount, super.key});

  final int wordCount;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.dataAttribution)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            InfoSection(
              title: t.data,
              children: [
                InfoRow(label: t.source, value: t.krdict),
                InfoRow(label: t.data, value: t.wordsLabel(wordCount)),
                InfoRow(label: t.language, value: '${t.korean} · ${t.thai}'),
              ],
            ),
            const SizedBox(height: 12),
            InfoSection(
              title: t.license,
              children: [
                InfoRow(
                    label: t.isThai ? 'ข้อความ' : '텍스트',
                    value: t.isThai
                        ? 'ต้องตรวจสอบเงื่อนไข CC BY-SA'
                        : 'CC BY-SA 조건 확인 필요'),
                InfoRow(
                    label: t.isThai ? 'การแสดงในแอป' : '앱 표시',
                    value: t.isThai
                        ? 'คงที่มาและประกาศลิขสิทธิ์ของต้นฉบับ'
                        : '원문 출처와 라이선스 고지 유지'),
                InfoRow(
                    label: t.isThai ? 'ข้อควรระวัง' : '주의',
                    value: t.isThai
                        ? 'เสียง รูปภาพ และมัลติมีเดียต้องตรวจสอบเงื่อนไขแยกต่างหาก'
                        : '오디오, 이미지 등 멀티미디어는 별도 조건 확인'),
              ],
            ),
            const SizedBox(height: 12),
            InfoSection(
              title: t.officialLinks,
              children: const [
                InfoRow(label: 'Krdict', value: 'https://krdict.korean.go.kr'),
                InfoRow(
                    label: 'Open API',
                    value:
                        'https://krdict.korean.go.kr/eng/openApi/openApiInfo'),
                InfoRow(
                    label: '저작권',
                    value:
                        'https://krdict.korean.go.kr/eng/kboardPolicy/copyRightTermsInfo'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  const InfoSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF59615F),
                ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class QuickPracticeTile extends StatelessWidget {
  const QuickPracticeTile({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        enabled: onTap != null,
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Text('$count'),
      ),
    );
  }
}

class WordDeckTile extends StatelessWidget {
  const WordDeckTile({
    required this.deck,
    required this.count,
    required this.stats,
    required this.onTap,
    super.key,
  });

  final WordDeck deck;
  final int count;
  final CourseStageStats stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        enabled: onTap != null,
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(
          deck.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${_deckProgressText(t)}\n'
            '${stats.canAdvance ? t.advanceReady : t.advanceRequirement(
                stats.remainingAttempts,
                CourseProgressPolicy.requiredQuizAccuracyPercent,
              )}\n'
            '${deck.subtitle}',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count == 0 ? t.readySoon : t.progressRate(stats.learningPercent),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Icon(onTap == null ? Icons.lock_outline : Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _deckProgressText(AppText t) {
    if (count == 0) {
      return deck.description;
    }
    return t.courseProgress(
      stats.learningPercent,
      stats.quizCorrect,
      stats.quizAttempts,
      stats.quizAccuracyPercent,
    );
  }
}

class WordListScreen extends StatelessWidget {
  const WordListScreen({
    required this.deck,
    required this.words,
    required this.allWords,
    required this.studyState,
    this.showClearWrong = false,
    super.key,
  });

  final WordDeck deck;
  final List<WordEntry> words;
  final List<WordEntry> allWords;
  final StudyState studyState;
  final bool showClearWrong;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(deck.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              deck.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF59615F),
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WordCardScreen(
                            words: words,
                            initialIndex: 0,
                            studyState: studyState,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.style_outlined),
                    label: Text(t.cardPractice),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: words.length < 2
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => QuizScreen(
                                  words: words,
                                  allWords: allWords,
                                  deckName: deck.title,
                                  studyState: studyState,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.quiz_outlined),
                    label: Text(t.quiz),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: studyState,
              builder: (context, _) {
                final visibleWords = showClearWrong
                    ? words
                        .where((word) => studyState.wrongIds.contains(word.id))
                        .toList()
                    : words;
                return Column(
                  children: [
                    for (var index = 0; index < visibleWords.length; index += 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => WordCardScreen(
                                    words: visibleWords,
                                    initialIndex: index,
                                    studyState: studyState,
                                  ),
                                ),
                              );
                            },
                            title: Text(
                              visibleWords[index].korean,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(visibleWords[index].thaiShort),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: t.speakKorean,
                                  onPressed: () => KoreanSpeech.speak(
                                      visibleWords[index].korean),
                                  icon: const Icon(Icons.volume_up_outlined),
                                ),
                                IconButton(
                                  tooltip: t.favorites,
                                  onPressed: () => studyState
                                      .toggleFavorite(visibleWords[index].id),
                                  icon: Icon(
                                    studyState
                                            .isFavorite(visibleWords[index].id)
                                        ? Icons.star
                                        : Icons.star_border,
                                  ),
                                ),
                                if (showClearWrong)
                                  IconButton(
                                    tooltip: t.removeWrong,
                                    onPressed: () => studyState
                                        .clearWrong(visibleWords[index].id),
                                    icon:
                                        const Icon(Icons.check_circle_outline),
                                  )
                                else
                                  const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum QuizMode {
  koreanToThai,
  thaiToKorean,
  listeningToThai;

  String title(AppText t) {
    return switch (this) {
      QuizMode.koreanToThai => t.koreanToThaiQuiz,
      QuizMode.thaiToKorean => t.thaiToKoreanQuiz,
      QuizMode.listeningToThai => t.listeningQuiz,
    };
  }

  IconData get icon {
    return switch (this) {
      QuizMode.koreanToThai => Icons.translate,
      QuizMode.thaiToKorean => Icons.spellcheck,
      QuizMode.listeningToThai => Icons.hearing,
    };
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    required this.words,
    required this.allWords,
    required this.deckName,
    required this.studyState,
    this.mode = QuizMode.koreanToThai,
    this.stageId,
    super.key,
  });

  final List<WordEntry> words;
  final List<WordEntry> allWords;
  final String deckName;
  final StudyState studyState;
  final QuizMode mode;
  final String? stageId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _score = 0;
  String? _selectedThai;
  late final List<WordEntry> _quizWords = [...widget.words]..shuffle();

  WordEntry get _word => _quizWords[_index];
  bool get _answered => _selectedThai != null;

  List<String> get _choices {
    final correctAnswer = _answerFor(_word);
    final candidates = <String, int>{};

    for (final word in [...widget.words, ...widget.allWords]) {
      final answer = _answerFor(word).trim();
      if (word.id == _word.id || answer.isEmpty || answer == correctAnswer) {
        continue;
      }
      candidates.putIfAbsent(answer, () => _choiceScore(_word.id, word));
    }

    final distractors = candidates.entries.toList()
      ..sort((a, b) {
        final scoreCompare = a.value.compareTo(b.value);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return a.key.compareTo(b.key);
      });

    return _stableShuffle([
      correctAnswer,
      ...distractors.take(3).map((entry) => entry.key),
    ]);
  }

  List<String> _stableShuffle(List<String> values) {
    final result = [...values];
    final seed = _hashText(_word.id);
    result.sort((a, b) {
      final aScore = _hashText('$seed:$a');
      final bScore = _hashText('$seed:$b');
      return aScore.compareTo(bScore);
    });
    return result;
  }

  int _choiceScore(String questionId, WordEntry candidate) {
    final sameLevelBonus = candidate.levelKo == _word.levelKo ? 0 : 1000000;
    final sameDeckBonus =
        widget.words.any((word) => word.id == candidate.id) ? 0 : 500000;
    return sameLevelBonus +
        sameDeckBonus +
        _hashText('$questionId:${candidate.id}:${candidate.thaiShort}');
  }

  String _answerFor(WordEntry word) {
    return switch (widget.mode) {
      QuizMode.koreanToThai || QuizMode.listeningToThai => word.thaiShort,
      QuizMode.thaiToKorean => word.korean,
    };
  }

  String _promptFor(WordEntry word) {
    return switch (widget.mode) {
      QuizMode.koreanToThai => word.korean,
      QuizMode.thaiToKorean => word.thaiShort,
      QuizMode.listeningToThai => word.pronunciation,
    };
  }

  String _promptTitle(AppText t) {
    return switch (widget.mode) {
      QuizMode.koreanToThai => t.quizKoTitle,
      QuizMode.thaiToKorean => t.thaiToKoreanPrompt,
      QuizMode.listeningToThai => t.listeningPrompt,
    };
  }

  int _hashText(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  void _choose(String thai) {
    if (_answered) {
      return;
    }

    final isCorrect = thai == _answerFor(_word);
    setState(() {
      _selectedThai = thai;
      if (isCorrect) {
        _score += 1;
      }
    });
    widget.studyState.recordQuizAnswer(
      stageId: widget.stageId,
      wordId: _word.id,
      isCorrect: isCorrect,
    );
  }

  void _next() {
    if (_index == _quizWords.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => QuizResultScreen(
            deckName: widget.deckName,
            score: _score,
            total: _quizWords.length,
            words: widget.words,
            allWords: widget.allWords,
            studyState: widget.studyState,
            mode: widget.mode,
            stageId: widget.stageId,
            wrongWords: _quizWords
                .where((word) => widget.studyState.wrongIds.contains(word.id))
                .toList(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _index += 1;
      _selectedThai = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final choices = _choices;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_score/${_quizWords.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            LinearProgressIndicator(value: (_index + 1) / _quizWords.length),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _promptTitle(t),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF59615F),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _promptFor(_word),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.mode != QuizMode.listeningToThai)
                      Text(
                        _word.pronunciation,
                        style: const TextStyle(
                          color: Color(0xFF59615F),
                          fontSize: 18,
                        ),
                      ),
                    const SizedBox(height: 12),
                    IconButton.filledTonal(
                      tooltip: t.speakKorean,
                      onPressed: () => KoreanSpeech.speak(_word.korean),
                      icon: const Icon(Icons.volume_up_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final choice in choices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuizChoiceButton(
                  text: choice,
                  isSelected: _selectedThai == choice,
                  isCorrect: choice == _answerFor(_word),
                  showResult: _answered,
                  onPressed: () => _choose(choice),
                ),
              ),
            const SizedBox(height: 12),
            if (_answered)
              Text(
                _selectedThai == _answerFor(_word)
                    ? t.correct
                    : t.answerPrefix(_answerFor(_word)),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _selectedThai == _answerFor(_word)
                      ? const Color(0xFF236860)
                      : const Color(0xFF9B2C2C),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _answered ? _next : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                _index == _quizWords.length - 1 ? t.showResult : t.nextQuestion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    required this.deckName,
    required this.score,
    required this.total,
    required this.words,
    required this.allWords,
    required this.studyState,
    required this.mode,
    required this.stageId,
    required this.wrongWords,
    super.key,
  });

  final String deckName;
  final int score;
  final int total;
  final List<WordEntry> words;
  final List<WordEntry> allWords;
  final StudyState studyState;
  final QuizMode mode;
  final String? stageId;
  final List<WordEntry> wrongWords;

  void _retry(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          words: words,
          allWords: allWords,
          deckName: deckName,
          studyState: studyState,
          mode: mode,
          stageId: stageId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final percent = total == 0 ? 0 : (score / total * 100).round();

    return Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: Color(0xFF236860),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.quizComplete,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$score/$total · $percent%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          wrongWords.isEmpty
                              ? t.noWrongWords
                              : t.wrongSaved(wrongWords.length),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF59615F)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _retry(context),
                icon: const Icon(Icons.refresh),
                label: Text(t.retry),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.list_alt),
                label: Text(t.wordList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizChoiceButton extends StatelessWidget {
  const QuizChoiceButton({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onPressed,
    super.key,
  });

  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color? backgroundColor;
    final Color? foregroundColor;
    final IconData? icon;

    if (!showResult) {
      backgroundColor = null;
      foregroundColor = null;
      icon = null;
    } else if (isCorrect) {
      backgroundColor = const Color(0xFFE3F3EC);
      foregroundColor = const Color(0xFF145C48);
      icon = Icons.check_circle;
    } else if (isSelected) {
      backgroundColor = const Color(0xFFF9E4E4);
      foregroundColor = const Color(0xFF9B2C2C);
      icon = Icons.cancel;
    } else {
      backgroundColor = colorScheme.surface;
      foregroundColor = const Color(0xFF59615F);
      icon = null;
    }

    return OutlinedButton(
      onPressed: showResult ? null : onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(54),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledForegroundColor: foregroundColor,
        side: BorderSide(
          color: showResult && isCorrect
              ? const Color(0xFF8BC7B1)
              : const Color(0xFFDDE4E1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (icon != null) Icon(icon),
        ],
      ),
    );
  }
}

class WordCardScreen extends StatefulWidget {
  const WordCardScreen({
    required this.words,
    required this.initialIndex,
    required this.studyState,
    super.key,
  });

  final List<WordEntry> words;
  final int initialIndex;
  final StudyState studyState;

  @override
  State<WordCardScreen> createState() => _WordCardScreenState();
}

class _WordCardScreenState extends State<WordCardScreen> {
  late int _index = widget.initialIndex;
  bool _showMeaning = false;

  WordEntry get _word => widget.words[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.studyState.markSeen(_word.id);
      }
    });
  }

  void _next() {
    setState(() {
      _index = (_index + 1) % widget.words.length;
      _showMeaning = false;
    });
    widget.studyState.markSeen(_word.id);
  }

  void _previous() {
    setState(() {
      _index = (_index - 1 + widget.words.length) % widget.words.length;
      _showMeaning = false;
    });
    widget.studyState.markSeen(_word.id);
  }

  @override
  void dispose() {
    KoreanSpeech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1}/${widget.words.length}'),
        actions: [
          AnimatedBuilder(
            animation: widget.studyState,
            builder: (context, _) {
              return IconButton(
                tooltip: t.favorites,
                onPressed: () => widget.studyState.toggleFavorite(_word.id),
                icon: Icon(
                  widget.studyState.isFavorite(_word.id)
                      ? Icons.star
                      : Icons.star_border,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showMeaning = !_showMeaning),
                  child: Card(
                    child: SizedBox.expand(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _word.korean,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _word.pronunciation,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFF59615F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            IconButton.filledTonal(
                              tooltip: t.speakKorean,
                              onPressed: () => KoreanSpeech.speak(_word.korean),
                              icon: const Icon(Icons.volume_up_outlined),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_word.levelKo} · ${_word.partOfSpeechKo}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 28),
                            Visibility(
                              visible: _showMeaning,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: _WordMeaningBlock(word: _word),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: widget.studyState,
                builder: (context, _) {
                  return _MemoryRatingControls(
                    rating: widget.studyState.memoryRating(_word.id),
                    onChanged: (rating) =>
                        widget.studyState.setMemoryRating(_word.id, rating),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(t.previous),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          setState(() => _showMeaning = !_showMeaning),
                      icon: Icon(_showMeaning
                          ? Icons.visibility_off
                          : Icons.visibility),
                      label: Text(_showMeaning ? t.hideMeaning : t.showMeaning),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(t.next),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryRatingControls extends StatelessWidget {
  const _MemoryRatingControls({
    required this.rating,
    required this.onChanged,
  });

  final MemoryRating? rating;
  final ValueChanged<MemoryRating> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.memoryQuestion,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<MemoryRating>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          selected: rating == null ? <MemoryRating>{} : <MemoryRating>{rating!},
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) {
              onChanged(selected.first);
            }
          },
          segments: [
            ButtonSegment<MemoryRating>(
              value: MemoryRating.hard,
              icon: const Icon(Icons.close),
              label: Text(t.memoryHard),
            ),
            ButtonSegment<MemoryRating>(
              value: MemoryRating.unsure,
              icon: const Icon(Icons.help_outline),
              label: Text(t.memoryUnsure),
            ),
            ButtonSegment<MemoryRating>(
              value: MemoryRating.known,
              icon: const Icon(Icons.check),
              label: Text(t.memoryKnown),
            ),
          ],
        ),
      ],
    );
  }
}

class _WordMeaningBlock extends StatelessWidget {
  const _WordMeaningBlock({required this.word});

  final WordEntry word;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          word.thaiShort,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          word.definitionKo,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          word.thaiDefinition,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF59615F)),
        ),
      ],
    );
  }
}
