import 'package:flutter_saimmod_3/src/screens/navigation_info.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

enum NodeType { randomSource, periodicSource, channel, queue }
enum InfluenceType { block, error }

class Node {
  List<int> childrenId = [];
  double val;
  int parentId;
  NodeType type;
  InfluenceType influenceType;
  Node(this.val, this.parentId, this.type, this.influenceType);
}

class ResultData {
  final List<Node> nodes;
  Node get source => nodes[0];
  final List<int> _groups;

  int getGroup(int i) {
    if (_groups[i] != null) {
      return _groups[i];
    } else {
      var nodeInd = nodes[i].parentId;
      while (_groups[i] == null) {
        if (nodeInd == null) {
          _groups[i] = -1;
        } else if (nodes[nodeInd].influenceType == InfluenceType.error) {
          _groups[i] = nodeInd;
        } else {
          nodeInd = nodes[nodeInd].parentId;
        }
      }
      return _groups[i];
    }
  }

  bool isBlock(int i) {
    return nodes[i].influenceType == InfluenceType.block;
  }

  bool isSourcePeriodic() {
    return nodes[0].type == NodeType.periodicSource;
  }

  bool isChannel(int i) {
    return nodes[i].type == NodeType.channel;
  }

  ResultData(this.nodes) : _groups = List<int>.filled(nodes.length, null);
}

class MainBloc implements Disposable {
  BehaviorSubject<List<Node>> _nodes = BehaviorSubject.seeded([
    Node(2, null, NodeType.periodicSource, InfluenceType.block),
    Node(0.5, 0, NodeType.channel, InfluenceType.block),
    Node(0.5, 1, NodeType.channel, InfluenceType.block),
    Node(0.5, 2, NodeType.channel, InfluenceType.block),
  ]);
  BehaviorSubject<int> _currStep = BehaviorSubject.seeded(0);
  PublishSubject<NavigationInfo> _navigate = PublishSubject();

  Observable<NavigationInfo> get navigate => _navigate;
  Observable<int> get countOfNodes =>
      _nodes.stream.map((val) => val.length).distinct();
  Observable<int> get currStep => _currStep;
  Observable<List<Node>> get workers => _nodes;

  incrementStep(int step) {
    if (step != _nodes.value.length - 1) {
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

  selectStep(int step) {
    _currStep.add(step);
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

  changeNodesCount(int newCount) {
    var nodes = _nodes.value;

    if (newCount < nodes.length) {
      if (_currStep.value > newCount - 1) {
        _currStep.add(newCount - 1);
      }
      _nodes.add(nodes.getRange(0, newCount).toList());
    } else if (newCount > nodes.length) {
      final range = newCount - nodes.length;
      for (int i = 0; i < range; i++) {
        nodes.add(
            Node(0.5, nodes.length - 1, NodeType.channel, InfluenceType.block));
        _nodes.add(nodes);
      }
    }
  }

  @override
  void dispose() {
    _navigate.close();
    _currStep.close();
    _nodes.close();
  }
}
