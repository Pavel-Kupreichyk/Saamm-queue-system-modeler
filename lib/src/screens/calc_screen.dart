import 'dart:math';

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
            title: Text('Calculations'),
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
    return StreamBuilder<List<StateInfo>>(
      stream: widget.bloc.allPossibleStates,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var info = snapshot.data;
        var dataSource = CustomDataSource(info);

        List<DataColumn> columns = info
            .map((val) => DataColumn(label: Text(val.state.join())))
            .toList();
        columns.insert(0, DataColumn(label: Text('State')));
        columns.add(DataColumn(label: Text('State')));
        return SafeArea(
          bottom: false,
          child: Scrollbar(
            child: ListView(
              children: <Widget>[
                PaginatedDataTable(
                  header: const Text('State graph'),
                  rowsPerPage: snapshot.data.length + 1,
                  columns: columns,
                  source: dataSource,
                  columnSpacing: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void setupBindings() {
    // TODO: implement setupBindings
  }
}

class CustomDataSource extends DataTableSource {
  final List<StateInfo> results;
  CustomDataSource(this.results);

  @override
  DataRow getRow(int index) {
    List<DataCell> cells = index != results.length
        ? createRegularListOfCells(index)
        : createInfoListOfCells();
    return DataRow(
      cells: cells,
    );
  }

  List<DataCell> createInfoListOfCells() {
    var infoCell = DataCell(Text('State'));
    List<DataCell> cells = [infoCell];

    for (int i = 0; i < results.length; i++) {
      cells.add(DataCell(Text(results[i].state.join())));
    }
    cells.add(infoCell);
    return cells;
  }

  List<DataCell> createRegularListOfCells(int index) {
    var val = results[index];
    var infoCell = DataCell(
        Text(val.state.join()));
    List<DataCell> cells = [infoCell];

    for (int i = 0; i < results.length; i++) {
      var desc = '';
      for (var child in val.childStates) {
        if (compareStates(child.state, results[i].state)) {
          if (desc.isEmpty) {
            desc = child.desc.isNotEmpty ? child.desc : '1';
          } else {
            desc += ' +\n' + (child.desc.isNotEmpty ? child.desc : '1');
          }
        }
      }
      desc = desc.isEmpty ? '-' : desc;
      cells.add(DataCell(Text(
        desc,
        style: TextStyle(fontWeight: FontWeight.bold),
      )));
    }
    cells.add(infoCell);
    return cells;
  }

  compareStates(List<int> state1, List<int> state2) {
    for (int i = 0; i < state1.length; i++) {
      if (state1[i] != state2[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => results.length + 1;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;
}
