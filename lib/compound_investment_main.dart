import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const CompoundInvestmentApp());
}

class CompoundInvestmentApp extends StatelessWidget {
  const CompoundInvestmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '定投複利計算器',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const InvestmentCalculator(),
    );
  }
}

class SpecialDeposit {
  final int period;
  final double amount;

  SpecialDeposit({required this.period, required this.amount});
}

class InvestmentCalculator extends StatefulWidget {
  const InvestmentCalculator({super.key});

  @override
  State<InvestmentCalculator> createState() => _InvestmentCalculatorState();
}

class _InvestmentCalculatorState extends State<InvestmentCalculator> {
  final _initialAmountController = TextEditingController(text: '100000');
  final _monthlyInvestmentController = TextEditingController(text: '10000');
  final _annualRateController = TextEditingController(text: '8.0');
  final _compoundCycleController = TextEditingController(text: '30');

  DateTime _startDate = DateTime(2024, 1, 1);
  DateTime _endDate = DateTime(2025, 12, 31);

  Map<String, dynamic>? _result;
  List<PeriodDetail>? _periodDetails;
  final List<SpecialDeposit> _specialDeposits = [];

  @override
  void dispose() {
    _initialAmountController.dispose();
    _monthlyInvestmentController.dispose();
    _annualRateController.dispose();
    _compoundCycleController.dispose();
    super.dispose();
  }

