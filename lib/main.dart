// ============================================================================
// 台灣房貸試算工具 - 進階版
// 功能：等額本息/本金、多筆提前償還、雙Y軸圖表、時間軸顯示
// ============================================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:intl/intl.dart';

void main() => runApp(const LoanApp());

class LoanApp extends StatelessWidget {
  const LoanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const LoanCalculatorPage(), debugShowCheckedModeBanner: false);
  }
}

// ============================================================================
// 資料模型
// ============================================================================

/// 還款方式
enum LoanType {
  equalPrincipal, // 本金攤還（等額本金）
  equalPayment, // 本息攤還（等額本息）
}

/// 提前償還記錄
class EarlyPayment {
  final int period;
  final double amount;

  EarlyPayment({required this.period, required this.amount});
}

// ============================================================================
// 主頁面
// ============================================================================

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  // 控制器
  final _amountCtrl = TextEditingController(text: "5000000");
  final _monthsCtrl = TextEditingController(text: "240");
  final _rateCtrl = TextEditingController(text: "2");
  final _earlyAmountCtrl = TextEditingController();
  final _earlyPeriodCtrl = TextEditingController();

  // 狀態變數
  DateTime _startDate = DateTime.now();
  LoanType _loanType = LoanType.equalPayment;
  List<EarlyPayment> _earlyPayments = [];
  List<Map<String, dynamic>> _schedule = [];
  double _totalInterest = 0;
  double _totalPayment = 0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  // ==========================================================================
  // 計算邏輯
  // ==========================================================================

  /// 主計算函數
  void _calculate() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final months = int.tryParse(_monthsCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;

    // 驗證輸入
    if (amount <= 0 || months <= 0 || rate < 0 || rate > 100) {
      setState(() {
        _schedule = [];
        _totalInterest = 0;
        _totalPayment = 0;
      });
      return;
    }

    final monthlyRate = rate / 100 / 12;
    double remaining = amount;
    List<Map<String, dynamic>> temp = [];
    double interestSum = 0;
    double totalPay = 0;

    // 建立提前償還映射表
    Map<int, double> earlyPayMap = {};
    for (var ep in _earlyPayments) {
      if (ep.period <= months) {
        earlyPayMap[ep.period] = (earlyPayMap[ep.period] ?? 0) + ep.amount;
      }
    }

    int currentPeriod = 1;
    int remainingMonths = months;

    // 計算還款排程
    while (currentPeriod <= months && remaining > 0.01) {
      double principal, interest, payment;

      if (_loanType == LoanType.equalPayment) {
        // 等額本息
        payment = remainingMonths > 0 && monthlyRate > 0
            ? remaining * monthlyRate / (1 - pow(1 + monthlyRate, -remainingMonths)).toDouble()
            : 0;
        interest = remaining * monthlyRate;
        principal = payment - interest;
      } else {
        // 等額本金
        principal = remainingMonths > 0 ? remaining / remainingMonths : 0;
        interest = remaining * monthlyRate;
        payment = principal + interest;
      }

      remaining -= principal;
      if (remaining < 0) remaining = 0;

      // 計算該期日期
      final date = DateTime(_startDate.year, _startDate.month + currentPeriod, 1);

      temp.add({
        "period": currentPeriod,
        "date": date,
        "principal": principal,
        "interest": interest,
        "payment": payment,
        "remaining": remaining,
        "earlyPay": 0.0,
        "savedPayment": 0.0,
      });

      interestSum += interest;
      totalPay += payment;

      // 處理提前償還
      if (earlyPayMap.containsKey(currentPeriod)) {
        final earlyAmount = earlyPayMap[currentPeriod]!;
        final saved = _calcSavedPayment(remaining, earlyAmount, monthlyRate, remainingMonths - 1);

        remaining -= earlyAmount;
        if (remaining < 0) remaining = 0;

        temp.last["earlyPay"] = earlyAmount;
        temp.last["savedPayment"] = saved;
        temp.last["remaining"] = remaining;
        totalPay += earlyAmount;
      }

      currentPeriod++;
      remainingMonths--;
    }

    setState(() {
      _schedule = temp;
      _totalInterest = interestSum;
      _totalPayment = totalPay;
    });
  }

  /// 計算提前償還可節省的總還款
  double _calcSavedPayment(double remaining, double earlyAmount, double monthlyRate, int months) {
    if (months <= 0 || earlyAmount <= 0 || remaining <= 0 || earlyAmount >= remaining) {
      return 0;
    }

    try {
      double withoutEarly = 0;
      double withEarly = 0;

      // 計算未提前償還的總還款
      double temp = remaining;
      for (int i = 0; i < months; i++) {
        if (temp < 0.01) break;

        if (_loanType == LoanType.equalPayment) {
          final denom = (1 - pow(1 + monthlyRate, -(months - i))).toDouble();
          if (denom <= 0) break;
          withoutEarly += temp * monthlyRate / denom;
          temp -= (temp * monthlyRate / denom - temp * monthlyRate);
        } else {
          withoutEarly += temp / months + temp * monthlyRate;
          temp -= temp / months;
        }
      }

      // 計算提前償還後的總還款
      temp = remaining - earlyAmount;
      for (int i = 0; i < months; i++) {
        if (temp < 0.01) break;

        if (_loanType == LoanType.equalPayment) {
          final denom = (1 - pow(1 + monthlyRate, -(months - i))).toDouble();
          if (denom <= 0) break;
          withEarly += temp * monthlyRate / denom;
          temp -= (temp * monthlyRate / denom - temp * monthlyRate);
        } else {
          withEarly += temp / months + temp * monthlyRate;
          temp -= temp / months;
        }
      }

      final saved = withoutEarly - withEarly;
      return saved > 0 ? saved : 0;
    } catch (e) {
      return 0;
    }
  }

  // ==========================================================================
  // UI 元件
  // ==========================================================================

  /// 輸入欄位
  Widget _buildInputField(String label, TextEditingController ctrl, {String? hint}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) => _calculate(),
    );
  }

  /// 提前償還列表項目
  Widget _buildEarlyPaymentItem(int index, EarlyPayment ep) {
    return Card(
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text("第 ${ep.period} 期償還 ${ep.amount.toStringAsFixed(0)} 元"),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () {
            setState(() => _earlyPayments.removeAt(index));
            _calculate();
          },
        ),
      ),
    );
  }

  /// 利息趨勢圖表（右Y軸）
  Widget _buildInterestChart() {
    if (_schedule.isEmpty) return const SizedBox();

    final maxInterest = _schedule.map((s) => s["interest"] as double).reduce(max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("利息趨勢", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final period = spot.x.toInt();
                      final date = _schedule[period - 1]["date"] as DateTime;
                      return LineTooltipItem(
                        '${DateFormat('yyyy-MM').format(date)}\n第 $period 期\n利息: ${spot.y.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('利息', style: TextStyle(fontSize: 11)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (v, m) =>
                        Text('${(v / 1000).toStringAsFixed(0)}K', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) => v % 12 == 0
                        ? Text('${(v / 12).toInt()}年', style: const TextStyle(fontSize: 10))
                        : const Text(''),
                  ),
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _schedule.map((s) => FlSpot(s["period"].toDouble(), s["interest"].toDouble())).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 貸款餘額圖表（左Y軸）
  Widget _buildRemainingChart() {
    if (_schedule.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("貸款餘額", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final period = spot.x.toInt();
                      final date = _schedule[period - 1]["date"] as DateTime;
                      return LineTooltipItem(
                        '${DateFormat('yyyy-MM').format(date)}\n第 $period 期\n餘額: ${spot.y.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('貸款餘額', style: TextStyle(fontSize: 11)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (v, m) =>
                        Text('${(v / 10000).toStringAsFixed(0)}萬', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) => v % 12 == 0
                        ? Text('${(v / 12).toInt()}年', style: const TextStyle(fontSize: 10))
                        : const Text(''),
                  ),
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _schedule.map((s) => FlSpot(s["period"].toDouble(), s["remaining"].toDouble())).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 日期選擇器
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _calculate();
      });
    }
  }

  /// 新增提前償還
  void _addEarlyPayment() {
    final amount = (double.tryParse(_earlyAmountCtrl.text) ?? 0) * 10000;
    final period = int.tryParse(_earlyPeriodCtrl.text) ?? 0;
    final totalMonths = int.tryParse(_monthsCtrl.text) ?? 0;

    if (amount <= 0) {
      _showSnackBar("償還金額必須大於 0", Colors.red);
      return;
    }

    if (period <= 0) {
      _showSnackBar("償還期數必須大於 0", Colors.red);
      return;
    }

    if (totalMonths > 0 && period > totalMonths) {
      _showSnackBar("償還期數($period)不能超過貸款總期數($totalMonths)", Colors.red);
      return;
    }

    setState(() {
      _earlyPayments.add(EarlyPayment(period: period, amount: amount));
      _earlyPayments.sort((a, b) => a.period.compareTo(b.period));
      _earlyAmountCtrl.clear();
      _earlyPeriodCtrl.clear();
    });

    _calculate();
    _showSnackBar("已新增：第 $period 期償還 ${amount.toStringAsFixed(0)} 元", Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)));
  }

  // ==========================================================================
  // 主介面
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("台灣貸款試算"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本輸入
            _buildInputField("貸款總額", _amountCtrl, hint: "例: 5000000"),
            const SizedBox(height: 12),
            _buildInputField("貸款期數(月)", _monthsCtrl, hint: "例: 240"),
            const SizedBox(height: 12),
            _buildInputField("年利率 (%)", _rateCtrl, hint: "例: 2"),
            const SizedBox(height: 12),

            // 起始時間選擇
            OutlinedButton.icon(
              onPressed: _selectStartDate,
              icon: const Icon(Icons.calendar_today),
              label: Text("起始時間: ${DateFormat('yyyy-MM').format(_startDate)}"),
            ),

            const SizedBox(height: 20),

            // 提前償還區塊
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("提前償還本金", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _earlyAmountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "償還金額(萬)",
                              hintText: "例: 30",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _earlyPeriodCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "第幾期",
                              hintText: "例: 30",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _addEarlyPayment, child: const Text("新增")),
                      ],
                    ),
                    if (_earlyPayments.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text("已設定提前償還：", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      ..._earlyPayments.asMap().entries.map((e) => _buildEarlyPaymentItem(e.key, e.value)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 還款方式選擇
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text("本息攤還"),
                    subtitle: const Text("等額本息"),
                    value: LoanType.equalPayment,
                    groupValue: _loanType,
                    onChanged: (v) {
                      setState(() => _loanType = v!);
                      _calculate();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text("本金攤還"),
                    subtitle: const Text("等額本金"),
                    value: LoanType.equalPrincipal,
                    groupValue: _loanType,
                    onChanged: (v) {
                      setState(() => _loanType = v!);
                      _calculate();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 總計資訊
            Text("總利息：${_totalInterest.toStringAsFixed(0)} 元", style: const TextStyle(fontSize: 16)),
            Text(
              "總還款額：${_totalPayment.toStringAsFixed(0)} 元",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // 圖表區塊
            _buildInterestChart(),
            const SizedBox(height: 20),
            _buildRemainingChart(),

            const SizedBox(height: 20),

            // 還款明細表格
            const Text("還款明細", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildScheduleTable(),
          ],
        ),
      ),
    );
  }

  /// 還款明細表格
  Widget _buildScheduleTable() {
    return Column(
      children: [
        // 表頭
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text("期數", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Expanded(
                child: Text("本金", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Expanded(
                child: Text("利息", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Expanded(
                child: Text("繳費", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Expanded(
                child: Text("提前償還", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Expanded(
                child: Text("節省", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Expanded(
                child: Text("餘額", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 表格內容
        ..._schedule.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final date = s["date"] as DateTime;
          final dateStr = DateFormat('yyyy-MM').format(date);

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: s['earlyPay'] > 0 ? Colors.amber.shade100 : (i % 2 == 0 ? Colors.grey.shade50 : Colors.white),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text("第${s['period']}期\n($dateStr)", style: const TextStyle(fontSize: 10))),
                Expanded(child: Text(s['principal'].toStringAsFixed(0), style: const TextStyle(fontSize: 10))),
                Expanded(child: Text(s['interest'].toStringAsFixed(0), style: const TextStyle(fontSize: 10))),
                Expanded(child: Text(s['payment'].toStringAsFixed(0), style: const TextStyle(fontSize: 10))),
                Expanded(
                  child: Text(
                    s['earlyPay'] > 0 ? s['earlyPay'].toStringAsFixed(0) : "-",
                    style: TextStyle(
                      fontSize: 10,
                      color: s['earlyPay'] > 0 ? Colors.red.shade700 : Colors.grey,
                      fontWeight: s['earlyPay'] > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    s['savedPayment'] > 0 ? s['savedPayment'].toStringAsFixed(0) : "-",
                    style: TextStyle(
                      fontSize: 10,
                      color: s['savedPayment'] > 0 ? Colors.green.shade700 : Colors.grey,
                      fontWeight: s['savedPayment'] > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(child: Text(s['remaining'].toStringAsFixed(0), style: const TextStyle(fontSize: 10))),
              ],
            ),
          );
        }),
      ],
    );
  }
}
