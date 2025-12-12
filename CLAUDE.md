# 財務計算工具 - 專案文件
最後更新時間：2025-12-12 16:45 | 由 Claude AI 編輯

## 專案概述

這是一個基於 Flutter Web 的財務計算工具，整合了**貸款計算器**和**定投複利計算器**兩大功能，提供專業的財務分析與規劃服務。

### 🌐 線上網址
https://lchuang8211.github.io/loan_calculator_web/

### 📦 Repository
https://github.com/lchuang8211/loan_calculator_web

---

## 專案結構

### 資料夾架構
```
loan_calculator_web/
├── lib/
│   ├── main.dart                              # 應用入口 + 路由配置
│   ├── pages/                                 # Feature-first 架構
│   │   ├── home_page.dart                     # 主頁（功能選單）
│   │   ├── loan_calculator_page.dart          # 貸款計算器頁面
│   │   └── investment_calculator_page.dart    # 定投複利計算器頁面
│   └── compound_investment_main.dart          # (舊版參考檔案，可刪除)
│
├── web/                                       # Web 平台配置
│   ├── index.html                             # HTML 入口
│   ├── manifest.json                          # PWA manifest
│   └── icons/                                 # App icons
│
├── test/                                      # 測試檔案
│   └── widget_test.dart
│
├── pubspec.yaml                               # 依賴配置
├── README.md                                  # 專案說明
├── CLAUDE.md                                  # 本文件
└── .gitignore
```

### Branch 結構
- **main**: 源碼分支，存放所有開發程式碼
- **gh-pages**: 部署分支，只存放構建後的 Web 應用

---

## 功能說明

### 1. 主頁 (HomePage)
**檔案位置**: `lib/pages/home_page.dart`

**功能**：
- 提供清晰的功能選單
- 兩個功能入口卡片設計
- 響應式佈局（支援不同螢幕尺寸）
- Material Design 3 風格

**技術要點**：
- 使用 `SingleChildScrollView` 避免小螢幕 overflow
- 卡片式 UI，良好的視覺層次
- Navigator push 進行頁面導航

---

### 2. 貸款計算器 (LoanCalculatorPage)
**檔案位置**: `lib/pages/loan_calculator_page.dart`

**核心功能**：
1. **還款方式選擇**
   - 本息攤還（等額本息）
   - 本金攤還（等額本金）

2. **基本參數設定**
   - 貸款總額
   - 貸款期數（月）
   - 年利率
   - 起始時間

3. **提前償還規劃**
   - 支援多筆提前償還
   - 自動計算節省的利息
   - 提前償還影響分析

4. **視覺化分析**
   - 利息趨勢圖（fl_chart）
   - 貸款餘額圖
   - 詳細還款明細表

**資料模型**：
```dart
enum LoanType {
  equalPrincipal,  // 等額本金
  equalPayment,    // 等額本息
}

class EarlyPayment {
  final int period;    // 提前償還期數
  final double amount; // 償還金額
}
```

**計算公式**：
- **等額本息**: 每期還款 = 本金 × 月利率 × (1+月利率)^n / [(1+月利率)^n - 1]
- **等額本金**: 每期本金 = 總本金 / 總期數；每期利息 = 剩餘本金 × 月利率

---

### 3. 定投複利計算器 (InvestmentCalculatorPage)
**檔案位置**: `lib/pages/investment_calculator_page.dart`

**核心功能**：
1. **投資參數設定**
   - 開始日期 / 結算日期
   - 初始金額
   - 每月定投金額
   - 年化報酬率
   - 複利週期（天數）

2. **特別存款管理**
   - 支援在特定期數新增額外存款
   - 統計每期特別存款次數
   - 視覺化標示（橘色背景）

3. **視覺化分析**
   - 總資產成長圖
   - 每期利息金額圖
   - 互動式圖表（hover tooltip）
   - 詳細各期資料表格

