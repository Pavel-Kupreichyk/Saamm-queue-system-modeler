import 'package:flutter_saimmod_3/src/blocs/calc_bloc.dart';
import 'package:flutter_saimmod_3/src/blocs/data_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/state_with_bag.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DataScreenBuilder extends StatelessWidget {
  final StateDescription data;
  DataScreenBuilder(this.data);

  @override
  Widget build(BuildContext context) {
    return Provider<DataBloc>(
      builder: (_) => DataBloc(data),
      dispose: (_, bloc) => bloc.dispose(),
      child: Consumer<DataBloc>(
        builder: (_, bloc, __) => Scaffold(
          appBar: AppBar(
            title: Text('Calculations'),
          ),
          body: DataScreen(bloc),
        ),
      ),
    );
  }
}

class DataScreen extends StatefulWidget {
  final DataBloc bloc;
  DataScreen(this.bloc);

  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends StateWithBag<DataScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          StreamBuilder<StateDescription>(
            stream: widget.bloc.statesDesc,
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _createColumnData(snapshot.data)),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _createColumnData(StateDescription desc) {
    List<Widget> widgets = [];
    widgets.add(Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text('Σ', style: TextStyle(fontSize: 20)),
        Text('P = 1')
      ],
    ));
    for (var key in desc.values.keys) {
      var values = desc.values[key];
      List<Widget> rowData = [];
      rowData.add(Text('P'));
      rowData.add(Text(key, style: TextStyle(fontSize: 8)));
      rowData.add(Text(' = '));
      if (values.isNotEmpty) {
        for (int i = 0; i < values.length; i++) {
          rowData.add(Text(values[i].val.toStringAsFixed(2)));
          rowData.add(Text('P'));
          rowData.add(Text(values[i].state, style: TextStyle(fontSize: 8)));
          if (i != values.length - 1) {
            rowData.add(Text(' + '));
          }
        }
      } else {
        rowData.add(Text('0'));
      }

      widgets.add(
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: rowData));
    }
    return widgets;
  }

  @override
  void setupBindings() {
    // TODO: implement setupBindings
  }
}
