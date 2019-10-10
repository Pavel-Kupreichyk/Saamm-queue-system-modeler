import 'dart:math';

import 'package:flutter/foundation.dart';
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
  BehaviorSubject<List<StateInfo>> _allPossibleStates = BehaviorSubject();
  Observable<List<StateInfo>> get allPossibleStates => _allPossibleStates;

  CalcBloc(this.data) {
    emitStates();
  }

  emitStates() async {
    var res = await compute(getAllStates, data);
    _allPossibleStates.add(res);
  }

  static getAllStates(ResultData data) {
    List<StateInfo> infoList = [StateInfo(getFirstState(data))];
    for (int i = 0; i < infoList.length; i++) {
      var states = _getPossibleStates(infoList[i].state, data);
      infoList[i].childStates = states;
      for (var state in states) {
        if (!infoList.any((s) => compareStates(s.state, state.state))) {
          infoList.add(StateInfo(state.state));
        }
      }
    }
    return infoList;
  }

  static compareStates(List<int> state1, List<int> state2) {
    for (int i = 0; i < state1.length; i++) {
      if (state1[i] != state2[i]) {
        return false;
      }
    }
    return true;
  }

  static List<int> getFirstState(ResultData data) {
    List<int> state = List.filled(data.nodes.length, 0);
    state[0] = (data.isSourcePeriodic() ? data.source.val.round() : 0);
    return state;
  }

  static List<StateData> _getPossibleStates(
      List<int> initState, ResultData data) {
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
// Add desc
  static List<StateData> incrementQueue(
      StateData state, int queueId, ResultData data) {
    if (state.state[queueId] > 0) {
      var copy = List<int>.from(state.state);
      copy[queueId] += 1;
      return [StateData(copy)..desc = state.desc];
    }

    List<StateData> queues = [];
    var fl = true;
    for (var childId in data.nodes[queueId].childrenId) {
      if (data.isChannel(queueId) && state.state[childId] == 0) {
        fl = false;
        var copy = List<int>.from(state.state);
        copy[childId] = 1;
        queues.add(StateData(copy)..desc = state.desc);
        break;
      } else if (!data.isChannel(queueId) && state.state[childId] < data.nodes[childId].val.round()) {
        //incrementQueue(state, queueId, data);
      }
    }
    if (fl) {
      var copy = List<int>.from(state.state);
      copy[queueId] = data.nodes[queueId].childrenId.isNotEmpty ? 1 : 0;
      queues.add(StateData(copy)..desc = state.desc);
    }
    return queues;
  }

  bool randomBool(double trueProbability) {
    return random.nextDouble() < trueProbability;
  }

  @override
  void dispose() {}
}
