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
              var copy = StateData(List<int>.from(state.state));
              copy.desc =
                  state.desc + (state.desc.isEmpty ? '(1-Π$i)' : '*(1-Π$i)');
              state.desc += state.desc.isEmpty ? 'Π$i' : '*Π$i';
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  fl = false;
                  copy.state[childId] = 1;
                  copy.state[i] = 0;
                  generatedStates.add(copy);
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(copy.state, childId, data);
                  copy.state[i] = 0;
                  generatedStates.add(copy);
                  break;
                }
              }

              if (fl) {
                if (data.nodes[i].childrenId.isNotEmpty) {
                  copy.state[i] = data.isBlock(i) ? 1 : 0;
                } else {
                  copy.state[i] = 0;
                }
                generatedStates.add(copy);
              }
            }
          }
          break;
        case NodeType.queue:
          if (initState[i] > 0) {
            for (var state in states) {
              for (var childId in data.nodes[i].childrenId) {
                if (state.state[i] == 0) {
                  break;
                }
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  state.state[childId] = 1;
                  state.state[i]--;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  incrementQueue(state.state, childId, data);
                  state.state[i]--;
                }
              }
            }
          }
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
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  fl = false;
                  state.state[childId] = 1;
                  state.state[i] = data.source.val.round();
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(state.state, childId, data);
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
          if (initState[i] == 0) {
            for (var state in states) {
              var copy = StateData(List<int>.from(state.state));
              copy.desc =
                  state.desc + (state.desc.isEmpty ? '(1-ρ$i)' : '*(1-ρ$i)');
              state.desc += state.desc.isEmpty ? 'ρ$i' : '*ρ$i';
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  fl = false;
                  copy.state[childId] = 1;
                  copy.state[i] = 0;
                  generatedStates.add(copy);
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(copy.state, childId, data);
                  copy.state[i] = 0;
                  generatedStates.add(copy);
                  break;
                }
              }

              if (fl) {
                if (data.nodes[i].childrenId.isNotEmpty) {
                  copy.state[i] = data.isBlock(i) ? 1 : 0;
                } else {
                  copy.state[i] = 0;
                }
                generatedStates.add(copy);
              }
            }
          } else if (initState[i] == 1) {
            for (var state in states) {
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  fl = false;
                  state.state[childId] = 1;
                  state.state[i] = 0;
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(state.state, childId, data);
                  state.state[i] = 0;
                  break;
                }
              }

              if (fl) {
                state.state[i] = data.isBlock(i) ? 1 : 0;
              }
            }
          }
          break;
      }
      states.addAll(generatedStates);
    }
    return states;
  }

  static List<int> incrementQueue(
      List<int> state, int queueId, ResultData data) {
    if (state[queueId] > 0) {
      state[queueId]++;
      return state;
    }

    for (var childId in data.nodes[queueId].childrenId) {
      if (data.isChannel(childId) && state[childId] == 0) {
        state[childId] = 1;
        return state;
      } else if (!data.isChannel(childId) &&
          state[childId] < data.nodes[childId].val.round()) {
        return incrementQueue(state, childId, data);
      }
    }

    state[queueId] = data.nodes[queueId].childrenId.isNotEmpty ? 1 : 0;
    return state;
  }

  //TABLE DATA CREATION
  static List<List<String>> createTable(List<StateInfo> data) {
    List<List<String>> result = [];
    for (int i = 0; i < data.length; i++) {
      result.add(i != data.length
          ? createRegularListOfCells(i, data)
          : createInfoListOfCells(data));
    }
    return result;
  }

  static List<String> createInfoListOfCells(List<StateInfo> data) {
    List<String> cells = ['State'];

    for (int i = 0; i < data.length; i++) {
      cells.add(data[i].state.join());
    }
    cells.add('State');
    return cells;
  }

  static List<String> createRegularListOfCells(
      int index, List<StateInfo> data) {
    var val = data[index];
    var info = val.state.join();
    List<String> cells = [info];

    for (int i = 0; i < data.length; i++) {
      var desc = '';
      for (var child in val.childStates) {
        if (compareStates(child.state, data[i].state)) {
          if (desc.isEmpty) {
            desc = child.desc.isNotEmpty ? child.desc : '1';
          } else {
            desc += ' +\n' + (child.desc.isNotEmpty ? child.desc : '1');
          }
        }
      }
      desc = desc.isEmpty ? '-' : desc;
      cells.add(desc);
    }
    cells.add(info);
    return cells;
  }
  //TABLE DATA CREATION

  bool randomBool(double trueProbability) {
    return random.nextDouble() < trueProbability;
  }

  @override
  void dispose() {}
}
