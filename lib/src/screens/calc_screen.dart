import 'package:flutter_saimmod_3/src/blocs/calc_bloc.dart';
import 'package:flutter_saimmod_3/src/blocs/main_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/state_with_bag.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalcScreenBuilder extends StatelessWidget {
  final ResultData data;
  CalcScreenBuilder(this.data);

  @override
  Widget build(BuildContext context) {
    return Provider<CalcBloc>(
      builder: (_) => CalcBloc(data),
      dispose: (_, bloc) => bloc.dispose(),
      child: Consumer<CalcBloc>(
        builder: (_, bloc, __) => Scaffold(
          appBar: AppBar(
            title: Text('Graph'),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  'Equations system',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: bloc.showData,
              ),
              FlatButton(
                child: Text(
                  'Simulate',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: bloc.simulate,
              )
            ],
          ),
          body: CalcScreen(bloc),
        ),
      ),
    );
  }
}

class CalcScreen extends StatefulWidget {
  final CalcBloc bloc;
  CalcScreen(this.bloc);

  @override
  _CalcScreenState createState() => _CalcScreenState();
}

class _CalcScreenState extends StateWithBag<CalcScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<TableInfo>(
        stream: widget.bloc.allPossibleStates,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var info = snapshot.data;
          var dataSource = CustomDataSource(info);

          List<DataColumn> columns =
              info.desc.map((val) => DataColumn(label: Text(val))).toList();
          return Scrollbar(
            child: ListView(
              children: <Widget>[
                PaginatedDataTable(
                  header: const Text('State graph'),
                  rowsPerPage: snapshot.data.rows.length + 1,
                  columns: columns,
                  source: dataSource,
                  columnSpacing: 10,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void setupBindings() {
    bag += widget.bloc.navigate.listen((navInfo) async {
      Navigator.pushNamed(context, navInfo.getRoute(), arguments: navInfo.args);
    });
  }
}

class CustomDataSource extends DataTableSource {
  final TableInfo results;
  CustomDataSource(this.results);

  @override
  DataRow getRow(int index) {
    List<DataCell> cells = [];
    if (index < results.rows.length) {
      for (int i = 0; i < results.rows[index].length; i++) {
        cells.add(DataCell(Text(results.rows[index][i],
            style: i != 0 && i != results.rows[index].length - 1
                ? TextStyle(fontWeight: FontWeight.bold)
                : null)));
      }
    } else {
      results.desc.forEach((val) => cells.add(DataCell(Text(val))));
    }
    return DataRow(
      cells: cells,
    );
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => results.rows.length + 1;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;
}
