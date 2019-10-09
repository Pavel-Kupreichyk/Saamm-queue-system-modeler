import 'package:flutter_saimmod_3/src/screens/navigation_info.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

enum TypeOfSource { randomSource, periodicSource }
enum TypeOfWorkNode { channel, queue }
enum InfluenceType { block, error }

abstract class Node {
  List<int> childrenId = [];
  final int id;
  double val;
  Node(this.id, this.val);
}

class Source extends Node {
  TypeOfSource type;
  InfluenceType influenceType;
  Source(int id, double val, this.type, this.influenceType) : super(id, val);
}

class WorkNode extends Node {
  int parentId;
  TypeOfWorkNode type;
  InfluenceType influenceType;
  WorkNode(int id, this.type, this.parentId, this.influenceType, double val)
      : super(id, val);
}

class ResultData {
  final List<WorkNode> workers;
  final Source source;
  ResultData(this.source, this.workers);
}

class MainBloc implements Disposable {
  BehaviorSubject<List<WorkNode>> _workNodes = BehaviorSubject.seeded([
    WorkNode(1, TypeOfWorkNode.channel, 0, InfluenceType.block, 0.5),
    WorkNode(2, TypeOfWorkNode.channel, 1, InfluenceType.block, 0.5),
    WorkNode(3, TypeOfWorkNode.channel, 2, InfluenceType.block, 0.5)
  ]);
  BehaviorSubject<Source> _source =
      BehaviorSubject.seeded(Source(0, 2, TypeOfSource.periodicSource, InfluenceType.block));
  BehaviorSubject<int> _currStep = BehaviorSubject.seeded(0);
  PublishSubject<NavigationInfo> _navigate = PublishSubject();

  Observable<NavigationInfo> get navigate => _navigate;

  Observable<int> get currStep => _currStep;
  Observable<Source> get source => _source;
  Observable<List<WorkNode>> get workers => _workNodes;

  incrementStep(int step) {
    if (step != 3) {
      _currStep.add(step + 1);
    } else {
      final source = _source.value;
      final workers = _workNodes.value;
      source.childrenId = [];
      workers.forEach((v) => v.childrenId = []);
      for (int i = 0; i < workers.length; i++) {
        if(workers[i].parentId == 0) {
          source.childrenId.add(i + 1);
        } else {
          workers[workers[i].parentId - 1].childrenId.add(i + 1);
        }
      }
      _navigate.add(NavigationInfo(ScreenType.calc,
          args: ResultData(_source.value, _workNodes.value)));
    }
  }

  decrementStep(int step) {
    if (step != 0) {
      _currStep.add(step - 1);
    }
  }

  changeSource(TypeOfSource sourceType) {
    var source = _source.value;
    source.type = sourceType;
    switch (sourceType) {
      case TypeOfSource.periodicSource:
        source.val = 2;
        _source.add(source);
        break;
      case TypeOfSource.randomSource:
        source.val = 0.5;
        _source.add(source);
        break;
      default:
        throw 'Not source type';
    }
  }

  setSourceVal(double val) {
    var source = _source.value;
    source.val = val;
    _source.add(source);
  }

  changeWorkerType(TypeOfWorkNode sourceType, int workerNum) {
    var workNodes = _workNodes.value;
    workNodes[workerNum].type = sourceType;
    switch (sourceType) {
      case TypeOfWorkNode.channel:
        workNodes[workerNum].val = 0.5;
        _workNodes.add(workNodes);
        break;
      case TypeOfWorkNode.queue:
        workNodes[workerNum].val = 2;
        _workNodes.add(workNodes);
        break;
      default:
        throw 'Not worker type';
    }
  }

  changeSourceInfluence(InfluenceType sourceType) {
    var source = _source.value;
    source.influenceType = sourceType;
    _source.add(source);
  }

  changeInfluence(InfluenceType sourceType, int workerNum) {
    var workNodes = _workNodes.value;
    workNodes[workerNum].influenceType = sourceType;
    _workNodes.add(workNodes);
  }

  setWorkNodeVal(double val, int stepId) {
    var workNodes = _workNodes.value;
    workNodes[stepId].val = val;
    _workNodes.add(workNodes);
  }

  setWorkNodeParent(int parent, int stepId) {
    var workNodes = _workNodes.value;
    workNodes[stepId].parentId = parent;
    _workNodes.add(workNodes);
  }

  @override
  void dispose() {
    _navigate.close();
    _currStep.close();
    _source.close();
    _workNodes.close();
  }
}
