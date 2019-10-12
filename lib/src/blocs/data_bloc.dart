import 'package:flutter_saimmod_3/src/blocs/calc_bloc.dart';
import 'package:flutter_saimmod_3/src/support_classes/disposable.dart';
import 'package:rxdart/rxdart.dart';

class DataBloc implements Disposable {
  final StateDescription data;
  Observable<StateDescription> get statesDesc => Observable.just(data);

  DataBloc(this.data);

  @override
  void dispose() {}
}
