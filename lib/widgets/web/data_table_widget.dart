import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DataTableWidget extends StatefulWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final Function(Map<String, dynamic>)? onRowTap;
  final Function(Map<String, dynamic>)? onEdit;
  final Function(Map<String, dynamic>)? onDelete;
  final Function(String)? onSearch;
  final Function(int, bool)? onSort;
  final bool showActions;
  final bool showSearch;
  final String searchHint;

  const DataTableWidget({
    Key? key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.onEdit,
    this.onDelete,
    this.onSearch,
    this.onSort,
    this.showActions = true,
    this.showSearch = true,
    this.searchHint = 'Search...',
  }) : super(key: key);

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  List<Map<String, dynamic>> _filteredRows = [];

  @override
  void initState() {
    super.initState();
    _filteredRows = List.from(widget.rows);
  }

  @override
  void didUpdateWidget(DataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _filteredRows = List.from(widget.rows);
      _applySearch();
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredRows = List.from(widget.rows);
    } else {
      _filteredRows = widget.rows.where((row) {
        return row.values.any((value) =>
            value.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    setState(() {});
  }

  void _sortRows(int columnIndex) {
    if (widget.onSort != null) {
      widget.onSort!(columnIndex, _sortAscending);
      return;
    }

    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }

      _filteredRows.sort((a, b) {
        final aValue = a[widget.columns[columnIndex]];
        final bValue = b[widget.columns[columnIndex]];

        if (aValue is num && bValue is num) {
          return _sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        }

        final comparison = aValue.toString().compareTo(bValue.toString());
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.showSearch) _buildSearchBar(),
          if (widget.showSearch) const Divider(height: 1),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columnSpacing: 20,
                horizontalMargin: 20,
                headingRowColor:
                MaterialStateProperty.all(Colors.grey.shade50),
                dataRowColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.red.shade50;
                  }
                  return null;
                }),
                columns: widget.columns.map((column) {
                  return DataColumn(
                    label: Text(
                      column,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    onSort: (columnIndex, ascending) {
                      _sortRows(columnIndex);
                    },
                  );
                }).toList()
                  ..addAll([
                    if (widget.showActions)
                      const DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ]),
                rows: _filteredRows.map((row) {
                  return DataRow(
                    onSelectChanged: widget.onRowTap != null
                        ? (_) => widget.onRowTap!(row)
                        : null,
                    cells: widget.columns.map((column) {
                      return DataCell(
                        _buildCellContent(row[column]),
                      );
                    }).toList()
                      ..addAll([
                        if (widget.showActions)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onEdit != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 18, color: Colors.blue),
                                    onPressed: () => widget.onEdit!(row),
                                    tooltip: 'Edit',
                                  ),
                                if (widget.onDelete != null)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    onPressed: () => _showDeleteDialog(row),
                                    tooltip: 'Delete',
                                  ),
                              ],
                            ),
                          ),
                      ]),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_filteredRows.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _applySearch();
                if (widget.onSearch != null) {
                  widget.onSearch!(value);
                }
              },
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filteredRows = List.from(widget.rows);
                });
              },
              child: const Text('Clear'),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total: ${_filteredRows.length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellContent(dynamic value) {
    if (value == null) {
      return const Text('-');
    }

    // Handle status badges
    if (value is String &&
        (value.toLowerCase() == 'pending' ||
            value.toLowerCase() == 'approved' ||
            value.toLowerCase() == 'rejected' ||
            value.toLowerCase() == 'completed')) {
      return _buildStatusBadge(value);
    }

    // Handle dates
    if (value is DateTime) {
      return Text(
        '${value.day}/${value.month}/${value.year}',
        style: GoogleFonts.poppins(fontSize: 13),
      );
    }

    return Text(
      value.toString(),
      style: GoogleFonts.poppins(fontSize: 13),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'active':
        color = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'pending':
      case 'waiting':
        color = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        color = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No data found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDelete!(row);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}