**資料模型**：
```dart
class SpecialDeposit {
  final int period;    // 期數
  final double amount; // 金額
}

class PeriodDetail {
  final int period;                    // 期數
  final DateTime date;                 // 日期
  final double principal;              // 本金
  final double monthlyInvestment;      // 定投金額
  final double specialDeposit;         // 特別存款
  final int specialDepositCount;       // 特別存款次數
  final double periodInterest;         // 本期利息
  final double accumulatedInterest;    // 累計利息
  final double totalInvested;          // 總投入
  final double totalAssets;            // 總資產
}
```

**計算公式**：
- **每期利率**: r = (年化報酬率 / 100) × (複利週期天數 / 365)
- **本期利息**: 前期總資產 × 每期利率
- **總資產**: 前期總資產 × (1 + r) + 本期投入
- **總收益**: 總資產 - 總投入

---

## 技術棧

### 核心框架
- **Flutter**: 3.35.6
- **Dart**: 3.9.2
- **Material Design 3**: ✅

### 主要依賴套件
```yaml
dependencies:
  flutter:
    sdk: flutter
  fl_chart: ^0.69.0      # 圖表繪製
  intl: ^0.19.0          # 日期格式化

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### 架構模式
- **Feature-first Architecture**: 按功能模組組織程式碼
- **Flutter 原生路由**: 簡單直接，適合小型專案
- **StatefulWidget**: 狀態管理

---

## 部署流程

### 完整部署步驟

#### 1️⃣ **開發階段**
```bash
# 確保在 main branch
git checkout main

# 進行開發...
# 修改 lib/ 下的檔案

# 測試
flutter test
flutter analyze
```

#### 2️⃣ **提交變更到 main**
```bash
# 加入變更
git add .

# 提交 (使用規範的 commit message)
git commit -m "feat: 新增功能描述

詳細說明...

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 推送到 remote
git push origin main
```

#### 3️⃣ **構建 Web 應用**
```bash
# 確保在 main branch
git checkout main

# 構建 (base-href 必須正確)
flutter build web --base-href "/loan_calculator_web/" --release
```

**重要參數說明**：
- `--base-href "/loan_calculator_web/"`: GitHub Pages 的 repository 路徑
- `--release`: 生產環境優化構建
- 輸出路徑: `build/web/`

#### 4️⃣ **部署到 gh-pages**

**方法一：手動部署**
```bash
# 1. 備份 build/web 到臨時目錄
cp -r build/web /tmp/gh-pages-temp

# 2. 切換到 gh-pages branch
git checkout gh-pages

# 3. 清理舊內容
git rm -rf .
git clean -fxd

