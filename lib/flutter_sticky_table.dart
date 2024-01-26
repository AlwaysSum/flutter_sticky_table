import 'package:flutter/material.dart';
import 'sync_scroller_controller.dart';

typedef StickyTableRowBuilder<T> = TableRow Function(
  BuildContext context,
  T item,
  int row,
  List<StickyTableColumn<T>> columnData,
);

typedef StickyTableCellFunction<T, R> = R Function(
  BuildContext context,
  StickyTableColumn<T> title,
  T item,
  int row,
  int column,
);

/// 每一列的构建方式
class StickyTableColumn<T> {
  final String title;
  final bool? sort;
  final bool showSort;
  final Alignment alignment;
  final TableColumnWidth? columnWidth;
  final bool fixedStart;
  final bool fixedEnd;

  StickyTableColumn(
    this.title, {
    this.onTitleClick,
    this.onCellClick,
    this.sort,
    this.showSort = false,
    this.alignment = Alignment.center,
    this.renderTitle,
    this.renderCell,
    this.columnWidth,
    this.fixedStart = false,
    this.fixedEnd = false,
  });

  final Widget Function(
      BuildContext context, StickyTableColumn<T> title)? renderTitle;
  final StickyTableCellFunction<T, Widget>? renderCell;

  final void Function(BuildContext context, StickyTableColumn<T> title)?
      onTitleClick;

  final StickyTableCellFunction<T, void>? onCellClick;
}

/// 表格组件
class StickyTable<T> extends StatefulWidget {
  const StickyTable({
    super.key,
    required this.data,
    required this.columns,
    this.titleHeight = 58,
    this.cellHeight = 58,
    this.cellDecoration,
    this.defaultColumnWidth = const FixedColumnWidth(120),
    this.cellPadding,
    this.titleDecoration,
    this.rowDecoration,
    this.tableBorder,
    this.showZebraCrossing = true,
    this.zebraCrossingColor = (Colors.white, const Color(0xfff5f5f5)),
    this.zebraCrossingRadius = const Radius.circular(12),
  });

  ///默认列宽度
  final TableColumnWidth defaultColumnWidth;

  ///列配置
  final List<StickyTableColumn<T>> columns;

  /// 单元格内边距
  final EdgeInsets? cellPadding;

  ///标题描述信息
  final Decoration? titleDecoration;
  final Decoration? rowDecoration;
  final TableBorder? tableBorder;

  ///数据集合
  final List<T> data;

  ///标题高度
  final double titleHeight;

  ///单元格高度
  final double cellHeight;

  ///单元格描述信息
  final StickyTableCellFunction<T, Decoration>? cellDecoration;

  ///显示斑马线
  final bool showZebraCrossing;

  ///斑马线弧度
  final Radius zebraCrossingRadius;

  ///斑马线颜色
  final (Color, Color) zebraCrossingColor;

  @override
  State<StickyTable<T>> createState() => _StickyTableState<T>();
}

class _StickyTableState<T> extends State<StickyTable<T>> {
  final scrollControl = SyncScrollController();

  @override
  void dispose() {
    super.dispose();
    scrollControl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fixColumns = <StickyTableColumn<T>>[];
    final columns = <StickyTableColumn<T>>[];
    final fixEndColumns = <StickyTableColumn<T>>[];
    for (var element in widget.columns) {
      if (element.fixedStart) {
        fixColumns.add(element);
      } else if (element.fixedEnd) {
        fixEndColumns.add(element);
      } else {
        columns.add(element);
      }
    }
    return Column(
      children: [
        //标题
        renderTableGroup(context, fixColumns, columns, fixEndColumns, true),
        // 内容
        Expanded(
          child: SingleChildScrollView(
            child: renderTableGroup(
                context, fixColumns, columns, fixEndColumns, false),
          ),
        )
      ],
    );
  }

