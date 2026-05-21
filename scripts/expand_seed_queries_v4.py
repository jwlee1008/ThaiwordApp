#!/usr/bin/env python3
"""Append a small final wave of curated seed queries to pass 2,000 app words."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


ADDITIONS = {
    "beginner": """
# v4 beginner top-up
가로
세로
무늬
줄
칸
표
동그라미
세모
네모
별표
밑줄
사다리
손잡이
뚜껑
꼭지
단추
주머니
끈
바늘
실
망치
못
삽
빗자루
걸레
약속시간
귀가하다
외출하다
마중
마중하다
배웅
배웅하다
깜짝
활짝
반짝
푹
살짝
""",
    "intermediate": """
# v4 intermediate top-up
가동
가동하다
간격
간담회
간편하다
개별
개별적
개설
개설하다
개편
개편하다
검사결과
결제
결제하다
결핍
공백
공식문서
과부하
교대
교대하다
구독
구독하다
권한
권한부여
근무표
납부
납부하다
대여
대여하다
도난
도난당하다
명단
미납
미납하다
발급
발급하다
방침
배정
배정하다
변경사항
보류
보류하다
복구
복구하다
부과
부과하다
분담
분담하다
사전예약
상담원
상환
상환하다
선착순
수납
수납하다
승차권
신분증
신청자격
안내데스크
연장
연장하다
예약자
오프라인
온라인신청
완료일
우선
우선하다
유의
유의하다
이용시간
입장권
재신청
재신청하다
접수번호
접수증
정산
정산하다
조기
조기마감
증빙
증빙서류
지참
지참하다
차감
차감하다
철회
철회하다
최신
최신식
충돌
충돌하다
취급
취급하다
폐쇄
폐쇄하다
해지
해지하다
""",
    "advanced": """
# v4 advanced top-up
가부장제
감수성
개연성
결정론
경계성
공동선
공리주의
공생
공생하다
관념론
구성원리
국민국가
귀납
귀납적
규범화
규범화하다
기호학
내재화
내재화하다
담론분석
당위성
대립구도
도구적
동원
동원하다
맥락화
맥락화하다
메커니즘
명시화
명시화하다
모더니즘
문화권
미시사
반증
반증하다
법률주의
비가시적
비판담론
사회계약
상대주의적
상호작용론
서구중심주의
선형적
성별분업
세계시민
세계시민주의
소비사회
수렴
수렴하다
시민권
신뢰도
실존
실존주의
양가성
언어공동체
역설
역설적
연역
연역적
예속
예속되다
운동성
원자화
원자화되다
유물론
유물론적
의례
의례적
이원론
인식론
자기성찰
자기성찰적
재맥락화
재맥락화하다
정체
정체되다
정체성정치
조응
조응하다
주체화
주체화하다
중심성
차등
차등화
차등화하다
탈근대
탈근대적
통치성
파생
파생되다
표준편차
합목적성
해체
해체하다
해체주의
현대성
환원
환원하다
환원주의
""",
}


FILES = {
    "beginner": ROOT / "data" / "seed_queries_beginner.txt",
    "intermediate": ROOT / "data" / "seed_queries_intermediate.txt",
    "advanced": ROOT / "data" / "seed_queries_advanced.txt",
}


def append_unique(path: Path, text: str) -> tuple[int, int]:
    existing = path.read_text(encoding="utf-8")
    seen = {
        line.strip()
        for line in existing.splitlines()
        if line.strip() and not line.strip().startswith("#")
    }
    output = [existing.rstrip(), "", "# expanded curated queries v4"]
    added = 0
    for line in text.strip().splitlines():
        value = line.strip()
        if not value:
            output.append("")
            continue
        if value.startswith("#"):
            output.append(value)
            continue
        if value in seen:
            continue
        seen.add(value)
        added += 1
        output.append(value)
    path.write_text("\n".join(output).rstrip() + "\n", encoding="utf-8")
    return added, len(seen)


def main() -> int:
    for level, path in FILES.items():
        added, total = append_unique(path, ADDITIONS[level])
        print(f"{level}: added {added}, total {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
