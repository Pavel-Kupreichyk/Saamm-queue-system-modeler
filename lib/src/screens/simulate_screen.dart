import 'package:flutter_saimmod_3/src/blocs/calc_bloc.dart';
import 'package:flutter_saimmod_3/src/blocs/data_bloc.dart';
import 'package:flutter_saimmod_3/src/blocs/simulate_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/state_with_bag.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimulateScreenBuilder extends StatelessWidget {
  final List<StateInfo> data;
  SimulateScreenBuilder(this.data);

  @override
  Widget build(BuildContext context) {
    return Provider<SimulateBloc>(
      builder: (_) => SimulateBloc(data),
      dispose: (_, bloc) => bloc.dispose(),
      child: Consumer<SimulateBloc>(
        builder: (_, bloc, __) => Scaffold(
          appBar: AppBar(
            title: Text('Calculations'),
          ),
          body: SimulateScreen(bloc),
        ),
      ),
    );
  }
}

class SimulateScreen extends StatefulWidget {
  final SimulateBloc bloc;
  SimulateScreen(this.bloc);

  @override
  _SimulateScreenState createState() => _SimulateScreenState();
}

class _SimulateScreenState extends StateWithBag<SimulateScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          StreamBuilder<Results>(
            stream: widget.bloc.results,
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'A=${snapshot.data.A}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'L=${snapshot.data.L}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'W=${snapshot.data.W}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'λ=${snapshot.data.lambda}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Q=${snapshot.data.Q}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'P(error)=${snapshot.data.pError}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
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