# 4. 複製新內容
cp -r /tmp/gh-pages-temp/* .

# 5. 刪除不需要的檔案
rm -rf android ios macos build .dart_tool .last_build_id

# 6. 提交
git add -A
git commit -m "deploy: update web app

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 7. 推送 (如果遇到 rejected，先 pull --rebase)
git pull origin gh-pages --rebase
git push origin gh-pages

# 8. 切回 main
git checkout main

# 9. 清理臨時檔案
rm -rf /tmp/gh-pages-temp
```

**方法二：自動化腳本 (建議)**

創建 `deploy.sh`:
```bash
#!/bin/bash
set -e

echo "📦 Building Flutter Web..."
flutter build web --base-href "/loan_calculator_web/" --release

echo "💾 Backing up build..."
cp -r build/web /tmp/gh-pages-temp

echo "🔄 Switching to gh-pages..."
git checkout gh-pages

echo "🧹 Cleaning old content..."
git rm -rf . 2>/dev/null || true
git clean -fxd

echo "📋 Copying new content..."
cp -r /tmp/gh-pages-temp/* .
rm -rf android ios macos build .dart_tool .last_build_id 2>/dev/null || true

echo "📝 Committing..."
git add -A
git commit -m "deploy: update web app

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

echo "⬆️  Pushing to remote..."
git pull origin gh-pages --rebase
git push origin gh-pages

echo "✅ Switching back to main..."
git checkout main
rm -rf /tmp/gh-pages-temp

echo "🎉 Deployment complete!"
echo "🌐 Visit: https://lchuang8211.github.io/loan_calculator_web/"
```

使用方式：
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 注意事項

### ⚠️ 部署相關

1. **base-href 設定**
   - 必須與 GitHub repository 名稱一致
   - 格式: `/repository-name/`
   - 前後都要有斜線 `/`

2. **gh-pages branch 管理**
   - ❌ 不要在 gh-pages 直接開發
   - ❌ 不要提交源碼到 gh-pages
   - ✅ 只存放 `build/web/` 的內容
   - ✅ 刪除 android, ios, macos 等不需要的目錄

3. **部署時間**
   - GitHub Pages 通常需要 1-2 分鐘更新
   - 可以在 repository Settings → Pages 查看部署狀態

4. **快取問題**
   - 如果更新沒有反映，嘗試 Ctrl+Shift+R 強制刷新
   - 或使用無痕模式開啟

### ⚠️ 開發相關

1. **棄用警告 (Deprecation)**
   目前專案有以下非關鍵警告：
   ```
   - withOpacity (建議使用 withValues)
   - RadioListTile 的 groupValue/onChanged (建議使用 RadioGroup)
   ```
   這些 API 仍可正常使用，但未來版本可能移除。

2. **依賴更新**
   ```bash
   # 檢查可更新的套件
   flutter pub outdated

   # 更新套件
   flutter pub upgrade
   ```

3. **測試覆蓋率**
   - 目前只有基本的 widget 測試
   - 建議增加計算邏輯的單元測試

4. **效能優化**
   - 圖表資料量大時可能影響效能
   - 考慮使用分頁或虛擬滾動

### ⚠️ 使用者體驗

1. **輸入驗證**
   - 目前有基本驗證
   - 可增強錯誤提示訊息

2. **載入狀態**
   - 計算時可顯示 loading indicator
   - 大量資料渲染時的進度提示

3. **行動裝置適配**
   - 圖表在小螢幕的顯示優化
   - 表格的橫向滾動體驗

---

## 未來可擴充的進階功能

### 🎯 短期擴充 (1-2 週)

#### 1. **資料持久化**
**Why**: 讓使用者可以儲存和讀取計算結果

**實作方向**：
```dart
// 使用 shared_preferences 儲存本地資料
import 'package:shared_preferences/shared_preferences.dart';

class CalculationHistory {
  Future<void> saveCalculation(String name, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    // 實作儲存邏輯
  }

  Future<List<Map<String, dynamic>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // 實作讀取邏輯
  }
}
```

**潛在陷阱**：
- shared_preferences 容量限制（建議每筆 < 1MB）
- Web 平台使用 localStorage，可能被使用者清除
- 需要處理版本升級時的資料遷移

#### 2. **匯出功能**
**Why**: 使用者可能需要分享或列印計算結果

**實作方向**：
- PDF 匯出 (使用 `pdf` package)
- CSV 匯出表格資料
- 圖片匯出圖表 (使用 `screenshot` package)

**範例**：
```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> exportToPdf(List<PeriodDetail> details) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Table(
        // 生成 PDF 表格
      ),
    ),
  );

  // Web 平台下載
  final bytes = await pdf.save();
  // 觸發瀏覽器下載
}
```

#### 3. **比較模式**
**Why**: 使用者可以並排比較不同參數的計算結果

**UI 設計**：
```
+------------------+------------------+
|   方案 A         |   方案 B         |
+------------------+------------------+
| 總利息: 100萬    | 總利息: 95萬     |
| 總還款: 600萬    | 總還款: 595萬    |
+------------------+------------------+
```

#### 4. **多語言支援 (i18n)**
**Why**: 擴展使用者群

**使用套件**: `flutter_localizations` + `intl`

```dart
// lib/l10n/app_en.arb
{
  "appTitle": "Financial Calculator",
  "loanCalculator": "Loan Calculator",
  "investmentCalculator": "Investment Calculator"
}

// lib/l10n/app_zh_TW.arb
{
  "appTitle": "財務計算工具",
  "loanCalculator": "貸款計算器",
  "investmentCalculator": "定投複利計算器"
}
```

---

### 🚀 中期擴充 (1-2 個月)

#### 5. **帳戶系統 + 雲端同步**
**Why**: 多裝置同步、資料備份

**技術選擇**：
- Firebase Authentication (Google, Email 登入)
- Firebase Firestore (資料儲存)
- 離線優先架構

**架構設計**：
```
lib/
  ├── services/
  │   ├── auth_service.dart           # 認證服務
  │   ├── firestore_service.dart      # 資料庫服務
  │   └── sync_service.dart           # 同步邏輯
  └── models/
      └── user_calculation.dart       # 使用者計算資料模型
```

**潛在陷阱**：
- Firebase 免費額度限制
- 離線/線上資料同步衝突
- 隱私權政策要求

#### 6. **進階圖表功能**
**Why**: 更豐富的資料視覺化

**功能清單**：
- 餅圖：本金/利息佔比
- 區域圖：累積資產成長
- 比較圖：多方案並排
- 自訂時間範圍

**使用 fl_chart 進阶功能**：
```dart
PieChart(
  PieChartData(
    sections: [
      PieChartSectionData(
        value: totalPrincipal,
        title: '本金',
        color: Colors.blue,
      ),
      PieChartSectionData(
        value: totalInterest,
        title: '利息',
        color: Colors.red,
      ),
    ],
  ),
)
```

#### 7. **計算範本庫**
**Why**: 常用情境快速套用

**範例範本**：
- 首購族房貸規劃（20% 頭期款，30年期）
- 退休金定投計劃（月投 2萬，8% 年化）
- 短期理財目標（5年存 100萬）

**資料結構**：
```dart
class CalculationTemplate {
  final String id;
  final String name;
  final String description;
  final CalculatorType type;
  final Map<String, dynamic> defaultValues;
  final String? imageUrl;
}
```

#### 8. **通知提醒功能**
**Why**: 提醒使用者還款日、定投日

**實作**：
- Web Push Notification
- 使用 Service Worker
- 需要使用者授權

---

### 🌟 長期擴充 (3-6 個月)

#### 9. **AI 財務建議**
**Why**: 提供個性化建議

**功能構想**：
- 分析使用者財務狀況
- 提供優化建議（提前還款時機、投資組合調整）
- 風險評估

**技術方案**：
- 整合 Claude API / OpenAI API
- 使用 prompt engineering
- 本地計算 + AI 輔助

**範例 Prompt**：
```
根據以下財務資料：
- 貸款總額：500萬
- 月收入：10萬
- 月支出：6萬
- 現有存款：50萬

請提供：
1. 最佳提前還款策略
2. 每月定投建議金額
3. 財務風險評估
```

#### 10. **即時利率資訊**
**Why**: 提供最新市場利率參考

**資料來源**：
- 中央銀行公開資料
- 各銀行官網 API
- 第三方財經資料服務

**實作**：
```dart
class RateService {
  Future<List<BankRate>> fetchCurrentRates() async {
    // 抓取最新利率
  }

  Map<String, double> getRateRange() {
    // 取得利率區間（最低/最高/平均）
  }
}
```

#### 11. **社群分享功能**
**Why**: 使用者可以分享計算結果、交流心得

**功能**：
- 生成分享連結（含參數）
- 社群媒體分享（Twitter, Facebook, Line）
- QR Code 生成

**範例 URL**：
```
https://lchuang8211.github.io/loan_calculator_web/
  ?type=loan
  &amount=5000000
  &months=240
  &rate=2
```

#### 12. **Mobile App 版本**
**Why**: 更好的行動體驗、離線使用

**優勢**：
- 推播通知
- 離線完整功能
- 原生效能
- 裝置整合（Face ID, 指紋辨識）

**技術**：
- 同一份 Flutter codebase
- 針對 iOS/Android 優化
- 上架 App Store / Google Play

---

## State Management 升級建議

### 目前狀況
使用 `StatefulWidget` + `setState()`

### 為什麼要升級
- 程式碼越來越複雜時，狀態管理會變得混亂
- 難以測試
- 父子元件狀態傳遞繁瑣

### 建議方案

#### **方案一：Provider (簡單專案)**
適合本專案目前規模

```dart
// lib/providers/loan_calculator_provider.dart
class LoanCalculatorProvider extends ChangeNotifier {
  double _loanAmount = 5000000;
  int _months = 240;
  double _rate = 2.0;

  double get loanAmount => _loanAmount;

  void setLoanAmount(double value) {
    _loanAmount = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> calculateSchedule() {
    // 計算邏輯
    return schedule;
  }
}

// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LoanCalculatorProvider()),
    ChangeNotifierProvider(create: (_) => InvestmentCalculatorProvider()),
  ],
  child: MyApp(),
)
```

#### **方案二：Riverpod (中型專案)**
更強大、更易測試

```dart
// lib/providers/loan_providers.dart
final loanAmountProvider = StateProvider<double>((ref) => 5000000);
final monthsProvider = StateProvider<int>((ref) => 240);
final rateProvider = StateProvider<double>((ref) => 2.0);

final scheduleProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final amount = ref.watch(loanAmountProvider);
  final months = ref.watch(monthsProvider);
  final rate = ref.watch(rateProvider);

  return calculateSchedule(amount, months, rate);
});
```

#### **方案三：BLoC (大型專案)**
本專案可能過度設計，但如果團隊規模擴大可考慮

---

## 程式碼品質提升

### 1. **單元測試**
目前測試覆蓋率低，建議增加：

```dart
// test/calculator_test.dart
void main() {
  group('Loan Calculator', () {
    test('等額本息計算正確', () {
      final result = calculateEqualPayment(
        amount: 1000000,
        months: 12,
        rate: 2.0,
      );

      expect(result['totalInterest'], closeTo(10000, 100));
    });

    test('提前還款節省計算正確', () {
      // 測試提前還款邏輯
    });
  });
}
```

### 2. **程式碼規範**
建立團隊 coding style：

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_final_fields
    - avoid_print
    - require_trailing_commas
```

### 3. **CI/CD**
使用 GitHub Actions 自動化：

```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.6'

      - run: flutter pub get
      - run: flutter test
      - run: flutter build web --base-href "/loan_calculator_web/" --release

      - name: Deploy to gh-pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

---

## 效能優化建議

### 1. **Lazy Loading**
大量資料不要一次全部渲染：

```dart
// 使用 ListView.builder
ListView.builder(
  itemCount: _schedule.length,
  itemBuilder: (context, index) {
    final item = _schedule[index];
    return ListTile(/* ... */);
  },
)
```

### 2. **計算優化**
```dart
// 使用 memoization 避免重複計算
import 'package:collection/collection.dart';

