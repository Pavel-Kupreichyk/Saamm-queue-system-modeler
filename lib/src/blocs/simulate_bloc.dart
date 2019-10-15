import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_saimmod_3/src/blocs/calc_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

class SimulationResults {
  final int ticks;
  final int sumGenerated;
  final int sumCalculated;
  final List<int> sumProcessed;
  final Map<int, int> weightMap;

  double get A => sumCalculated / ticks;
  double get L => weightMap.values.reduce((a, b) => a + b) / ticks;
  double get lambda => sumGenerated / ticks;
  double get W => _calcW();
  double get Q => A / lambda;
  double get pError => 1 - Q;

  double _calcW() {
    double W = 0;
    weightMap
        .forEach((k, v) => W += v / (k != -1 ? sumProcessed[k] : sumGenerated));
    return W;
  }

  SimulationResults(this.ticks, this.sumGenerated, this.sumCalculated,
      this.sumProcessed, this.weightMap);
}

class SimulateBloc implements Disposable {
  static const int n = 1000000;
  BehaviorSubject<SimulationResults> _results = BehaviorSubject();
  Observable<SimulationResults> get results => _results;

  SimulateBloc(List<StateInfo> data) {
    _createAndEmitData(data);
  }

  _createAndEmitData(List<StateInfo> data) async {
    var res = await compute(_simulate, data);
    _results.add(res);
  }

  static SimulationResults _simulate(List<StateInfo> data) {
    var random = Random();
    var currState = data[0];
    Map<int, int> weightMap = {};
    for (var key in currState.weightByGroup.keys) {
      weightMap[key] = 0;
    }
    List<int> sumProcessed = List<int>.filled(currState.state.length, 0);
    var sumCalculated = 0;
    var sumGenerated = 0;

    //Simulation loop
    for (int i = 0; i < n; i++) {
      currState.weightByGroup.forEach((k, v) => weightMap[k] += v);
      var randomVal = random.nextDouble();
      var idOfNextState = 0;
      while (currState.transitions[idOfNextState].value < randomVal) {
        randomVal -= currState.transitions[idOfNextState].value;
        idOfNextState++;
      }
      sumGenerated +=
          currState.transitions[idOfNextState].isNewGenerated ? 1 : 0;
      sumCalculated += currState.transitions[idOfNextState].finalEmit;
      for (int i = 0; i < sumProcessed.length; i++) {
        sumProcessed[i] +=
            currState.transitions[idOfNextState].emittedByNode[i];
      }
      for (var stateInfo in data) {
        if (_compareStates(
            currState.transitions[idOfNextState].state, stateInfo.state)) {
          currState = stateInfo;
          break;
        }
      }
    }

    return SimulationResults(
        n, sumGenerated, sumCalculated, sumProcessed, weightMap);
  }

  static bool _compareStates(List<int> state1, List<int> state2) {
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
