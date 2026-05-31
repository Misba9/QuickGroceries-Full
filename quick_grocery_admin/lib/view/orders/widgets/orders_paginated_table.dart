import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_row_actions.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_data_table_source.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_mobile_card.dart';

/// Horizontally scrollable [DataTable] with client-side paging — safe inside scroll views.
class OrdersPaginatedTable extends StatefulWidget {
  const OrdersPaginatedTable({
    super.key,
    required this.orders,
    required this.onView,
    this.rowsPerPage = 10,
    this.availableRowsPerPage = const [10, 15, 25, 50],
    this.minTableWidth = 1320,
  });

  final List<OrderModel> orders;
  final OrderDrawerCallback onView;
  final int rowsPerPage;
  final List<int> availableRowsPerPage;
  final double minTableWidth;

  @override
  State<OrdersPaginatedTable> createState() => _OrdersPaginatedTableState();
}

class _OrdersPaginatedTableState extends State<OrdersPaginatedTable> {
  late int _rowsPerPage;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPage;
  }

  @override
  void didUpdateWidget(OrdersPaginatedTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rowsPerPage != oldWidget.rowsPerPage) {
      _rowsPerPage = widget.rowsPerPage;
    }
    final pageCount = _pageCount;
    if (_pageIndex >= pageCount && pageCount > 0) {
      _pageIndex = pageCount - 1;
    }
  }

  int get _pageCount {
    if (widget.orders.isEmpty) return 1;
    return (widget.orders.length / _rowsPerPage).ceil();
  }

  List<OrderModel> get _pageSlice {
    final start = _pageIndex * _rowsPerPage;
    if (start >= widget.orders.length) return const [];
    final end = (start + _rowsPerPage).clamp(0, widget.orders.length);
    return widget.orders.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, c) {
        if (adminIsMobileWidth(c.maxWidth)) {
          return _MobilePagedList(
            orders: widget.orders,
            onView: widget.onView,
            rowsPerPage: _rowsPerPage,
          );
        }
        return _OrdersDataTableCard(
          orders: _pageSlice,
          allOrders: widget.orders,
          onView: widget.onView,
          minTableWidth: widget.minTableWidth,
          pageIndex: _pageIndex,
          pageCount: _pageCount,
          rowsPerPage: _rowsPerPage,
          availableRowsPerPage: widget.availableRowsPerPage,
          onPageChanged: (i) => setState(() => _pageIndex = i),
          onRowsPerPageChanged: (v) {
            if (v == null) return;
            setState(() {
              _rowsPerPage = v;
              _pageIndex = 0;
            });
          },
        );
      },
    );
  }
}

const _kOrderTableColumns = [
  DataColumn(label: Text('Order ID')),
  DataColumn(label: Text('Customer')),
  DataColumn(label: Text('Vendor')),
  DataColumn(label: Text('Rider')),
  DataColumn(label: Text('Payment')),
  DataColumn(label: Text('Delivery Slot')),
  DataColumn(label: Text('Amount')),
  DataColumn(label: Text('Status')),
  DataColumn(label: Text('ETA')),
  DataColumn(label: Text('Actions')),
];

class _OrdersDataTableCard extends StatelessWidget {
  const _OrdersDataTableCard({
    required this.orders,
    required this.allOrders,
    required this.onView,
    required this.minTableWidth,
    required this.pageIndex,
    required this.pageCount,
    required this.rowsPerPage,
    required this.availableRowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  final List<OrderModel> orders;
  final List<OrderModel> allOrders;
  final OrderDrawerCallback onView;
  final double minTableWidth;
  final int pageIndex;
  final int pageCount;
  final int rowsPerPage;
  final List<int> availableRowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onRowsPerPageChanged;

  @override
  Widget build(BuildContext context) {
    final globalStart = pageIndex * rowsPerPage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minTableWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8F9FB),
                ),
                headingRowHeight: 48,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 56,
                columnSpacing: 24,
                horizontalMargin: 16,
                columns: _kOrderTableColumns,
                rows: [
                  for (var i = 0; i < orders.length; i++)
                    OrdersDataTableSource.buildDataRow(
                      order: orders[i],
                      index: globalStart + i,
                      onView: onView,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TablePager(
            pageIndex: pageIndex,
            pageCount: pageCount,
            totalRows: allOrders.length,
            rowsPerPage: rowsPerPage,
            availableRowsPerPage: availableRowsPerPage,
            onPageChanged: onPageChanged,
            onRowsPerPageChanged: onRowsPerPageChanged,
          ),
        ],
      ),
    );
  }
}

class _TablePager extends StatelessWidget {
  const _TablePager({
    required this.pageIndex,
    required this.pageCount,
    required this.totalRows,
    required this.rowsPerPage,
    required this.availableRowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  final int pageIndex;
  final int pageCount;
  final int totalRows;
  final int rowsPerPage;
  final List<int> availableRowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onRowsPerPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = pageIndex * rowsPerPage + 1;
    final end = ((pageIndex + 1) * rowsPerPage).clamp(0, totalRows);
    final uniqueRowsPerPage = _uniqueRowsPerPageOptions(availableRowsPerPage);
    final validRowsPerPage = uniqueRowsPerPage.contains(rowsPerPage)
        ? rowsPerPage
        : null;

    debugPrint('Dropdown items count: ${uniqueRowsPerPage.length}');
    debugPrint('Selected value: $rowsPerPage');

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Rows per page:',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        if (uniqueRowsPerPage.isNotEmpty)
          DropdownButton<int>(
            value: validRowsPerPage,
            hint: Text('$rowsPerPage'),
            isExpanded: false,
            items: uniqueRowsPerPage
                .map((n) => DropdownMenuItem<int>(value: n, child: Text('$n')))
                .toList(growable: false),
            onChanged: onRowsPerPageChanged,
          ),
        Text(
          '$start–$end of $totalRows',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        IconButton(
          tooltip: 'First page',
          onPressed: pageIndex > 0 ? () => onPageChanged(0) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Previous page',
          onPressed: pageIndex > 0 ? () => onPageChanged(pageIndex - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Page ${pageIndex + 1} of $pageCount'),
        IconButton(
          tooltip: 'Next page',
          onPressed: pageIndex < pageCount - 1
              ? () => onPageChanged(pageIndex + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'Last page',
          onPressed: pageIndex < pageCount - 1
              ? () => onPageChanged(pageCount - 1)
              : null,
          icon: const Icon(Icons.last_page),
        ),
      ],
    );
  }

  static List<int> _uniqueRowsPerPageOptions(List<int> values) {
    return values.fold<List<int>>([], (list, value) {
      if (value > 0 && !list.contains(value)) {
        list.add(value);
      }
      return list;
    });
  }
}

class _MobilePagedList extends StatefulWidget {
  const _MobilePagedList({
    required this.orders,
    required this.onView,
    required this.rowsPerPage,
  });

  final List<OrderModel> orders;
  final OrderDrawerCallback onView;
  final int rowsPerPage;

  @override
  State<_MobilePagedList> createState() => _MobilePagedListState();
}

class _MobilePagedListState extends State<_MobilePagedList> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.orders.length;
    if (total == 0) return const SizedBox.shrink();

    final pageCount = (total / widget.rowsPerPage).ceil();
    final start = _page * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, total);
    final slice = widget.orders.sublist(start, end);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < slice.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OrdersMobileCard(
              order: slice[i],
              index: start + i,
              onView: widget.onView,
            ),
          ),
        if (total > widget.rowsPerPage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${_page + 1} of $pageCount'),
                IconButton(
                  onPressed: _page < pageCount - 1
                      ? () => setState(() => _page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
