import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/services/analytics_service.dart';
import 'package:crisissync/services/gemini_service.dart';
import 'package:crisissync/widgets/gemini_tag.dart';
import 'package:crisissync/widgets/loading_skeleton.dart';
import 'package:fl_chart/fl_chart.dart';

/// Admin analytics screen with charts.
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _monthlyReport;
  bool _loadingReport = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    try {
      _data = await AnalyticsService.getAnalyticsRange(start, end);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _generateReport() async {
    setState(() => _loadingReport = true);
    try {
      final monthData = {
        'days': _data.length,
        'totalIncidents': _data.fold<int>(0, (sum, d) => sum + ((d['totalIncidents'] ?? 0) as int)),
        'totalResolved': _data.fold<int>(0, (sum, d) => sum + ((d['resolvedIncidents'] ?? 0) as int)),
        'avgResponseTime': _data.isEmpty ? 0 : _data.fold<double>(0, (sum, d) => sum + ((d['avgResponseTime'] as num?)?.toDouble() ?? 0)) / _data.length,
      };
      _monthlyReport = await GeminiService.generateMonthlyReport(monthData);
    } catch (_) {
      _monthlyReport = 'Failed to generate report.';
    }
    if (mounted) setState(() => _loadingReport = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.geminiPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics', style: AppTextStyles.clashDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Last 30 days', style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted)),
                  const SizedBox(height: 24),

                  // Charts grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      if (isWide) {
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildDailyVolumeChart()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildIncidentsByFloor()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildResponseTimeChart()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSeverityDistribution()),
                              ],
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildDailyVolumeChart(),
                          const SizedBox(height: 16),
                          _buildIncidentsByFloor(),
                          const SizedBox(height: 16),
                          _buildResponseTimeChart(),
                          const SizedBox(height: 16),
                          _buildSeverityDistribution(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Monthly report
                  _buildMonthlyReport(),
                ],
              ),
            ),
    );
  }

  Widget _chartContainer(String title, Widget chart, {double height = 260}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderGhost),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildDailyVolumeChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _data.length; i++) {
      spots.add(FlSpot(i.toDouble(), ((_data[i]['totalIncidents'] ?? 0) as int).toDouble()));
    }

    return _chartContainer(
      'Daily Incident Volume',
      spots.isEmpty
          ? Center(child: Text('No data', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF242424), strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: AppTextStyles.dmSans(fontSize: 10, color: AppColors.textMuted)))),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.crisisRed,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.crisisRed.withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildIncidentsByFloor() {
    final floorData = <String, int>{};
    for (final day in _data) {
      final byFloor = day['incidentsByFloor'] as Map<String, dynamic>? ?? {};
      byFloor.forEach((k, v) {
        floorData[k] = (floorData[k] ?? 0) + ((v as num?)?.toInt() ?? 0);
      });
    }

    return _chartContainer(
      'Incidents by Floor',
      floorData.isEmpty
          ? Center(child: Text('No data', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
          : BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF242424), strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: AppTextStyles.dmSans(fontSize: 10, color: AppColors.textMuted)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx >= 0 && idx < floorData.keys.length) {
                      return Padding(padding: const EdgeInsets.only(top: 4), child: Text(floorData.keys.elementAt(idx), style: AppTextStyles.dmSans(fontSize: 9, color: AppColors.textMuted)));
                    }
                    return const SizedBox();
                  })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: floorData.entries.toList().asMap().entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(toY: e.value.value.toDouble(), color: AppColors.geminiPurple, width: 16, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildResponseTimeChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _data.length; i++) {
      spots.add(FlSpot(i.toDouble(), ((_data[i]['avgResponseTime'] as num?)?.toDouble() ?? 0)));
    }

    return _chartContainer(
      'Response Time Trend (min)',
      spots.isEmpty
          ? Center(child: Text('No data', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
          : LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF242424), strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}m', style: AppTextStyles.dmSans(fontSize: 10, color: AppColors.textMuted)))),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(spots: spots, isCurved: true, color: AppColors.signalTeal, barWidth: 2, dotData: const FlDotData(show: false)),
                ],
              ),
            ),
    );
  }

  Widget _buildSeverityDistribution() {
    final sevData = <String, int>{};
    for (final day in _data) {
      final bySev = day['incidentsBySeverity'] as Map<String, dynamic>? ?? {};
      bySev.forEach((k, v) {
        sevData[k] = (sevData[k] ?? 0) + ((v as num?)?.toInt() ?? 0);
      });
    }

    final colors = {'1': AppColors.signalTeal, '2': const Color(0xFF00BFA5), '3': AppColors.amberAlert, '4': const Color(0xFFE64A19), '5': AppColors.crisisRed};

    return _chartContainer(
      'Severity Distribution',
      sevData.isEmpty
          ? Center(child: Text('No data', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
          : PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sections: sevData.entries.map((e) => PieChartSectionData(
                  value: e.value.toDouble(),
                  color: colors[e.key] ?? AppColors.textMuted,
                  radius: 35,
                  title: 'S${e.key}',
                  titleStyle: AppTextStyles.jetBrainsMono(fontSize: 10, color: Colors.white),
                )).toList(),
              ),
            ),
    );
  }

  Widget _buildMonthlyReport() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderGhost),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Gemini Monthly Report', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              const GeminiTag(),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loadingReport ? null : _generateReport,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.geminiPurple),
                child: Text(_loadingReport ? 'Generating...' : 'Generate Monthly Report', style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingReport)
            const LoadingSkeleton(rows: 4, height: 16)
          else if (_monthlyReport != null)
            Text(_monthlyReport!, style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted))
          else
            Text('Click "Generate Monthly Report" to create an AI-powered analysis.', style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
