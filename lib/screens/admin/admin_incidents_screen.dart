import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'package:intl/intl.dart';

/// Admin incident log with filters and pagination.
class AdminIncidentsScreen extends StatefulWidget {
  const AdminIncidentsScreen({super.key});

  @override
  State<AdminIncidentsScreen> createState() => _AdminIncidentsScreenState();
}

class _AdminIncidentsScreenState extends State<AdminIncidentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _searchQuery = '';
  int _page = 0;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Incident Log', style: AppTextStyles.clashDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _exportCSV,
                  icon: const Icon(Icons.download, size: 16, color: AppColors.textMuted),
                  label: Text('Export CSV', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.crisisRed,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.crisisRed,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTextStyles.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyles.dmSans(fontSize: 14),
              tabs: const [
                Tab(text: 'Recent Incidents'),
                Tab(text: 'All Incidents'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecentIncidents(),
                  _buildAllIncidents(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the last 10 incidents from the past 48 hours.
  Widget _buildRecentIncidents() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    return StreamBuilder<List<IncidentModel>>(
      stream: IncidentService.streamAllIncidents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.crisisRed));
        }
        final recent = (snapshot.data ?? [])
            .where((i) => i.createdAt.isAfter(cutoff))
            .take(10)
            .toList();

        if (recent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                Text('No incidents in the last 48 hours',
                    style: AppTextStyles.dmSans(fontSize: 16, color: AppColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: recent.length,
          itemBuilder: (context, index) {
            final i = recent[index];
            return InkWell(
              onTap: () => _showDetail(context, i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: i.status == 'active' || i.status == 'escalated'
                        ? AppColors.crisisRed.withValues(alpha: 0.4)
                        : AppColors.borderGhost,
                  ),
                ),
                child: Row(
                  children: [
                    CrisisTypeIcon(type: i.crisisType, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i.crisisType.toUpperCase()} — Room ${i.roomNumber}',
                            style: AppTextStyles.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Guest: ${i.guestName}  •  ${DateFormat('MMM dd, HH:mm').format(i.createdAt)}',
                            style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    SeverityBadge(level: i.severity),
                    const SizedBox(width: 8),
                    StatusIndicator(status: i.status),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllIncidents() {
    return Column(
      children: [
        // Filter bar
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 200,
              height: 40,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search room, desc...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            _buildDropdown('Type', _typeFilter, ['all', 'fire', 'medical', 'security', 'other'], (v) => setState(() => _typeFilter = v)),
            _buildDropdown('Status', _statusFilter, ['all', 'active', 'accepted', 'responding', 'escalated', 'resolved'], (v) => setState(() => _statusFilter = v)),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: StreamBuilder<List<IncidentModel>>(
            stream: IncidentService.streamAllIncidents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.crisisRed));
              }

              var incidents = snapshot.data ?? [];
              incidents = _applyFilters(incidents);
              final totalPages = (incidents.length / _pageSize).ceil();
              final pageIncidents = incidents.skip(_page * _pageSize).take(_pageSize).toList();

              return Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.card),
                        topRight: Radius.circular(AppRadius.card),
                      ),
                      border: Border.all(color: AppColors.borderGhost),
                    ),
                    child: Row(
                      children: [
                        _headerCell('ID', 80),
                        _headerCell('Room', 60),
                        _headerCell('Type', 80),
                        _headerCell('Sev', 60),
                        _headerCell('Guest', 100),
                        _headerCell('Staff', 100),
                        _headerCell('Time', 90),
                        _headerCell('Status', 80),
                      ],
                    ),
                  ),
                  // Data rows
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderGhost),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppRadius.card),
                          bottomRight: Radius.circular(AppRadius.card),
                        ),
                      ),
                      child: pageIncidents.isEmpty
                          ? Center(child: Text('No incidents found', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
                          : ListView.builder(
                              itemCount: pageIncidents.length,
                              itemBuilder: (context, index) {
                                final i = pageIncidents[index];
                                final isEven = index % 2 == 0;
                                return InkWell(
                                  onTap: () => _showDetail(context, i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    color: isEven ? AppColors.surface : AppColors.surfaceContainer,
                                    child: Row(
                                      children: [
                                        SizedBox(width: 80, child: Text(i.id.length > 8 ? i.id.substring(0, 8) : i.id, style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted))),
                                        SizedBox(width: 60, child: Text(i.roomNumber, style: AppTextStyles.jetBrainsMono(fontSize: 12, color: AppColors.textPrimary))),
                                        SizedBox(width: 80, child: Row(children: [CrisisTypeIcon(type: i.crisisType, size: 14), const SizedBox(width: 4), Text(i.crisisType, style: AppTextStyles.dmSans(fontSize: 11, color: AppColors.textMuted))])),
                                        SizedBox(width: 60, child: SeverityBadge(level: i.severity)),
                                        SizedBox(width: 100, child: Text(i.guestName, style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                                        SizedBox(width: 100, child: Text(i.acceptedBy?['staffName'] ?? 'Unassigned', style: AppTextStyles.dmSans(fontSize: 12, color: i.acceptedBy != null ? AppColors.textPrimary : AppColors.crisisRed))),
                                        SizedBox(width: 90, child: Text(DateFormat('MM/dd HH:mm').format(i.createdAt), style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted))),
                                        SizedBox(width: 80, child: StatusIndicator(status: i.status)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  // Pagination
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _page > 0 ? () => setState(() => _page--) : null,
                        icon: Icon(Icons.chevron_left, color: _page > 0 ? AppColors.textPrimary : AppColors.textMuted),
                      ),
                      Text('Page ${_page + 1} of ${totalPages == 0 ? 1 : totalPages}', style: AppTextStyles.jetBrainsMono(fontSize: 12, color: AppColors.textMuted)),
                      IconButton(
                        onPressed: _page < totalPages - 1 ? () => setState(() => _page++) : null,
                        icon: Icon(Icons.chevron_right, color: _page < totalPages - 1 ? AppColors.textPrimary : AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _headerCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(label, style: AppTextStyles.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.borderGhost),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surface,
          style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textPrimary),
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(v == 'all' ? 'All ${label}s' : v))).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  List<IncidentModel> _applyFilters(List<IncidentModel> list) {
    var result = list;
    if (_typeFilter != 'all') result = result.where((i) => i.crisisType == _typeFilter).toList();
    if (_statusFilter != 'all') result = result.where((i) => i.status == _statusFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) => i.roomNumber.toLowerCase().contains(q) || (i.description ?? '').toLowerCase().contains(q) || i.guestName.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  void _exportCSV() {
    // Browser CSV download placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV export feature — configure dart:html for production'), backgroundColor: AppColors.signalTeal),
    );
  }

  void _showDetail(BuildContext context, IncidentModel i) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.modal)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Incident ${i.id}', style: AppTextStyles.clashDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow('Room', i.roomNumber),
                _detailRow('Type', i.crisisType.toUpperCase()),
                _detailRow('Severity', 'SEV ${i.severity}'),
                _detailRow('Status', i.status),
                _detailRow('Guest', '${i.guestName} (${i.guestEmail})'),
                _detailRow('Staff', i.acceptedBy?['staffName'] ?? 'Unassigned'),
                _detailRow('Created', DateFormat('MMM dd, yyyy – hh:mm a').format(i.createdAt)),
                if (i.resolvedAt != null) _detailRow('Resolved', DateFormat('MMM dd, yyyy – hh:mm a').format(i.resolvedAt!)),
                if (i.description != null && i.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Description:', style: AppTextStyles.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                  Text(i.description!, style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textPrimary)),
                ],
                if (i.postIncidentReport != null) ...[
                  const SizedBox(height: 16),
                  Text('AI Report:', style: AppTextStyles.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(i.postIncidentReport!, style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