  void _calculate() {
    final initialAmount = double.tryParse(_initialAmountController.text) ?? 0;
    final monthlyInvestment = double.tryParse(_monthlyInvestmentController.text) ?? 0;
    final annualRate = double.tryParse(_annualRateController.text) ?? 0;
    final compoundCycleDays = int.tryParse(_compoundCycleController.text) ?? 30;

    final result = calculateInvestmentReturn(
      startDate: _startDate,
      endDate: _endDate,
      initialAmount: initialAmount,
      monthlyInvestment: monthlyInvestment,
      annualRate: annualRate,
      compoundCycleDays: compoundCycleDays,
      specialDeposits: _specialDeposits,
    );

    setState(() {
      _result = result['summary'];
      _periodDetails = result['details'];
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showFormulaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('複利計算公式說明'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('1. 每期利率計算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('r = (Y / 100) × (Z / 365)'),
              const Text('r: 每期利率\nY: 年化報酬率\nZ: 複利週期天數'),
              const Divider(height: 24),
              const Text('2. 初始金額終值', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('FV₀ = X1 × (1 + r)ⁿ'),
              const Text('FV₀: 初始金額終值\nX1: 初始金額\nn: 複利期數'),
              const Divider(height: 24),
              const Text('3. 定投終值', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('FV₁ = Σ [X2 × (1 + r)^(剩餘期數)]'),
              const Text('FV₁: 定投終值\nX2: 每月定投金額'),
              const Divider(height: 24),
              const Text('4. 總終值', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('總終值 = FV₀ + FV₁ + 特別存款'),
              const Text('總收益 = 總終值 - 總投入'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉'))],
      ),
    );
  }

  void _showSpecialDepositDialog() {
    final periodController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增特別存款'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: periodController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '第幾期',
                border: OutlineInputBorder(),
                helperText: '輸入期數（從 0 開始）',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '金額', border: OutlineInputBorder(), suffixText: '元'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final period = int.tryParse(periodController.text);
              final amount = double.tryParse(amountController.text);

              if (period != null && amount != null && amount > 0) {
                setState(() {
                  _specialDeposits.add(SpecialDeposit(period: period, amount: amount));
                  _specialDeposits.sort((a, b) => a.period.compareTo(b.period));
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入有效的期數和金額')));
              }
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }

  void _removeSpecialDeposit(int index) {
    setState(() {
      _specialDeposits.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('定投複利計算器'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              title: '投資參數',
              children: [
                _buildDateField('開始日期 (D1)', _startDate, true),
                const SizedBox(height: 12),
                _buildDateField('結算日期 (D2)', _endDate, false),
                const SizedBox(height: 12),
                _buildTextField('初始金額 (X1)', _initialAmountController, '元'),
                const SizedBox(height: 12),
                _buildTextField('每月定投 (X2)', _monthlyInvestmentController, '元'),
                const SizedBox(height: 12),
                _buildTextField('年化報酬率 (Y)', _annualRateController, '%'),
                const SizedBox(height: 12),
                _buildTextField('複利週期 (Z)', _compoundCycleController, '天'),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: '特別存款',
              children: [
                if (_specialDeposits.isEmpty)
                  const Text('尚未新增特別存款', style: TextStyle(color: Colors.grey))
                else
                  ..._specialDeposits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final deposit = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '第 ${deposit.period} 期：${formatMoney(deposit.amount)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeSpecialDeposit(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _showSpecialDepositDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('新增特別存款'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFormulaDialog,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('公式說明'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('計算', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildCard(
                title: '計算結果',
                children: [
                  _buildResultRow('投資天數', '${_result!['totalDays']} 天'),
                  _buildResultRow('複利期數', '${_result!['compoundPeriods']} 期'),
                  _buildResultRow('定投次數', '${_result!['investmentCount']} 次'),
                  _buildResultRow('特別存款次數', '${_result!['specialDepositCount']} 次'),
                  const Divider(height: 24),
                  _buildResultRow(
                    '總投入金額',
                    formatMoney(_result!['totalInvested']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildResultRow(
                    '期末總值',
                    formatMoney(_result!['finalValue']),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18),
                  ),
                  _buildResultRow(
                    '總收益',
                    formatMoney(_result!['totalProfit']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _result!['totalProfit'] > 0 ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  _buildResultRow(
                    '報酬率',
                    '${_result!['returnRate'].toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _result!['returnRate'] > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTotalAssetsChart(),
              const SizedBox(height: 24),
              _buildInterestChart(),
              const SizedBox(height: 24),
              _buildPeriodDetailsTable(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAssetsChart() {
    if (_periodDetails == null || _periodDetails!.isEmpty) return const SizedBox();

    final maxValue = _periodDetails!.last.totalAssets;
    final maxInvested = _periodDetails!.last.totalInvested;
    final chartMax = max(maxValue, maxInvested) * 1.1;

    return _buildCard(
      title: '總資產成長圖',
      children: [
        InteractiveLineChart(periods: _periodDetails!, maxValue: chartMax, showAssets: true),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildLegend(Colors.blue, '總資產'), const SizedBox(width: 20), _buildLegend(Colors.grey, '累計投入')],
        ),
      ],
    );
  }

  Widget _buildInterestChart() {
    if (_periodDetails == null || _periodDetails!.isEmpty) return const SizedBox();

    final maxInterest = _periodDetails!.map((e) => e.periodInterest).reduce((a, b) => a > b ? a : b);
    final chartMax = maxInterest * 1.2;

    return _buildCard(
      title: '每期利息金額圖',
      children: [
        InteractiveLineChart(periods: _periodDetails!, maxValue: chartMax, showAssets: false),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildLegend(Colors.green, '每期利息')]),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 20, height: 3, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Color _getRowColor(int index, bool hasSpecialDeposit) {
    if (hasSpecialDeposit) {
      return Colors.orange[100]!;
    }
    return index % 2 == 0 ? Colors.white : Colors.grey[50]!;
  }

  Widget _buildPeriodDetailsTable() {
    if (_periodDetails == null || _periodDetails!.isEmpty) return const SizedBox();

    return _buildCard(
      title: '各期詳細資料',
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: Colors.orange[100]),
              const SizedBox(width: 8),
              const Text('橘色背景表示有特別存款的期數'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
            columns: const [
              DataColumn(
                label: Text('期數', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('日期', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('本金', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('定投金額', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('特別存款', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('本期利息', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('累計利息', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('總資產', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            rows: _periodDetails!.asMap().entries.map((entry) {
              final index = entry.key;
              final detail = entry.value;

              return DataRow(
                color: WidgetStateProperty.all(_getRowColor(index, detail.specialDepositCount > 0)),
                cells: [
                  DataCell(Text('${detail.period}')),
                  DataCell(Text(formatDate(detail.date))),
                  DataCell(Text(formatMoneyShort(detail.principal))),
                  DataCell(Text(formatMoneyShort(detail.monthlyInvestment))),
                  DataCell(
                    detail.specialDepositCount > 0
                        ? Text(
                            '${formatMoneyShort(detail.specialDeposit)} (${detail.specialDepositCount})',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          )
                        : const Text('-'),
                  ),
                  DataCell(Text(formatMoneyShort(detail.periodInterest), style: const TextStyle(color: Colors.green))),
                  DataCell(
                    Text(formatMoneyShort(detail.accumulatedInterest), style: const TextStyle(color: Colors.green)),
                  ),
                  DataCell(
                    Text(
                      formatMoneyShort(detail.totalAssets),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String suffix) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
    );
  }

  Widget _buildDateField(String label, DateTime date, bool isStartDate) {
    return InkWell(
      onTap: () => _selectDate(context, isStartDate),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(formatDate(date)), const Icon(Icons.calendar_today, size: 20)],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: style ?? const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Map<String, dynamic> calculateInvestmentReturn({
    required DateTime startDate,
    required DateTime endDate,
    required double initialAmount,
    required double monthlyInvestment,
    required double annualRate,
    required int compoundCycleDays,
    required List<SpecialDeposit> specialDeposits,
  }) {
    final totalDays = endDate.difference(startDate).inDays;
    final compoundPeriods = (totalDays / compoundCycleDays).floor();
    final ratePerPeriod = (annualRate / 100) * (compoundCycleDays / 365);

    List<PeriodDetail> details = [];
    double cumulativeInvested = initialAmount;
    double cumulativeAssets = initialAmount;
    double cumulativeInterest = 0.0;

    // 建立特別存款的 Map 方便查詢，並統計每期的存款筆數
    final specialDepositMap = <int, List<double>>{};
    for (var deposit in specialDeposits) {
      specialDepositMap.putIfAbsent(deposit.period, () => []).add(deposit.amount);
    }

    // 計算每期的詳細資料
    for (int period = 0; period <= compoundPeriods; period++) {
      final periodDate = startDate.add(Duration(days: period * compoundCycleDays));

      // 計算本期新增的定投金額
      double newInvestment = 0.0;
      if (period > 0) {
        final prevPeriodDay = (period - 1) * compoundCycleDays;
        final currentPeriodDay = period * compoundCycleDays;
        final investmentCountInPeriod = (currentPeriodDay / 30).floor() - (prevPeriodDay / 30).floor();
        newInvestment = monthlyInvestment * investmentCountInPeriod;
      }

      // 取得特別存款金額和筆數
      final specialDepositList = specialDepositMap[period] ?? [];
      final specialDepositAmount = specialDepositList.fold<double>(0.0, (sum, amount) => sum + amount);
      final specialDepositCount = specialDepositList.length;

      // 計算本期利息（前期總資產 × 每期利率）
      final periodInterest = period == 0 ? 0.0 : cumulativeAssets * ratePerPeriod;

      // 更新累計數值
      cumulativeInvested += newInvestment + specialDepositAmount;
      cumulativeAssets = cumulativeAssets * (1 + ratePerPeriod) + newInvestment + specialDepositAmount;
      cumulativeInterest += periodInterest;

      details.add(
        PeriodDetail(
          period: period,
          date: periodDate,
          principal: initialAmount,
          monthlyInvestment: newInvestment,
          specialDeposit: specialDepositAmount,
          specialDepositCount: specialDepositCount,
          periodInterest: periodInterest,
          accumulatedInterest: cumulativeInterest,
          totalInvested: cumulativeInvested,
          totalAssets: cumulativeAssets,
        ),
      );
    }

    final finalDetail = details.last;
    final totalProfit = finalDetail.totalAssets - finalDetail.totalInvested;
    final returnRate = (totalProfit / finalDetail.totalInvested) * 100;

    // 計算定投次數
    final investmentCount = (totalDays / 30).floor();

    return {
      'summary': {
        'totalDays': totalDays,
        'compoundPeriods': compoundPeriods,
        'investmentCount': investmentCount,
        'specialDepositCount': specialDeposits.length,
        'finalValue': finalDetail.totalAssets,
        'totalInvested': finalDetail.totalInvested,
        'totalProfit': totalProfit,
        'returnRate': returnRate,
      },
      'details': details,
    };
  }

  String formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String formatMoney(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} 元';
  }

  String formatMoneyShort(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

class PeriodDetail {
  final int period;
  final DateTime date;
  final double principal;
  final double monthlyInvestment;
  final double specialDeposit;
  final int specialDepositCount;
  final double periodInterest;
  final double accumulatedInterest;
  final double totalInvested;
  final double totalAssets;

  PeriodDetail({
    required this.period,
    required this.date,
    required this.principal,
    required this.monthlyInvestment,
    required this.specialDeposit,
    required this.specialDepositCount,
    required this.periodInterest,
    required this.accumulatedInterest,
    required this.totalInvested,
    required this.totalAssets,
  });
}

class InteractiveLineChart extends StatefulWidget {
  final List<PeriodDetail> periods;
  final double maxValue;
  final bool showAssets;

  const InteractiveLineChart({super.key, required this.periods, required this.maxValue, required this.showAssets});

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  int? _hoveredIndex;
  Offset? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            MouseRegion(
              onHover: (event) {
                _updateHoverInfo(event.localPosition, constraints.maxWidth);
              },
              onExit: (event) {
                setState(() {
                  _hoveredIndex = null;
                  _hoverPosition = null;
                });
              },
              child: GestureDetector(
                onTapDown: (details) {
                  _updateHoverInfo(details.localPosition, constraints.maxWidth);
                },
                child: SizedBox(
                  height: 250,
                  child: CustomPaint(
                    painter: LineChartPainter(
                      periods: widget.periods,
                      maxValue: widget.maxValue,
                      showAssets: widget.showAssets,
                      hoveredIndex: _hoveredIndex,
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),
            if (_hoveredIndex != null && _hoverPosition != null) _buildTooltip(constraints.maxWidth, 250),
          ],
        );
      },
    );
  }

  void _updateHoverInfo(Offset position, double chartWidth) {
    const padding = 40.0;
    final width = chartWidth - padding * 2;

    if (position.dx < padding || position.dx > chartWidth - padding) {
      setState(() {
        _hoveredIndex = null;
        _hoverPosition = null;
      });
      return;
    }

    final stepX = width / (widget.periods.length - 1);
    final relativeX = position.dx - padding;
    final index = (relativeX / stepX).round().clamp(0, widget.periods.length - 1);

    setState(() {
      _hoveredIndex = index;
      _hoverPosition = position;
    });
  }

  Widget _buildTooltip(double chartWidth, double chartHeight) {
    if (_hoveredIndex == null || _hoverPosition == null) return const SizedBox();

    final detail = widget.periods[_hoveredIndex!];

    // 計算 tooltip 尺寸
    const tooltipWidth = 200.0;
    const tooltipHeight = 150.0;

    // 計算 tooltip 位置，避免超出邊界
    double left = _hoverPosition!.dx + 10;
    double top = _hoverPosition!.dy - 80;

    // 右邊界檢查
    if (left + tooltipWidth > chartWidth) {
      left = _hoverPosition!.dx - tooltipWidth - 10;
    }

    // 左邊界檢查
    if (left < 0) {
      left = 10;
    }

    // 上邊界檢查
    if (top < 0) {
      top = _hoverPosition!.dy + 20;
    }

    // 下邊界檢查
    if (top + tooltipHeight > chartHeight) {
      top = chartHeight - tooltipHeight - 10;
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: tooltipWidth),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('第 ${detail.period} 期', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(formatDate(detail.date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const Divider(height: 8),
              if (widget.showAssets) ...[
                _buildTooltipRow('總資產', formatMoneyShort(detail.totalAssets), Colors.blue),
                _buildTooltipRow('累計投入', formatMoneyShort(detail.totalInvested), Colors.grey),
                _buildTooltipRow('累計利息', formatMoneyShort(detail.accumulatedInterest), Colors.green),
              ] else ...[
                _buildTooltipRow('本期利息', formatMoneyShort(detail.periodInterest), Colors.green),
              ],
              if (detail.specialDepositCount > 0)
                _buildTooltipRow(
                  '特別存款',
                  '${formatMoneyShort(detail.specialDeposit)} (${detail.specialDepositCount})',
                  Colors.orange,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTooltipRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String formatMoneyShort(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

class LineChartPainter extends CustomPainter {
  final List<PeriodDetail> periods;
  final double maxValue;
  final bool showAssets;
  final int? hoveredIndex;

  LineChartPainter({required this.periods, required this.maxValue, required this.showAssets, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // 繪製座標軸
    final axisPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(Offset(padding, padding), Offset(padding, size.height - padding), axisPaint);

    if (periods.isEmpty) return;

    final stepX = chartWidth / (periods.length - 1);

    if (showAssets) {
      // 繪製總資產線
      paint.color = Colors.blue;
      final assetsPath = Path();
      for (int i = 0; i < periods.length; i++) {
        final x = padding + i * stepX;
        final y = size.height - padding - (periods[i].totalAssets / maxValue) * chartHeight;
        if (i == 0) {
          assetsPath.moveTo(x, y);
        } else {
          assetsPath.lineTo(x, y);
        }
      }
      canvas.drawPath(assetsPath, paint);

      // 繪製累計投入線
      paint.color = Colors.grey;
      paint.strokeWidth = 2;
      final investedPath = Path();
      for (int i = 0; i < periods.length; i++) {
        final x = padding + i * stepX;
        final y = size.height - padding - (periods[i].totalInvested / maxValue) * chartHeight;
        if (i == 0) {
          investedPath.moveTo(x, y);
        } else {
          investedPath.lineTo(x, y);
        }
      }
      canvas.drawPath(investedPath, paint);

      // 繪製 hover 點
      if (hoveredIndex != null) {
        final x = padding + hoveredIndex! * stepX;
        final yAssets = size.height - padding - (periods[hoveredIndex!].totalAssets / maxValue) * chartHeight;
        final yInvested = size.height - padding - (periods[hoveredIndex!].totalInvested / maxValue) * chartHeight;

        final pointPaint = Paint()..style = PaintingStyle.fill;

        pointPaint.color = Colors.blue;
        canvas.drawCircle(Offset(x, yAssets), 5, pointPaint);

        pointPaint.color = Colors.grey;
        canvas.drawCircle(Offset(x, yInvested), 5, pointPaint);
      }
    } else {
      // 繪製每期利息線
      paint.color = Colors.green;
      final interestPath = Path();
      for (int i = 0; i < periods.length; i++) {
        final x = padding + i * stepX;
        final y = size.height - padding - (periods[i].periodInterest / maxValue) * chartHeight;
        if (i == 0) {
          interestPath.moveTo(x, y);
        } else {
          interestPath.lineTo(x, y);
        }
      }
      canvas.drawPath(interestPath, paint);

      // 繪製 hover 點
      if (hoveredIndex != null) {
        final x = padding + hoveredIndex! * stepX;
        final y = size.height - padding - (periods[hoveredIndex!].periodInterest / maxValue) * chartHeight;

        final pointPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.green;
        canvas.drawCircle(Offset(x, y), 5, pointPaint);
      }
    }

    // 繪製 Y 軸標籤
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 5; i++) {
      final value = (maxValue / 5) * i;
      final y = size.height - padding - (chartHeight / 5) * i;

      textPainter.text = TextSpan(
        text: '${(value / 1000).toStringAsFixed(0)}K',
        style: const TextStyle(color: Colors.black, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // 繪製 X 軸標籤（顯示部分期數）
    final step = max(1, (periods.length / 10).ceil());
    for (int i = 0; i < periods.length; i += step) {
      final x = padding + i * stepX;
      textPainter.text = TextSpan(
        text: '${periods[i].period}',
        style: const TextStyle(color: Colors.black, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - padding + 5));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex;
  }
}
