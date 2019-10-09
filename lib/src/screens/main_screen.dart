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
              content: StreamBuilder<Source>(
                stream: widget.bloc.source,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  final infType = snapshot.data.influenceType;
                  final type = snapshot.data.type;
                  final data = snapshot.data.val;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _createSourceTypeRadio(
                              TypeOfSource.periodicSource, 'Periodic', type),
                          _createSourceTypeRadio(
                              TypeOfSource.randomSource, 'Random', type),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          _createInfluenceSourceRadio(
                              InfluenceType.block, 'Block', infType),
                          _createInfluenceSourceRadio(
                              InfluenceType.error, 'Error', infType),
                        ],
                      ),
                      Slider(
                        value: data,
                        min: type == TypeOfSource.periodicSource ? 1 : 0.01,
                        max: type == TypeOfSource.periodicSource ? 10 : 1,
                        divisions: type == TypeOfSource.periodicSource ? 9 : 99,
                        onChanged: widget.bloc.setSourceVal,
                        label: type == TypeOfSource.periodicSource
                            ? 'period: ${data.toInt()}'
                            : 'r: ${data.toStringAsFixed(2)}',
                      ),
                    ],
                  );
                },
              ),
            ),
            Step(title: Text('Create 1 node'), content: createWorker(0)),
            Step(title: Text('Create 2 node'), content: createWorker(1)),
            Step(title: Text('Create 3 node'), content: createWorker(2)),
          ],
          onStepContinue: () => widget.bloc.incrementStep(currStep),
          onStepCancel: () => widget.bloc.decrementStep(currStep),
        );
      },
    );
  }

  Widget createWorker(int workerNum) {
    return StreamBuilder<List<WorkNode>>(
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
                _createWorkerTypeRadio(
                    TypeOfWorkNode.channel, 'Channel', type, workerNum),
                _createWorkerTypeRadio(
                    TypeOfWorkNode.queue, 'Queue', type, workerNum),
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
              min: type == TypeOfWorkNode.queue ? 1 : 0.01,
              max: type == TypeOfWorkNode.queue ? 10 : 1,
              divisions: type == TypeOfWorkNode.queue ? 9 : 99,
              onChanged: (val) => widget.bloc.setWorkNodeVal(val, workerNum),
              label: type == TypeOfWorkNode.queue
                  ? 'queue: ${data.toInt()}'
                  : 'channel: ${data.toStringAsFixed(2)}',
            ),
            SizedBox(
              width: 200,
              child: workerNum != 0
                  ? Slider(
                      value: parent.toDouble(),
                      min: 0,
                      max: workerNum.toDouble(),
                      divisions: workerNum,
                      onChanged: (val) =>
                          widget.bloc.setWorkNodeParent(val.round(), workerNum),
                      label: 'parent: ${parent + 1}',
                    )
                  : Text('Child of source'),
            ),
          ],
        );
      },
    );
  }

  Widget _createInfluenceSourceRadio(
      InfluenceType val, String desc, InfluenceType currData) {
    return Row(
      children: <Widget>[
        Text(desc),
        Radio(
          value: val,
          groupValue: currData,
          onChanged: widget.bloc.changeSourceInfluence,
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

  Widget _createWorkerTypeRadio(
      TypeOfWorkNode val, String desc, TypeOfWorkNode currData, int step) {
    return Row(
      children: <Widget>[
        Text(desc),
        Radio(
          value: val,
          groupValue: currData,
          onChanged: (val) => widget.bloc.changeWorkerType(val, step),
        ),
      ],
    );
  }

  Widget _createSourceTypeRadio(
      TypeOfSource val, String desc, TypeOfSource currData) {
    return Row(
      children: <Widget>[
        Text(desc),
        Radio(
          value: val,
          groupValue: currData,
          onChanged: widget.bloc.changeSource,
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
