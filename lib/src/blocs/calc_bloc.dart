import 'package:flutter/foundation.dart';
import 'package:flutter_saimmod_3/src/blocs/main_bloc.dart';
import 'package:flutter_saimmod_3/src/screens/navigation_info.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

class StateInfo {
  final List<int> state;
  int weight = 0;
  List<StateTransitionData> transitions;
  StateInfo(this.state);
}

class StateTransitionData {
  List<int> state;
  List<int> emittedByNode;
  String desc = '';
  double value = 1;
  bool isNewGenerated = false;
  int finalEmit = 0;

  StateTransitionData(this.state) {
    emittedByNode = List.filled(state.length, 0);
  }

  StateTransitionData.copy(StateTransitionData from) {
    state = List<int>.from(from.state);
    emittedByNode = List<int>.from(from.emittedByNode);
    isNewGenerated = from.isNewGenerated;
    desc = from.desc;
    value = from.value;
    finalEmit = from.finalEmit;
  }
}

class StateDescription {
  Map<String, List<StateVal>> values = {};

  StateDescription(List<String> data) {
    for (var val in data) {
      values[val] = [];
    }
  }
}

class StateVal {
  final String state;
  final double val;

  StateVal(this.val, this.state);
}

class StatesTableInfo {
  final List<List<String>> rows;
  final List<String> desc;
  StatesTableInfo(this.desc, this.rows);
}

class CalcBloc implements Disposable {
  final ResultData data;
  BehaviorSubject<StatesTableInfo> _allPossibleStates = BehaviorSubject();
  Observable<StatesTableInfo> get allPossibleStates => _allPossibleStates;
  PublishSubject<NavigationInfo> _navigate = PublishSubject();
  Observable<NavigationInfo> get navigate => _navigate;
  StateDescription listOfDesc;
  List<StateInfo> stateInfo;

  CalcBloc(this.data) {
    emitStates();
  }

  showData() {
    if (listOfDesc != null) {
      _navigate.add(NavigationInfo(ScreenType.data, args: listOfDesc));
    }
  }

  simulate() {
    if (stateInfo != null) {
      _navigate.add(NavigationInfo(ScreenType.sim, args: stateInfo));
    }
  }

  emitStates() async {
    stateInfo = await compute(getAllStates, data);
    var result = await compute(createTable, stateInfo);
    _allPossibleStates.add(result);
    listOfDesc = await compute(createDesc, stateInfo);
  }

  static List<StateInfo> getAllStates(ResultData data) {
    List<StateInfo> infoList = [StateInfo(getFirstState(data))];
    for (int i = 0; i < infoList.length; i++) {
      infoList[i].weight = getStateWeight(data, infoList[i].state);
      var states = _getPossibleStates(infoList[i].state, data);
      infoList[i].transitions = states;
      for (var state in states) {
        if (!infoList.any((s) => compareStates(s.state, state.state))) {
          infoList.add(StateInfo(state.state));
        }
      }
    }
    return infoList;
  }