  /// 渲染组合表格
  Widget renderTableGroup(
      BuildContext context, fixColumns, columns, fixEndColumns, onlyTitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (fixColumns.isNotEmpty)
          renderTable(
            context,
            fixColumns,
            isFixedStart: true,
            isFixedEnd: false,
            onlyTitle: onlyTitle,
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollControl.addAndGet(onlyTitle ? "title" : "body"),
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: renderTable(
              context,
              columns,
              isFixedStart: false,
              isFixedEnd: false,
              onlyTitle: onlyTitle,
              appendColumnNum: fixColumns.length,
            ),
          ),
        ),
        if (fixEndColumns.isNotEmpty)
          renderTable(
            context,
            fixEndColumns,
            isFixedStart: false,
            isFixedEnd: true,
            onlyTitle: onlyTitle,
            appendColumnNum: fixColumns.length + columns.length,
          ),
      ],
    );
  }

  ///渲染表格
  Table renderTable(
    BuildContext context,
    List<StickyTableColumn<T>> allColumns, {
    int appendColumnNum = 0,
    bool isFixedStart = false,
    bool isFixedEnd = false,
    bool onlyTitle = false,
  }) {
    final titleDecoration = widget.titleDecoration ??
        const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xffebebeb), width: 0.5),
          ),
        );

    const titleTextColor = Color(0xff999999);
    const bodyTextColor = Color(0xff333333);

    ///内容
    final bodyColumnWidthMaps = allColumns
        .map((e) => e.columnWidth ?? widget.defaultColumnWidth)
        .toList()
        .asMap();
    return Table(
      defaultColumnWidth: widget.defaultColumnWidth,
      columnWidths: bodyColumnWidthMaps,
      border: widget.tableBorder,
      children: [
        /// 渲染表头
        if (onlyTitle)
          TableRow(
            decoration: titleDecoration,
            children: allColumns
                .map((e) => InkWell(
                      onTap: () {
                        if (e.onTitleClick != null) {
                          e.onTitleClick!(context, e);
                        }
                      },
                      child: Container(
                        alignment: e.alignment,
                        height: widget.titleHeight,
                        padding: widget.cellPadding ?? const EdgeInsets.all(10),
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: titleTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              e.renderTitle != null
                                  ? e.renderTitle!(context, e)
                                  : renderTitle(context, e),
                              if (e.showSort)
                                _SortWidget(
                                  sortUp: e.sort,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          )

        ///渲染表格内容
        else
          for (var row = 0; row < widget.data.length; row++) ...[
            TableRow(
              decoration: widget.rowDecoration,
              children: allColumns.asMap().entries.map((column) {
                //第几列
                final columnValue = column.key + appendColumnNum;
                return InkWell(
                  onTap: () {
                    if (column.value.onCellClick != null) {
                      column.value.onCellClick!(context, column.value,
                          widget.data[row], row, columnValue);
                    }
                  },
                  child: Container(
                    decoration: widget.cellDecoration != null
                        ? widget.cellDecoration!(context, column.value,
                            widget.data[row], row, columnValue)
                        : zebraCrossingBoxDecoration(row, columnValue),
                    alignment: column.value.alignment,
                    height: widget.cellHeight,
                    padding: widget.cellPadding ?? const EdgeInsets.all(10),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                          color: bodyTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      child: column.value.renderCell != null
                          ? column.value.renderCell!(context, column.value,
                              widget.data[row], row, columnValue)
                          : renderCell(context, column.value, widget.data[row],
                              row, columnValue),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
      ],
    );
  }

  ///渲染标题
  Widget renderTitle(BuildContext context, StickyTableColumn<T> title) {
    return Text(title.title);
  }

  ///渲染标题
  Widget renderCell(BuildContext context, StickyTableColumn<T> title,
      T data, int row, int column) {
    return const Text("-");
  }

  ///斑马线描述
  BoxDecoration? zebraCrossingBoxDecoration(int row, int column) {
    if (!widget.showZebraCrossing) return null;

    final isFirstColumn = column == 0;
    final isEndColumn = column == widget.columns.length - 1;
    final defaultRadius = widget.zebraCrossingRadius;
    final leftRadius = isFirstColumn ? defaultRadius : Radius.zero;
    final rightRadius = isEndColumn ? defaultRadius : Radius.zero;

    final (firstColor, secColor) = widget.zebraCrossingColor;
    return BoxDecoration(
      color: row % 2 == 0 ? firstColor : secColor,
      borderRadius: BorderRadius.only(
        topLeft: leftRadius,
        bottomLeft: leftRadius,
        topRight: rightRadius,
        bottomRight: rightRadius,
      ),
    );
  }
}

///排序组件
class _SortWidget extends StatelessWidget {
  const _SortWidget({super.key, this.sortUp});

  final bool? sortUp;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Icon(
            Icons.arrow_drop_up,
            color: sortUp == true ? color : null,
            size: 20,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Icon(
            Icons.arrow_drop_down,
            color: sortUp == false ? color : null,
            size: 20,
          ),
        ),
      ],
    );
  }
}
