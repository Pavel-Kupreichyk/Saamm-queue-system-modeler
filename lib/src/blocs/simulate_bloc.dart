import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_saimmod_3/src/blocs/calc_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

class SimulationResults {
  final double A;
  final double L;
  final double lambda;
  double get W => L/A;
  double get Q => A/lambda;
  double get pError => 1 - Q;
  SimulationResults(this.A, this.L, this.lambda);
}

class SimulateBloc implements Disposable {
  static const int n = 10000;
  BehaviorSubject<SimulationResults> _results = BehaviorSubject();
  Observable<SimulationResults> get results => _results;

  SimulateBloc(List<StateInfo> data) {
    createAndEmitData(data);
  }

  createAndEmitData(List<StateInfo> data) async {
    var res = await compute(_simulate, data);
    _results.add(res);
  }

  static SimulationResults _simulate(List<StateInfo> data) {
    var random = Random();
    var sumWeight = 0;
    var sumCalculated = 0;
    var sumGenerated = 0;
    var currState = data[0];
    for (int i = 0; i < n; i++) {
      sumWeight += currState.weight;
      var randomVal = random.nextDouble();
      var idOfNextState = 0;
      while (currState.transitions[idOfNextState].value < randomVal) {
        randomVal -= currState.transitions[idOfNextState].value;
        idOfNextState++;
      }
      sumGenerated += currState.transitions[idOfNextState].isNewGenerated ? 1 : 0;
      sumCalculated += currState.transitions[idOfNextState].finalEmit;
      for (var stateInfo in data) {
        if (compareStates(
            currState.transitions[idOfNextState].state, stateInfo.state)) {
          currState = stateInfo;
          break;
        }
      }
    }
    return SimulationResults(sumCalculated/n,sumWeight/n,sumGenerated/n);
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
