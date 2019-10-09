import 'package:flutter_saimmod_3/src/screens/navigation_info.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

enum NodeType { randomSource, periodicSource, channel, queue }
enum InfluenceType { block, error }

class Node {
  List<int> childrenId = [];
  final int id;
  double val;
  int parentId;
  NodeType type;
  InfluenceType influenceType;
  Node(this.id, this.val, this.parentId, this.type, this.influenceType);
}

class ResultData {
  final List<Node> nodes;
  Node get source => nodes[0];

  bool isBlock(int i) {
    return nodes[i].influenceType == InfluenceType.block;
  }

  bool isSourcePeriodic() {
    return nodes[0].type == NodeType.periodicSource;
  }

  bool isChannel(int i) {
    return nodes[i].type == NodeType.channel;
  }

  ResultData(this.nodes);
}

class MainBloc implements Disposable {
  BehaviorSubject<List<Node>> _nodes = BehaviorSubject.seeded([
    Node(0, 2, null, NodeType.periodicSource, InfluenceType.block),
    Node(1, 0.5, 0, NodeType.channel, InfluenceType.block),
    Node(2, 0.5, 1, NodeType.channel, InfluenceType.block),
    Node(3, 0.5, 2, NodeType.channel, InfluenceType.block),
  ]);
  BehaviorSubject<int> _currStep = BehaviorSubject.seeded(0);
  PublishSubject<NavigationInfo> _navigate = PublishSubject();

  Observable<NavigationInfo> get navigate => _navigate;

  Observable<int> get currStep => _currStep;
  Observable<List<Node>> get workers => _nodes;

  incrementStep(int step) {
    if (step != 3) {
      _currStep.add(step + 1);
    } else {
      final nodes = _nodes.value;
      nodes.forEach((v) => v.childrenId = []);
      for (int i = 1; i < nodes.length; i++) {
        nodes[nodes[i].parentId].childrenId.add(i);
      }
      _navigate.add(NavigationInfo(ScreenType.calc, args: ResultData(nodes)));
    }
  }

  decrementStep(int step) {
    if (step != 0) {
      _currStep.add(step - 1);
    }
  }

  changeSource(NodeType sourceType) {
    var nodes = _nodes.value;
    nodes[0].type = sourceType;
    switch (sourceType) {
      case NodeType.periodicSource:
        nodes[0].val = 2;
        _nodes.add(nodes);
        break;
      case NodeType.randomSource:
        nodes[0].val = 0.5;
        _nodes.add(nodes);
        break;
      default:
        throw 'Not a source type';
    }
  }

  changeWorkerType(NodeType nodeType, int stepId) {
    var nodes = _nodes.value;
    nodes[stepId].type = nodeType;
    switch (nodeType) {
      case NodeType.channel:
        nodes[stepId].val = 0.5;
        _nodes.add(nodes);
        break;
      case NodeType.queue:
        nodes[stepId].val = 2;
        _nodes.add(nodes);
        break;
      default:
        throw 'Not a worker type';
    }
  }

  changeInfluence(InfluenceType newInfluenceType, int stepId) {
    var nodes = _nodes.value;
    nodes[stepId].influenceType = newInfluenceType;
    _nodes.add(nodes);
  }

  setWorkNodeVal(double val, int stepId) {
    var nodes = _nodes.value;
    nodes[stepId].val = val;
    _nodes.add(nodes);
  }

  setParentNode(int parent, int stepId) {
    var nodes = _nodes.value;
    nodes[stepId].parentId = parent;
    _nodes.add(nodes);
  }

  @override
  void dispose() {
    _navigate.close();
    _currStep.close();
    _nodes.close();
  }
}
