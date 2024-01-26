# sticky_table

一个可以固定表头、首尾列、以及可以自定义单元格和表头的表格组件。

A table component that can fix headers, first and end columns, and customize cells and headers.


## Getting started

In the command line

```shell
flutter pub get sticky_table
```

## 效果演示

![example.gif](doc%2Fexample.gif)

## 固定列，表头自动固定

// Fixed column, header automatically fixed

```dart
demo() {
  StickyTable(
      data: [1, 2, 3, 4, 5],
      columns: [
        StickyTableColumn(
          "Title",
          //固定在开头
          fixedStart: true,
          //固定在结尾
          fixedEnd: false,
        )
      ]
  );
}
```

## 去除默认的单元格内边距

```dart
demo() {
  StickyTable(
    cellPadding: EdgeInsets.zero,
  );
}
```

## 自定义 表格的头、尾的背景描述符

```dart
demo() {
  StickyTable(
    titleDecoration: BoxDecoration(
        color: Colors.white
    ),
    rowDecoration: BoxDecoration(
        color: Colors.black12
    ),
  );
}
```

## 显示斑马线/ Show the zebra crossing

1. 支持显示斑马线
2. 设置斑马线颜色：单行、双行
3. 设置斑马线首尾的圆角弧度

```dart
demo() {
  StickyTable(
    showZebraCrossing: true,
    zebraCrossingColor: (Colors.white, const Color(0xfff5f5f5)),
    zebraCrossingRadius: const Radius.circular(12),
  );
}
```

## 完整使用方式 / Full Usage

```dart
 demo() {
  return StickyTable(
    // 支持任意数据数组
    data: List.generate(50, (index) => sort ? 50 - index : index),
    // 默认列宽
    defaultColumnWidth: const FixedColumnWidth(80),
    // 标题的高度 default: 58
    titleHeight: 58,
    // 单元格高度 default: 58
    cellHeight: 58,
    // 每一列的配置
    columns: [
      StickyTableColumn(
        "Title", // 标题 / TITLE
        fixedStart: true,
        //是否在开头固定 / Is it fixed at the beginning?
        showSort: true,
        //是否支持排序 /Support sorting
        sort: sort,
        //排序图标 / Sort i
        //列宽：支持百分比和自适应 / Column width, Support percentage and adaptive
        columnWidth: const FixedColumnWidth(80),
        //单元格的对齐方式 /Align cells
        alignment: Alignment.centerLeft,
        // 标题的点击时间 / Click time of the title
        onTitleClick: (context, title) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Sort")));
          setState(() {
            sort = !(title.sort ?? false);
          });
        },
        // 自定义渲染单元格 / Custom rendering cells
        renderCell: (context, title, data, row, column) {
          return Text("Name$data");
        },
        //自定义渲染标题 / Custom rendering title
        renderTitle: (context, title) {
          return Text(
            title.title,
            style: const TextStyle(color: Colors.purple),
          );
        },
      ),
      StickyTableColumn(
        "Age",
        showSort: true,
        sort: false,
        onCellClick: (context, title, data, row, column) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("年龄$data")));
        },
        renderCell: (context, title, data, row, column) {
          return Text("*$data");
        },
      ),
      ...List.generate(
        10,
            (index) =>
            StickyTableColumn(
              "Sub Title $index",
              showSort: true,
              sort: false,
              renderCell: (context, title, data, row, column) {
                return Text("Content $row-$column");
              },
            ),
      ),
      StickyTableColumn(
        "Option",
        // 固定在结尾
        fixedEnd: true,
        columnWidth: const FixedColumnWidth(100),
        renderCell: (context, title, data, row, column) {
          return MaterialButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text("删除$data成功")));
            },
            color: Colors.red,
            minWidth: 0,
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    ],
  );
}
```

# Thanks ~

掘金分享更多：https://juejin.cn/user/660178231645965?utm_source=gold_browser_extension
# 致谢

❤️❤️❤️

Thanks to [sync_scroll_controller](https://pub.dev/packages/sync_scroll_controller) ❤️

