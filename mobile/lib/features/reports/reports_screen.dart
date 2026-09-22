import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/app_state_service.dart';
import '../../data/repositories/reports_repository.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/chart_common.dart';
import 'widgets/comparison_bar_chart.dart';
import 'widgets/report_section_card.dart';
import 'widgets/trend_line_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _CategoryColors {
  static final List<Color> palette = [
    AppTheme.neonLime,
    const Color(0xFF389BF2),
    AppTheme.statusOverdue,
    const Color(0xFFF97316),
    const Color(0xFFA855F7),
    AppTheme.statusDueSoon,
    const Color(0xFF25D366),
    const Color(0xFFEC4899),
    const Color(0xFF64748B),
  ];
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportsRepo = ReportsRepository();

  bool _isLoading = true;
  ReportGranularity _granularity = ReportGranularity.monthly;
  int _periods = 12;
  String _breakdownFilter = 'This Month';

  List<PeriodValue> _income = [];
  List<PeriodValue> _expenses = [];
  List<PeriodValue> _newMembers = [];
  List<PeriodValue> _cumulativeMembers = [];
  Map<String, double> _categoryBreakdown = {};
  Map<String, double> _paymentMethodBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) _loadData(showSpinner: false);
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoading = true);

    final income = await _reportsRepo.getIncomeSeries(granularity: _granularity, periods: _periods);
    final expenses = await _reportsRepo.getExpenseSeries(granularity: _granularity, periods: _periods);
    final newMembers = await _reportsRepo.getNewMemberSeries(granularity: _granularity, periods: _periods);
    final cumulative = await _reportsRepo.getCumulativeMemberSeries(granularity: _granularity, periods: _periods);

    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    if (_breakdownFilter == 'This Month') {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 1);
    } else if (_breakdownFilter == 'This Year') {
      from = DateTime(now.year, 1, 1);
      to = DateTime(now.year + 1, 1, 1);
    }

    final categoryBreakdown = await _reportsRepo.getExpenseCategoryBreakdown(from: from, to: to);
    final paymentMethodBreakdown = await _reportsRepo.getPaymentMethodBreakdown(from: from, to: to);

    if (mounted) {
      setState(() {
        _income = income;
        _expenses = expenses;
        _newMembers = newMembers;
        _cumulativeMembers = cumulative;
        _categoryBreakdown = categoryBreakdown;
        _paymentMethodBreakdown = paymentMethodBreakdown;
        _isLoading = false;
      });
    }
  }

  void _setGranularity(ReportGranularity g) {
    if (g == _granularity) return;
    setState(() {
      _granularity = g;
      _periods = g == ReportGranularity.monthly ? 12 : 5;
    });
    _loadData();
  }

  void _setPeriods(int p) {
    if (p == _periods) return;
    setState(() => _periods = p);
    _loadData();
  }

  void _setBreakdownFilter(String f) {
    if (f == _breakdownFilter) return;
    setState(() => _breakdownFilter = f);
    _loadData();
  }

  String _formatLabel(DateTime d) {
    return _granularity == ReportGranularity.monthly ? DateFormat('MMM yy').format(d) : DateFormat('yyyy').format(d);
  }

  double _sum(List<PeriodValue> series) => series.fold(0.0, (s, p) => s + p.value);

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final labels = _income.map((p) => _formatLabel(p.period)).toList();
    final incomeValues = _income.map((p) => p.value).toList();
    final expenseValues = _expenses.map((p) => p.value).toList();
    final netProfitValues = List.generate(incomeValues.length, (i) => incomeValues[i] - expenseValues[i]);
    final newMemberValues = _newMembers.map((p) => p.value).toList();
    final cumulativeValues = _cumulativeMembers.map((p) => p.value).toList();

    final totalIncome = _sum(_income);
    final totalExpenses = _sum(_expenses);
    final netProfit = totalIncome - totalExpenses;
    final totalNewMembers = _sum(_newMembers).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('REPORTS & ANALYTICS'),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : RefreshIndicator(
                color: AppTheme.neonLime,
                onRefresh: _loadData,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, safeBottom + 24),
                  children: [
                    _buildGranularityToggle(),
                    const SizedBox(height: 12),
                    _buildPeriodWindowChips(),
                    const SizedBox(height: 20),

                    _buildSummaryGrid(totalIncome, totalExpenses, netProfit, totalNewMembers),
                    const SizedBox(height: 20),

                    ReportSectionCard(
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFF389BF2),
                      title: 'Income vs Expenses',
                      subtitle: _granularity == ReportGranularity.monthly ? 'Last $_periods months' : 'Last $_periods years',
                      child: ComparisonBarChart(
                        labels: labels,
                        seriesA: incomeValues,
                        seriesB: expenseValues,
                        colorA: AppTheme.statusActive,
                        colorB: AppTheme.statusOverdue,
                        labelA: 'Income',
                        labelB: 'Expenses',
                      ),
                    ),
                    const SizedBox(height: 16),

                    ReportSectionCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppTheme.neonLime,
                      title: 'Net Profit Trend',
                      subtitle: 'Income minus expenses over time',
                      child: TrendLineChart(
                        labels: labels,
                        values: netProfitValues,
                        color: netProfit >= 0 ? AppTheme.neonLime : AppTheme.statusOverdue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ReportSectionCard(
                      icon: Icons.person_add_alt_1_rounded,
                      iconColor: const Color(0xFFA855F7),
                      title: 'New Member Sign-ups',
                      subtitle: 'Onboarding growth per period',
                      child: TrendLineChart(
                        labels: labels,
                        values: newMemberValues,
                        color: const Color(0xFFA855F7),
                        isCurrency: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ReportSectionCard(
                      icon: Icons.groups_rounded,
                      iconColor: const Color(0xFFF97316),
                      title: 'Total Active Members Growth',
                      subtitle: 'Cumulative member count over time',
                      child: TrendLineChart(
                        labels: labels,
                        values: cumulativeValues,
                        color: const Color(0xFFF97316),
                        isCurrency: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ReportSectionCard(
                      icon: Icons.pie_chart_rounded,
                      iconColor: AppTheme.statusOverdue,
                      title: 'Expense Breakdown',
                      subtitle: 'By category',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBreakdownFilterChips(),
                          const SizedBox(height: 16),
                          CategoryPieChart(data: _categoryBreakdown, palette: _CategoryColors.palette),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    ReportSectionCard(
                      icon: Icons.payments_rounded,
                      iconColor: const Color(0xFF25D366),
                      title: 'Income Breakdown',
                      subtitle: 'By payment method',
                      child: CategoryPieChart(data: _paymentMethodBreakdown, palette: _CategoryColors.palette),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildGranularityToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _segmentButton('Monthly', _granularity == ReportGranularity.monthly, () => _setGranularity(ReportGranularity.monthly))),
          Expanded(child: _segmentButton('Yearly', _granularity == ReportGranularity.yearly, () => _setGranularity(ReportGranularity.yearly))),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.neonLime : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppTheme.darkBackground : AppTheme.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodWindowChips() {
    final options = _granularity == ReportGranularity.monthly ? [6, 12] : [3, 5];
    final suffix = _granularity == ReportGranularity.monthly ? 'M' : 'Y';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((p) {
          final selected = _periods == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text('Last $p$suffix'),
              selectedColor: AppTheme.neonLime,
              backgroundColor: AppTheme.darkSurface,
              labelStyle: TextStyle(
                color: selected ? AppTheme.darkBackground : AppTheme.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              onSelected: (_) => _setPeriods(p),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBreakdownFilterChips() {
    final options = ['This Month', 'This Year', 'All Time'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((f) {
          final selected = _breakdownFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text(f),
              selectedColor: AppTheme.neonLime,
              backgroundColor: AppTheme.darkBackground,
              labelStyle: TextStyle(
                color: selected ? AppTheme.darkBackground : AppTheme.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
              onSelected: (_) => _setBreakdownFilter(f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryGrid(double income, double expenses, double netProfit, int newMembers) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard('TOTAL INCOME', '₹${formatCompactAmount(income)}', AppTheme.statusActive, Icons.arrow_downward_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('TOTAL EXPENSES', '₹${formatCompactAmount(expenses)}', AppTheme.statusOverdue, Icons.arrow_upward_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'NET PROFIT',
                '₹${formatCompactAmount(netProfit)}',
                netProfit >= 0 ? AppTheme.neonLime : AppTheme.statusOverdue,
                netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('NEW MEMBERS', '$newMembers', const Color(0xFFA855F7), Icons.person_add_alt_1_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color accent, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
