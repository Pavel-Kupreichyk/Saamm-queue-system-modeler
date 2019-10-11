import 'package:flutter/material.dart';
import 'package:flutter_saimmod_3/src/blocs/main_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/state_with_bag.dart';
import 'package:provider/provider.dart';

class MainScreenBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<MainBloc>(
      builder: (_) => MainBloc(),
      dispose: (_, bloc) => bloc.dispose(),
      child: Consumer<MainBloc>(
        builder: (_, bloc, __) => Scaffold(
          appBar: AppBar(
            title: Text('Queueing Theory App'),
          ),
          body: MainScreen(bloc),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final MainBloc bloc;
  MainScreen(this.bloc);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends StateWithBag<MainScreen> {
  int _prevLength = 0;
  Key stepperKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 40.0, left: 25),
          child: Text(
            'Nodes count selection',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        StreamBuilder<int>(
          stream: widget.bloc.countOfNodes,
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            final data = snapshot.data;
            return Slider(
              value: data.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              onChanged: (val) => widget.bloc.changeNodesCount(val.round()),
              label: 'nodes: ${data.round()}',
            );
          },
        ),
        StreamBuilder<int>(
          stream: widget.bloc.currStep,
          builder: (_, snapshot) {
            final currStep = snapshot.data ?? 0;
            return StreamBuilder<List<Node>>(
                stream: widget.bloc.workers,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  final nodes = snapshot.data;
                  if (_prevLength != nodes.length) {
                    stepperKey = UniqueKey();
                    _prevLength = nodes.length;
                  }
                  List<Step> stepList = [
                    Step(
                        title: Text(
                          'Select Source',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        content: createSource(nodes))
                  ];

                  for (int i = 1; i < nodes.length; i++) {
                    stepList.add(
                      Step(
                        title: Text(
                          'Select channel or queue',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        content: createWorker(i, nodes),
                      ),
                    );
                  }

                  return Expanded(
                    child: Stepper(
                      key: stepperKey,
                      currentStep: currStep,
                      steps: stepList,
                      onStepContinue: () => widget.bloc.incrementStep(currStep),
                      onStepCancel: () => widget.bloc.decrementStep(currStep),
                      onStepTapped: widget.bloc.selectStep,
                      controlsBuilder: (_,
                          {VoidCallback onStepContinue,
                          VoidCallback onStepCancel}) {
                        var nextStepDesc = currStep == nodes.length - 1
                            ? 'Calculate'
                            : 'Next node';
                        return Row(
                          children: <Widget>[
                            MaterialButton(
                              child: Text(
                                nextStepDesc,
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: onStepContinue,
                              color: Colors.blue,
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            currStep != 0
                                ? MaterialButton(
                                    child: Text('Previous node',
                                        style: TextStyle(color: Colors.white)),
                                    onPressed: onStepCancel,
                                    color: Colors.grey,
                                  )
                                : Container(),
                          ],
                        );
                      },
                    ),
                  );
                });
          },
        ),
      ],
    );
  }

  Widget createWorker(int workerNum, List<Node> nodes) {
    final type = nodes[workerNum].type;
    final infType = nodes[workerNum].influenceType;
    final data = nodes[workerNum].val;
    final parent = nodes[workerNum].parentId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Type of node:', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: <Widget>[
            _createNodeTypeRadio(NodeType.channel, 'Channel', type, workerNum),
            _createNodeTypeRadio(NodeType.queue, 'Queue', type, workerNum),
          ],
        ),
        type == NodeType.channel
            ? Text('Overflow behaviour:',
                style: TextStyle(fontWeight: FontWeight.bold))
            : Container(),
        type == NodeType.channel
            ? Row(
                children: <Widget>[
                  _createInfluenceTypeRadio(
                      InfluenceType.block, 'Block', infType, workerNum),
                  _createInfluenceTypeRadio(
                      InfluenceType.error, 'Error', infType, workerNum),
                ],
              )
            : Container(),
        Text('Value:', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: data,
          min: type == NodeType.queue ? 1 : 0.01,
          max: type == NodeType.queue ? 10 : 1,
          divisions: type == NodeType.queue ? 9 : 99,
          onChanged: (val) => widget.bloc.setWorkNodeVal(val, workerNum),
          label: type == NodeType.queue
              ? 'size: ${data.round()}'
              : 'П: ${data.toStringAsFixed(2)}',
        ),
        Text('Parent:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          width: 200,
          child: workerNum != 1
              ? Slider(
                  value: parent.toDouble(),
                  min: 0,
                  max: (workerNum - 1).toDouble(),
                  divisions: workerNum - 1,
                  onChanged: (val) =>
                      widget.bloc.setParentNode(val.round(), workerNum),
                  label: 'parent: ${parent + 1}',
                )
              : Text('Source'),
        ),
      ],
    );
  }

  Widget createSource(List<Node> nodes) {
    final infType = nodes[0].influenceType;
    final type = nodes[0].type;
    final data = nodes[0].val;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Type of source:', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: <Widget>[
            _createNodeTypeRadio(NodeType.periodicSource, 'Periodic', type, 0),
            _createNodeTypeRadio(NodeType.randomSource, 'Random', type, 0),
          ],
        ),
        Text('Overflow behaviour:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: <Widget>[
            _createInfluenceTypeRadio(InfluenceType.block, 'Block', infType, 0),
            _createInfluenceTypeRadio(InfluenceType.error, 'Error', infType, 0),
          ],
        ),
        Text('Value:', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: data,
          min: type == NodeType.periodicSource ? 1 : 0.01,
          max: type == NodeType.periodicSource ? 10 : 1,
          divisions: type == NodeType.periodicSource ? 9 : 99,
          onChanged: (val) => widget.bloc.setWorkNodeVal(val, 0),
          label: type == NodeType.periodicSource
              ? 'period: ${data.round()}'
              : 'ρ: ${data.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _createInfluenceTypeRadio(
      InfluenceType val, String desc, InfluenceType currData, int step) {
    return Row(
      children: <Widget>[
        Text(desc),
        Radio(
          value: val,
          groupValue: currData,
          onChanged: (val) => widget.bloc.changeInfluence(val, step),
        ),
      ],
    );
  }

  Widget _createNodeTypeRadio(
      NodeType val, String desc, NodeType currData, int step) {
    return Row(
      children: <Widget>[
        Text(desc),
        Radio(
          value: val,
          groupValue: currData,
          onChanged: step != 0
              ? (val) => widget.bloc.changeWorkerType(val, step)
              : widget.bloc.changeSource,
        ),
      ],
    );
  }

  @override
  void setupBindings() {
    bag += widget.bloc.navigate.listen((navInfo) async {
      Navigator.pushNamed(context, navInfo.getRoute(), arguments: navInfo.args);
    });
  }
}
