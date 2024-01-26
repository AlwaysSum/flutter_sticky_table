import 'package:flutter/material.dart';
import 'package:sticky_table/sticky_table.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool sort = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: StickyTable(
            data: List.generate(50, (index) => sort ? 50 - index : index),
            defaultColumnWidth: const FixedColumnWidth(80),
            titleHeight:58,
            cellHeight: 58,
            columns: [
              StickyTableColumn(
                "名称",
                fixedStart: true,
                showSort: true,
                sort: sort,
                columnWidth: const FixedColumnWidth(80),
                alignment: Alignment.centerLeft,
                onTitleClick: (context, title) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("排序")));
                  setState(() {
                    sort = !(title.sort ?? false);
                  });
                },
                renderCell: (context, title, data, row, column) {
                  return Text("名称$data");
                },
                renderTitle: (context, title) {
                  return Text(
                    title.title,
                    style: const TextStyle(color: Colors.purple),
                  );
                },
              ),
              StickyTableColumn(
                "年龄",
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
                    (index) => StickyTableColumn(
                  "标题$index",
                  showSort: true,
                  sort: false,
                  renderCell: (context, title, data, row, column) {
                    return Text("内容$row-$column");
                  },
                ),
              ),
              StickyTableColumn(
                "操作",
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
                      "删除",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
