import 'dart:math';

import 'package:flutter_saimmod_3/src/blocs/calc_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

class Results {
  final double A;
  final double L;
  final double lambda;
  double get W => L/A;
  double get Q => A/lambda;
  double get pError => 1 - Q;
  Results(this.A, this.L, this.lambda);
}

class SimulateBloc implements Disposable {
  static const int n = 10000;
  BehaviorSubject<Results> _results = BehaviorSubject();
  Observable<Results> get results => _results;
  SimulateBloc(List<StateInfo> data) {
    var res = _simulate(data);
    _results.add(res);
  }

  static Results _simulate(List<StateInfo> data) {
    var random = Random();
    var sumWeight = 0;
    var sumCalculated = 0;
    var sumGenerated = 0;
    var currState = data[0];
    for (int i = 0; i < n; i++) {
      sumWeight += currState.weight;
      var randomVal = random.nextDouble();
      var idOfNextState = 0;
      while (currState.childStates[idOfNextState].value < randomVal) {
        randomVal -= currState.childStates[idOfNextState].value;
        idOfNextState++;
      }
      sumGenerated += currState.childStates[idOfNextState].isNewGenerated ? 1 : 0;
      sumCalculated += currState.childStates[idOfNextState].finalEmit;
      for (var stateInfo in data) {
        if (compareStates(
            currState.childStates[idOfNextState].state, stateInfo.state)) {
          currState = stateInfo;
          break;
        }
      }
    }
    return Results(sumCalculated/n,sumWeight/n,sumGenerated/n);
  }

  static bool compareStates(List<int> state1, List<int> state2) {
    for (int i = 0; i < state1.length; i++) {
      if (state1[i] != state2[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {}
}