  static int getStateWeight(ResultData data, List<int> state) {
    var result = 0;
    for (int i = 1; i < state.length; i++) {
      result += state[i].abs();
    }
    return result;
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

  static List<StateTransitionData> _getPossibleStates(
      List<int> initState, ResultData data) {
    List<StateTransitionData> states = [];
    states.add(StateTransitionData(List<int>.from(initState)));

    for (int i = data.nodes.length - 1; i >= 0; i--) {
      List<StateTransitionData> generatedStates = [];
      switch (data.nodes[i].type) {
        case NodeType.channel:
          if (initState[i] == 1) {
            for (var state in states) {
              var copy = StateTransitionData.copy(state);
              copy.desc += state.desc.isEmpty ? '(1-Π$i)' : '*(1-Π$i)';
              copy.value *= 1 - data.nodes[i].val;
              state.desc += state.desc.isEmpty ? 'Π$i' : '*Π$i';
              state.value *= data.nodes[i].val;

              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  fl = false;
                  copy.state[childId] = 1;
                  copy.emittedByNode[i]++;
                  copy.state[i] = 0;
                  generatedStates.add(copy);
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(copy, childId, data);
                  copy.emittedByNode[i]++;
                  copy.state[i] = 0;
                  generatedStates.add(copy);
                  break;
                }
              }

              if (fl) {
                if (data.nodes[i].childrenId.isNotEmpty) {
                  copy.state[i] = data.isBlock(i) ? -1 : 0;
                } else {
                  copy.finalEmit++;
                  copy.emittedByNode[i]++;
                  copy.state[i] = 0;
                }
                generatedStates.add(copy);
              }
            }
          } else if (initState[i] == -1) {
            for (var state in states) {
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  fl = false;
                  state.state[childId] = 1;
                  state.emittedByNode[i]++;
                  state.state[i] = 0;
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(state, childId, data);
                  state.emittedByNode[i]++;
                  state.state[i] = 0;
                  break;
                }
              }

              if (fl) {
                state.state[i] = data.isBlock(i) ? -1 : 0;
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
                  state.emittedByNode[i]++;
                  state.state[i]--;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  incrementQueue(state, childId, data);
                  state.emittedByNode[i]++;
                  state.state[i]--;
                }
              }
            }
          }
          break;
        case NodeType.periodicSource:
          if (initState[i] > 1) {
            for (var state in states) {
              state.state[i]--;
            }
          } else if (initState[i] <= 1) {
            for (var state in states) {
              if(initState[i] != 0) {
                state.isNewGenerated = true;
              }
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  fl = false;
                  state.state[childId] = 1;
                  state.emittedByNode[i]++;
                  state.state[i] = data.source.val.round();
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(state, childId, data);
                  state.emittedByNode[i]++;
                  state.state[i] = data.source.val.round();
                  break;
                }
              }

              if (fl) {
                if (data.nodes[i].childrenId.isNotEmpty) {
                  state.state[i] =
                      data.isBlock(i) ? 0 : data.source.val.round();
                } else {
                  state.finalEmit++;
                  state.emittedByNode[i]++;
                  state.state[i] = data.source.val.round();
                }
              }
            }
          }
          break;
        case NodeType.randomSource:
          if (initState[i] == 0) {
            for (var state in states) {
              var copy = StateTransitionData.copy(state);
              copy.isNewGenerated = true;
              copy.desc += state.desc.isEmpty ? '(1-ρ$i)' : '*(1-ρ$i)';
              copy.value *= 1 - data.nodes[i].val;
              state.desc += state.desc.isEmpty ? 'ρ$i' : '*ρ$i';
              state.value *= data.nodes[i].val;

              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (data.isChannel(childId) && state.state[childId] == 0) {
                  fl = false;
                  copy.state[childId] = 1;
                  copy.emittedByNode[i]++;
                  copy.state[i] = 0;
                  generatedStates.add(copy);
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(copy, childId, data);
                  copy.emittedByNode[i]++;
                  copy.state[i] = 0;
                  generatedStates.add(copy);
                  break;
                }
              }

              if (fl) {
                if (data.nodes[i].childrenId.isNotEmpty) {
                  copy.state[i] = data.isBlock(i) ? 1 : 0;
                } else {
                  copy.emittedByNode[i]++;
                  copy.finalEmit++;
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
                  state.emittedByNode[i]++;
                  state.state[i] = 0;
                  break;
                } else if (!data.isChannel(childId) &&
                    state.state[childId] < data.nodes[childId].val.round()) {
                  fl = false;
                  incrementQueue(state, childId, data);
                  state.emittedByNode[i]++;
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
    states.forEach((s)=>print('${createStateDesc(initState)} -> ${createStateDesc(s.state)}: ${createStateDesc(s.emittedByNode)}'));
    return states;
  }

  static incrementQueue(StateTransitionData state, int queueId, ResultData data) {
    if (state.state[queueId] > 0) {
      state.state[queueId]++;
      return state;
    }

    for (var childId in data.nodes[queueId].childrenId) {
      if (data.isChannel(childId) && state.state[childId] == 0) {
        state.state[childId] = 1;
        return state;
      } else if (!data.isChannel(childId) &&
          state.state[childId] < data.nodes[childId].val.round()) {
        incrementQueue(state, childId, data);
      }
    }

    if (data.nodes[queueId].childrenId.isNotEmpty) {
      state.state[queueId] = 1;
    } else {
      state.state[queueId] = 0;
      state.finalEmit++;
    }
  }

  static StateDescription createDesc(List<StateInfo> data) {
    StateDescription result = StateDescription(
        data.map((val) => createStateDesc(val.state)).toList());
    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < data[i].transitions.length; j++) {
        result.values[createStateDesc(data[i].transitions[j].state)].add(
            StateVal(
                data[i].transitions[j].value, createStateDesc(data[i].state)));
      }
    }
    return result;
  }

  ///TABLE DATA CREATION
  static StatesTableInfo createTable(List<StateInfo> data) {
    List<List<String>> result = [];
    for (int i = 0; i < data.length; i++) {
      result.add(createRegularListOfCells(i, data));
    }
    return StatesTableInfo(createInfoListOfCells(data), result);
  }

  static List<String> createInfoListOfCells(List<StateInfo> data) {
    List<String> cells = ['State'];

    for (int i = 0; i < data.length; i++) {
      cells.add(createStateDesc(data[i].state));
    }
    cells.add('State');
    return cells;
  }

  static List<String> createRegularListOfCells(
      int index, List<StateInfo> data) {
    var val = data[index];
    var info = createStateDesc(val.state);
    List<String> cells = [info];

    for (int i = 0; i < data.length; i++) {
      var desc = '';
      for (var child in val.transitions) {
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

  static String createStateDesc(List<int> state) {
    var str = '';
    state.forEach((v) => str += v != -1 ? v.toString() : 'B');
    return str;
  }

  ///TABLE DATA CREATION

  @override
  void dispose() {
    _allPossibleStates.close();
  }
}
