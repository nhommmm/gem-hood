# Hướng dẫn Custom UI — Gem Hood

Ứng dụng (`package:gem_hood`) được tách lớp rõ ràng để bạn có thể đổi giao diện bất kỳ lúc nào mà không ảnh hưởng đến logic gọi API hay quản lý state.

- **Tên hiển thị**: `Gem Hood` ([lib/l10n/strings.dart](lib/l10n/strings.dart), [web/index.html](web/index.html), [web/manifest.json](web/manifest.json), [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml), [Info.plist](ios/Runner/Info.plist))
- **Package / Application ID**: `gem_hood` ([pubspec.yaml](pubspec.yaml)), `com.gemhood.app` ([build.gradle.kts](android/app/build.gradle.kts))
- **Cấu hình giải đấu**: Không hard-code trong source; nhập qua màn hình **Setup** ([lib/screens/setup_screen.dart](lib/screens/setup_screen.dart), lưu trong `SharedPreferences` qua [lib/services/league_config_service.dart](lib/services/league_config_service.dart)) hoặc truyền trực tiếp qua URL `?league=<LEAGUE_ID>&user=<USERNAME>`.

---

## 1. Đổi màu sắc, font chữ, khoảng cách, văn bản, cấu hình

| Muốn chỉnh gì | Sửa file nào | Ghi chú |
|---|---|---|
| **Màu sắc** (nền, card, cam, xanh ngọc, màu chấn thương, thắng/thua) | [lib/theme/app_colors.dart](lib/theme/app_colors.dart) | Đổi giá trị `Color(0xFF...)` trong `AppColors`. |
| **Cỡ chữ, độ đậm, màu chữ** | [lib/theme/app_text_styles.dart](lib/theme/app_text_styles.dart) | Chỉnh các `TextStyle` trong `AppTextStyles` (có thể gắn `fontFamily` tại đây). |
| **Padding, margin, bo góc, kích thước avatar** | [lib/theme/app_spacing.dart](lib/theme/app_spacing.dart) | Chỉnh các hằng số trong `AppSpacing`. |
| **Theme Material tổng thể** (AppBar, Card, NavigationRail, BottomNavigationBar) | [lib/theme/app_theme.dart](lib/theme/app_theme.dart) | Dựng `ThemeData` từ 3 file trên. |
| **Toàn bộ chữ hiển thị** (tên tab, nhãn `"Starters"`, `"Bench"`, `"IR"`, lỗi, Setup) | [lib/l10n/strings.dart](lib/l10n/strings.dart) | Đổi hoặc dịch chuỗi trong `AppStrings`. |
| **Chu kỳ refresh, múi giờ lịch đấu, breakpoint 800px** | [lib/config/constants.dart](lib/config/constants.dart) | Sửa `AppConstants`. Đổi `scheduleTimezone` giữa `ScheduleTimezone.vietnam` (UTC+7, mặc định) và `ScheduleTimezone.usEastern` (giờ Mỹ ET). |
| **Bảng quy đổi mã viết tắt 30 đội NBA** | [lib/config/team_codes.dart](lib/config/team_codes.dart) | Quy đổi mã đội giữa nguồn lịch (ESPN/NBA CDN) và Sleeper (`GS→GSW`, `NO→NOP`, `NY→NYK`, `SA→SAS`, `WSH→WAS`, `UTAH→UTA`...). |

---

## 2. Đổi giao diện từng thành phần (Widgets)

Mỗi thành phần UI nằm độc lập trong thư mục `lib/widgets/` và chỉ nhận dữ liệu qua tham số:

- **Thẻ cầu thủ** (slot, ảnh, tên, vị trí/đội NBA, chấn thương, điểm tuần): `lib/widgets/player_tile.dart` (`PlayerTile`)
- **Thẻ cặp đấu** (2 đội và tổng điểm): `lib/widgets/matchup_card.dart` (`MatchupCard`)
- **Chi tiết cặp đấu** (bảng điểm + Starters vs Bench hai đội): `lib/widgets/matchup_detail.dart` (`MatchupDetail`)
- **Hàng bảng xếp hạng** (hạng, avatar, tên đội, W-L, FPTS): `lib/widgets/standings_row.dart` (`StandingsRow`)
- **Thẻ giao dịch Trade** (các đội tham gia, cầu thủ nhận/nhường, draft picks, thời gian): `lib/widgets/trade_card.dart` (`TradeCard`)
- **Thẻ Top 5 Starters cao/thấp điểm** (kèm ghi chú cầu thủ 0 điểm): `lib/widgets/insight_starter_card.dart` (`InsightStarterCard`)
- **Thẻ Bench tiếc nuối** (cầu thủ dự bị cao điểm hơn starter thấp nhất): `lib/widgets/bench_regret_card.dart` (`BenchRegretCard`)
- **Thẻ Lineup hiệu quả nhất tuần** (so sánh thực tế vs tối ưu theo `roster_positions`): `lib/widgets/lineup_efficiency_card.dart` (`LineupEfficiencyCard`)
- **Bảng lịch tuần fantasy ở đầu tab Teams** (7 cột Thứ 3 → Thứ 2, chuyển tuần trước/này/sau): `lib/widgets/week_schedule_card.dart` (`WeekScheduleCard`)
- **Thẻ đội trong danh sách Teams**: `lib/widgets/team_card.dart` (`TeamCard`)
- **Thanh chọn tuần**: `lib/widgets/week_selector.dart` (`WeekSelector`)
- **Nhãn chấn thương**: `lib/widgets/injury_badge.dart` (`InjuryBadge`)
- **Ảnh cầu thủ / Avatar đội**: `lib/widgets/player_avatar.dart`, `lib/widgets/team_avatar.dart`
- **Màn hình Loading / Lỗi + Retry**: `lib/widgets/loading_view.dart`, `lib/widgets/error_retry.dart`

---

## 3. Thêm hoặc chỉnh tab trong `lib/screens/app_shell.dart`

Các tab hiện có: **Matchups** (`0`), **Teams** (`1`), **Standings** (`2`), **Trades** (`3` - `lib/screens/trades_screen.dart`), **Insights** (`4` - `lib/screens/insights_screen.dart`).

- **Màn hình Setup / Đổi league**: `lib/screens/setup_screen.dart` + `lib/services/league_config_service.dart`.
- **Model & cache của Trades**: `lib/models/trade.dart`, `lib/services/trade_cache.dart` (cache các tuần đã qua), `lib/providers/fantasy_provider.dart`.
- **Logic tính toán của Insights**: `lib/providers/insights_provider.dart` (tính từ `FantasyProvider` qua `ProxyProvider` trong `lib/main.dart`, chỉ dùng các model hiện có).
- **Lịch đấu cầu thủ**: `lib/models/nba_game.dart`, `lib/services/schedule_service.dart` (đọc `assets/nba_schedule.json` offline, không gọi mạng trong app).

Để thêm một tab mới (ví dụ: *Waivers* hoặc *Playoffs*):

1. Tạo màn hình mới trong `lib/screens/` (ví dụ `my_new_screen.dart`), đọc dữ liệu từ `FantasyProvider`.
2. Khai báo tên tab trong `lib/l10n/strings.dart`.
3. Mở `lib/screens/app_shell.dart`:
   - Thêm 1 `NavigationRailDestination` trong danh sách `destinations` của `NavigationRail` (giao diện `> 800px`).
   - Thêm 1 `BottomNavigationBarItem` tương ứng trong `items` của `BottomNavigationBar` (giao diện `< 800px`).
   - Thêm nhánh `case 5:` trong `_buildBody({required bool isWide})` để trả về màn hình mới (kèm Master-Detail nếu cần).

---

## 4. Cập nhật lịch thi đấu NBA (`assets/nba_schedule.json`)

App đọc dữ liệu lịch tĩnh từ `assets/nba_schedule.json` (mỗi trận lưu `{utc, date, home, away}`, tải lần gần nhất ngày **2026-11-13** cho mùa giải 2026–27).
- **Quy tắc tuần fantasy**: Thứ 2 → Chủ nhật theo giờ Mỹ Eastern (`America/New_York`, tự xử lý đổi giờ mùa hè EDT/EST).
- **Hiển thị mặc định**: **Giờ Việt Nam (`ScheduleTimezone.vietnam`, UTC+7)** nên một tuần fantasy hiển thị từ **Thứ 3 → Thứ 2 tuần sau**. Có thể đổi sang `ScheduleTimezone.usEastern` trong `lib/config/constants.dart`.

Khi cần cập nhật lại lịch (ví dụ khi NBA công bố lịch vòng Play-In / Playoffs hoặc đầu mùa giải mới):

```powershell
dart run tools/fetch_schedule.dart
```

Script sẽ thử lần lượt NBA CDN rồi fallback sang ESPN API, lưu giờ bắt đầu `utc` + ngày `America/New_York`, lọc bỏ các trận `TBD`, ghi đè `assets/nba_schedule.json`, và tự động kiểm tra khớp đủ 30/30 mã đội với Sleeper API.
