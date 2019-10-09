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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.bloc.currStep,
      builder: (_, snapshot) {
        final currStep = snapshot.data ?? 0;
        return Stepper(
          currentStep: currStep,
          steps: <Step>[
            Step(
              title: Text('Select Source'),
              content: StreamBuilder<List<Node>>(
                stream: widget.bloc.workers,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  final infType = snapshot.data[0].influenceType;
                  final type = snapshot.data[0].type;
                  final data = snapshot.data[0].val;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _createNodeTypeRadio(
                              NodeType.periodicSource, 'Periodic', type, 0),
                          _createNodeTypeRadio(
                              NodeType.randomSource, 'Random', type, 0),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          _createInfluenceTypeRadio(
                              InfluenceType.block, 'Block', infType, 0),
                          _createInfluenceTypeRadio(
                              InfluenceType.error, 'Error', infType, 0),
                        ],
                      ),
                      Slider(
                        value: data,
                        min: type == NodeType.periodicSource ? 1 : 0.01,
                        max: type == NodeType.periodicSource ? 10 : 1,
                        divisions: type == NodeType.periodicSource ? 9 : 99,
                        onChanged: (val) => widget.bloc.setWorkNodeVal(val, 0),
                        label: type == NodeType.periodicSource
                            ? 'period: ${data.toInt()}'
                            : 'r: ${data.toStringAsFixed(2)}',
                      ),
                    ],
                  );
                },
              ),
            ),
            Step(title: Text('Create 1 node'), content: createWorker(1)),
            Step(title: Text('Create 2 node'), content: createWorker(2)),
            Step(title: Text('Create 3 node'), content: createWorker(3)),
          ],
          onStepContinue: () => widget.bloc.incrementStep(currStep),
          onStepCancel: () => widget.bloc.decrementStep(currStep),
        );
      },
    );
  }

  Widget createWorker(int workerNum) {
    return StreamBuilder<List<Node>>(
      stream: widget.bloc.workers,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        final type = snapshot.data[workerNum].type;
        final infType = snapshot.data[workerNum].influenceType;
        final data = snapshot.data[workerNum].val;
        final parent = snapshot.data[workerNum].parentId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _createNodeTypeRadio(
                    NodeType.channel, 'Channel', type, workerNum),
                _createNodeTypeRadio(NodeType.queue, 'Queue', type, workerNum),
              ],
            ),
            Row(
              children: <Widget>[
                _createInfluenceTypeRadio(
                    InfluenceType.block, 'Block', infType, workerNum),
                _createInfluenceTypeRadio(
                    InfluenceType.error, 'Error', infType, workerNum),
              ],
            ),
            Slider(
              value: data,
              min: type == NodeType.queue ? 1 : 0.01,
              max: type == NodeType.queue ? 10 : 1,
              divisions: type == NodeType.queue ? 9 : 99,
              onChanged: (val) => widget.bloc.setWorkNodeVal(val, workerNum),
              label: type == NodeType.queue
                  ? 'queue: ${data.toInt()}'
                  : 'channel: ${data.toStringAsFixed(2)}',
            ),
            SizedBox(
              width: 200,
              child: workerNum != 1
                  ? Slider(
                      value: parent.toDouble(),
                      min: 0,
                      max: (workerNum-1).toDouble(),
                      divisions: workerNum-1,
                      onChanged: (val) =>
                          widget.bloc.setParentNode(val.round(), workerNum),
                      label: 'parent: ${parent + 1}',
                    )
                  : Text('Child of source'),
            ),
          ],
        );
      },
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