final _calculationCache = HashMap<String, dynamic>();

dynamic _getCachedOrCalculate(String key, Function calculator) {
  if (_calculationCache.containsKey(key)) {
    return _calculationCache[key];
  }
  final result = calculator();
  _calculationCache[key] = result;
  return result;
}
```

### 3. **圖表效能**
```dart
// 資料點過多時進行採樣
List<FlSpot> _sampleData(List<FlSpot> data, int maxPoints) {
  if (data.length <= maxPoints) return data;

  final step = data.length / maxPoints;
  return List.generate(
    maxPoints,
    (i) => data[(i * step).floor()],
  );
}
```

---

## 資安考量

### 1. **輸入驗證**
```dart
// 驗證使用者輸入
double? _validateAmount(String value) {
  final amount = double.tryParse(value);
  if (amount == null || amount <= 0 || amount > 1000000000) {
    return null; // 無效輸入
  }
  return amount;
}
```

### 2. **XSS 防護**
Flutter Web 自動處理大部分 XSS 風險，但要注意：
- 不要使用 `HtmlElementView` 載入不信任的 HTML
- 避免動態執行 JavaScript

### 3. **HTTPS**
GitHub Pages 預設 HTTPS，確保：
- 所有 API 請求使用 HTTPS
- 不要混合 HTTP/HTTPS 內容

---

## 常見問題 (FAQ)

### Q1: 為什麼部署後網站是空白的？
**A**: 檢查以下項目：
1. `--base-href` 是否正確
2. GitHub Pages 設定是否啟用 gh-pages branch
3. 瀏覽器 Console 是否有錯誤訊息
4. 等待 1-2 分鐘讓 GitHub Pages 更新

### Q2: 如何本地測試 Web 版？
**A**:
```bash
flutter run -d chrome
# 或
flutter run -d web-server --web-port=8080
# 瀏覽器開啟 http://localhost:8080
```

### Q3: 圖表在行動裝置上顯示異常？
**A**:
- 確保圖表容器有明確的寬高
- 使用 `LayoutBuilder` 適配螢幕尺寸
- 測試不同裝置的顯示效果

### Q4: 如何更改網站標題和 icon？
**A**:
- 標題: 修改 `web/index.html` 的 `<title>` 標籤
- Icon: 替換 `web/icons/` 下的圖片檔案
- Manifest: 修改 `web/manifest.json`

### Q5: 可以部署到其他平台嗎？
**A**: 可以！例如：
- **Netlify**: 拖拽 `build/web` 資料夾即可
- **Vercel**: 連結 GitHub repo，自動部署
- **Firebase Hosting**: `firebase deploy`

---

## 維護指南

### 定期維護檢查清單

#### 每月
- [ ] 執行 `flutter pub outdated` 檢查套件更新
- [ ] 檢查 GitHub Security Alerts
- [ ] 測試所有功能是否正常

#### 每季
- [ ] 升級 Flutter SDK 到最新穩定版
- [ ] 更新主要依賴套件
- [ ] 執行效能分析
- [ ] 檢視使用者回饋（如果有）

#### 每年
- [ ] 重構老舊程式碼
- [ ] 檢討架構是否需要調整
- [ ] 評估新技術導入（如 Wasm）
- [ ] 更新文件

### 緊急修復流程

1. **發現嚴重 Bug**
   ```bash
   git checkout main
   git checkout -b hotfix/critical-bug
   # 修復 bug
   git commit -m "fix: critical bug description"
   git push origin hotfix/critical-bug
   # 建立 PR 審查後合併
   ```

2. **快速部署修復**
   ```bash
   git checkout main
   git pull origin main
   ./deploy.sh  # 使用自動化腳本
   ```

---

## 貢獻指南

### Commit Message 規範

遵循 Conventional Commits：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type**:
- `feat`: 新功能
- `fix`: Bug 修復
- `docs`: 文件更新
- `style`: 程式碼格式（不影響功能）
- `refactor`: 重構
- `perf`: 效能優化
- `test`: 測試
- `chore`: 構建/工具變更

**範例**:
```
feat(loan): add early payment comparison feature

- Added side-by-side comparison view
- Implemented savings calculation
- Updated UI for better visualization

Closes #123
```

### Pull Request 流程

1. Fork repository
2. 創建 feature branch
3. 開發並測試
4. 提交 PR 附上詳細說明
5. 等待 Code Review
6. 合併後刪除 branch

---

## 聯絡資訊

- **Repository**: https://github.com/lchuang8211/loan_calculator_web
- **Issues**: https://github.com/lchuang8211/loan_calculator_web/issues
- **Website**: https://lchuang8211.github.io/loan_calculator_web/

---

## 版本歷史

### v1.0.0 (2025-12-12)
- ✨ 整合貸款計算器和定投複利計算器
- 🎨 全新主頁 UI 設計
- 📊 互動式圖表功能
- 🚀 部署至 GitHub Pages
- 📝 完整專案文件

---

## 授權

本專案使用 MIT License。

---

**最後更新時間：2025-12-12 16:45 | 由 Claude AI 編輯**
