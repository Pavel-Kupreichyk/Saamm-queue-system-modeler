import 'dart:math';

import 'package:flutter_saimmod_3/src/blocs/main_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

class StateInfo {
  final List<int> state;
  List<StateData> childStates;
  StateInfo(this.state);
}

class StateData {
  List<int> state;
  String desc = '';
  StateData(this.state);
}

class CalcBloc implements Disposable {
  final ResultData data;
  Random random = Random();
  final List<StateInfo> infoList = [];
  BehaviorSubject<List<StateInfo>> _allPossibleStates = BehaviorSubject();
  Observable<List<StateInfo>> get allPossibleStates => _allPossibleStates;

  CalcBloc(this.data) {
    infoList.add(StateInfo(getFirstState()));
    getAllStates();
    _allPossibleStates.add(infoList);
  }

  getAllStates() {
    int i = 0;
    while (i < infoList.length) {
      var states = _getPossibleStates(infoList[i].state);
      infoList[i].childStates = states;
      for (var state in states) {
        if (!infoList.any((s) => compareStates(s.state, state.state))) {
          infoList.add(StateInfo(state.state));
        }
      }
      i++;
    }
  }

  compareStates(List<int> state1, List<int> state2) {
    for (int i = 0; i < state1.length; i++) {
      if (state1[i] != state2[i]) {
        return false;
      }
    }
    return true;
  }

  List<int> getFirstState() {
    List<int> state = List.filled(data.nodes.length, 0);
    state[0] = (data.isSourcePeriodic() ? data.source.val.round() : 0);
    return state;
  }

  List<StateData> _getPossibleStates(List<int> initState) {
    List<StateData> states = [];
    states.add(StateData(List<int>.from(initState)));

    for (int i = data.nodes.length - 1; i >= 0; i--) {
      List<StateData> generatedStates = [];
      switch (data.nodes[i].type) {
        case NodeType.channel:
          if (initState[i] == 1) {
            for (var state in states) {
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (state.state[childId] == 0) {
                  fl = false;
                  var copy = List<int>.from(state.state);
                  copy[childId] = 1;
                  copy[i] = 0;
                  generatedStates.add(StateData(copy)
                    ..desc = state.desc +
                        (state.desc.isEmpty ? '(1-Π$i)' : '*(1-Π$i)'));
                  state.desc += state.desc.isEmpty ? 'Π$i' : '*Π$i';
                  break;
                }
              }

              if (fl) {
                var copy = List<int>.from(state.state);
                if (data.nodes[i].childrenId.isNotEmpty) {
                  copy[i] = data.isBlock(i) ? 1 : 0;
                } else {
                  copy[i] = 0;
                }
                generatedStates.add(StateData(copy)
                  ..desc = state.desc +
                      (state.desc.isEmpty ? '(1-Π$i)' : '*(1-Π$i)'));
                state.desc += state.desc.isEmpty ? 'Π$i' : '*Π$i';
              }
            }
          }
          break;
        case NodeType.queue:
          break;
        case NodeType.periodicSource:
          if (initState[i] > 1) {
            for (var state in states) {
              state.state[i] -= 1;
            }
          } else if (initState[i] <= 1) {
            for (var state in states) {
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (state.state[childId] == 0) {
                  fl = false;
                  state.state[childId] = 1;
                  state.state[i] = data.source.val.round();
                  break;
                }
              }

              if (fl) {
                state.state[i] = data.isBlock(i) ? 0 : data.source.val.round();
              }
            }
          }
          break;
        case NodeType.randomSource:
          break;
      }
      states.addAll(generatedStates);
    }
    return states;
  }

  bool randomBool(double trueProbability) {
    return random.nextDouble() < trueProbability;
  }

  @override
  void dispose() {}
}
