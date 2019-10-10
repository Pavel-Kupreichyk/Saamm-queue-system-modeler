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
          return Container();
        }
        var info = snapshot.data;
        return GridView.builder(
          scrollDirection: Axis.horizontal,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: info.length + 1,childAspectRatio: 0.5),
          itemCount: pow(info.length + 1, 2),
          itemBuilder: (BuildContext context, int index) {
            var row = index ~/ (info.length + 1);
            var column = index % (info.length + 1);
            String data;
            if (row == 0 && column == 0) {
              return Container();
            } else if (row == 0) {
              var state = info[column - 1].state;
              data = '${state[0]}${state[1]}${state[2]}${state[3]}';
            } else if (column == 0) {
              var state = info[row - 1].state;
              data = '${state[0]}${state[1]}${state[2]}${state[3]}';
            } else {
              data = 'None';
              for(var child in info[column-1].childStates) {
                if(widget.bloc.compareStates(child.state, info[row-1].state)) {
                  data = child.desc.isNotEmpty ? child.desc : '1';
                }
              }
            }
            return Container(
              child: Text(data),
            );
          },
        );
      },
    );
  }

  @override
  void setupBindings() {
    // TODO: implement setupBindings
  }
}
