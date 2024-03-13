import 'dart:async';
import 'dart:isolate';
import 'package:worker_manager/src/scheduling/task.dart';
import 'package:worker_manager/src/worker/worker.dart';

class WorkerImpl implements Worker {
  final void Function() onReviseAfterTimeout;

  WorkerImpl(this.onReviseAfterTimeout);

  @override
  Isolate get isolate => Isolate.current;

  @override
  var initialized = false;

  @override
  String? taskId;

  void Function(Object value)? onMessage;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<R> work<R>(Task<R> task) async {
    Future<R> run() async {
      return await task.execution();
    }

    taskId = task.id;
    if (task is TaskWithPort) {
      onMessage = (task as TaskWithPort).onMessage;
    }
    final resultValue = await run().whenComplete(() {
      _cleanUp();
    });
    return resultValue;
  }

  @override
  void cancelGentle() {
    _cleanUp();
  }

  @override
  Future<void> restart() async {
    kill();
    await initialize();
    onReviseAfterTimeout();
  }

  @override
  void kill() {
    _cleanUp();
    initialized = false;
  }

  void _cleanUp() {
    onMessage = null;
    taskId = null;
  }
}
