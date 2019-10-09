import 'dart:math';

import 'package:flutter_saimmod_3/src/blocs/main_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

class CalcBloc implements Disposable {
  final ResultData data;
  Random random = Random();
  final List<List<int>> states = [];
  List<int> currState;
  bool isPeriodicSource;

  CalcBloc(this.data) {
    isPeriodicSource = data.source.type == TypeOfSource.periodicSource;
    currState = getFirstState();
    states.add(currState);
  }

  List<int> getFirstState() {
    List<int> state = List.filled(data.workers.length + 1, 0);
    state[0] = (isPeriodicSource ? 2 : 0);
    return state;
  }

  getPossibleStates() {
    List<List<int>> states;
  }

  getNextState() {
    List<int> nextState = List.filled(data.workers.length + 1, 0);



    if (isPeriodicSource) {
      if (currState[0] == 1) {
        bool fl = true;
        for (var childId in data.source.childrenId) {
          if (currState[childId] == 0) {
            nextState[0] = data.source.val.round();
            nextState[childId] = 1;
            fl = false;
            break;
          }
        }
        if (fl) {
          nextState[0] = data.source.influenceType == InfluenceType.block
              ? 0
              : data.source.val.round();
        }
      } else {
        nextState[0] = currState[0] - 1;
      }
    } else {

    }
  }

  bool randomBool(double trueProbability) {
    return random.nextDouble() < trueProbability;
  }

  @override
  void dispose() {}
}
