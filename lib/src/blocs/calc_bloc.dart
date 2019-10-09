import 'dart:math';

import 'package:flutter_saimmod_3/src/blocs/main_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

class StateInfo {
  final List<int> state;
  //Map<List<int>, String> childStates;
  List<List<int>> childStates;
  StateInfo(this.state);
}

class CalcBloc implements Disposable {
  final ResultData data;
  Random random = Random();
  final List<StateInfo> infoList = [];
  //final List<List<int>> states = [];
  //List<int> currState;
  BehaviorSubject<List<String>> _allPossibleStates = BehaviorSubject();
  Observable<List<String>> get allPossibleStates => _allPossibleStates;

  CalcBloc(this.data) {
    data.nodes.forEach((t) {
      print('node');
      t.childrenId.forEach(print);
    });

    //currState = getFirstState();
    infoList.add(StateInfo(getFirstState()));
    getAllStates();
    List<String> results = [];
    infoList.forEach((val) {
      var state = val.state;
      results.add('${state[0]}${state[1]}${state[2]}${state[3]}');
    });
    _allPossibleStates.add(results);
  }

  getAllStates() {
    int i = 0;
    while(i< infoList.length) {
      var states = _getPossibleStates(infoList[i].state);
      infoList[i].childStates = states;
      for(var state in states) {
        if(!infoList.any((s) => compareStates(s.state, state))) {
          infoList.add(StateInfo(state));
        }
      }
      i++;
    }
  }
  compareStates(List<int> state1, List<int> state2) {
    for(int i = 0;i< state1.length;i++) {
      if(state1[i] != state2[i]) {
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

  List<List<int>> _getPossibleStates(List<int> initState) {
    print('new');
    print('${initState[0]}${initState[1]}${initState[2]}${initState[3]}');
    List<List<int>> states = [];
    states.add(List<int>.from(initState));

    for (int i = data.nodes.length - 1; i >= 0; i--) {
      List<List<int>> generatedStates = [];
      switch (data.nodes[i].type) {
        case NodeType.channel:
          if (initState[i] == 1) {
            for (var state in states) {
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (state[childId] == 0) {
                  fl = false;
                  var copy = List<int>.from(state);
                  copy[childId] = 1;
                  copy[i] = 0;
                  generatedStates.add(copy);
                  break;
                }
              }

              if (fl) {
                var copy = List<int>.from(state);
                if(data.nodes[i].childrenId.isNotEmpty) {
                  copy[i] = data.isBlock(i) ? 1 : 0;
                } else {
                  copy[i] = 0;
                }
                generatedStates.add(copy);
              }
            }
          }
          break;
        case NodeType.queue:
          break;
        case NodeType.periodicSource:
          if (initState[i] > 1) {
            for(var state in states) {
              state[i] -= 1;
            }
          } else if (initState[i] <= 1) {
            for (var state in states) {
              bool fl = true;
              for (var childId in data.nodes[i].childrenId) {
                if (state[childId] == 0) {
                  fl = false;
                  state[childId] = 1;
                  state[i] = data.source.val.round();
                  break;
                }
              }

              if (fl) {
                state[i] = data.isBlock(i) ? 0 : data.source.val.round();
              }
            }
          }
          break;
        case NodeType.randomSource:
          break;
      }
      states.addAll(generatedStates);
    }
    print('-----');
    states.forEach((s) =>  print('${s[0]}${s[1]}${s[2]}${s[3]}'));
    return states;
  }

  bool randomBool(double trueProbability) {
    return random.nextDouble() < trueProbability;
  }

  @override
  void dispose() {}
}
