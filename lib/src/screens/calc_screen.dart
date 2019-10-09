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
    return Container();
  }

  @override
  void setupBindings() {
    // TODO: implement setupBindings
  }
}
