# FilmIn
FilmIn(필름인) Main ReadMe

# 1) 시뮬레이터 앱 켜기
open -a Simulator

# 2) 사용 가능한 기기 확인
fvm flutter devices

# 3) 표시된 기기 이름(또는 UDID)로 실행  ← 이름에 공백 있으면 따옴표 필수
fvm flutter run -d insert
fvm flutter run -d "iPhone 16 Pro"
