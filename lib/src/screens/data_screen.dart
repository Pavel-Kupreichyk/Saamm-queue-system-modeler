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
              List<Widget> widgets = [];
              for (var key in snapshot.data.values.keys) {
                var val = snapshot.data.values[key];
                if (val.isEmpty) {
                  continue;
                }
                List<Widget> rowData = [];
                rowData.add(Text('P'));
                rowData.add(Text(key, style: TextStyle(fontSize: 8)));
                rowData.add(Text(' = '));
                var i = 0;
                for (var v in val) {
                  i++;
                  rowData.add(Text(v.val.toStringAsFixed(2)));
                  rowData.add(Text('P'));
                  rowData.add(Text(v.state, style: TextStyle(fontSize: 8)));
                  if (i != val.length) {
                    rowData.add(Text(' + '));
                  }
                }
                widgets.add(Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: rowData));
              }
              List<Widget> aValue = [];
              aValue.add(Text('A = '));
              var aVal = snapshot.data.aVal;
              for (int i = 1; i < aVal.length; i++) {
                aValue.add(Text(aVal[i].val.toStringAsFixed(2)));
                aValue.add(Text('P'));
                aValue.add(Text(aVal[i].state, style: TextStyle(fontSize: 8)));
                if (i != aVal.length-1) {
                  aValue.add(Text(' + '));
                }
              }
              widgets.add(SizedBox(height: 10,));
              widgets.add(Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: aValue));
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widgets);
            },
          ),
        ],
      ),
    );
  }

  @override
  void setupBindings() {
    // TODO: implement setupBindings
  }
}
