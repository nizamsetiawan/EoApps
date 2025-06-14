// Mocks generated by Mockito 5.4.6 from annotations
// in kenongotask2/test/task_notification_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:workmanager/src/options.dart' as _i4;
import 'package:workmanager/src/workmanager.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [Workmanager].
///
/// See the documentation for Mockito's code generation for more information.
class MockWorkmanager extends _i1.Mock implements _i2.Workmanager {
  MockWorkmanager() {
    _i1.throwOnMissingStub(this);
  }

  @override
  void executeTask(_i2.BackgroundTaskHandler? backgroundTask) =>
      super.noSuchMethod(
        Invocation.method(#executeTask, [backgroundTask]),
        returnValueForMissingStub: null,
      );

  @override
  _i3.Future<void> initialize(
    Function? callbackDispatcher, {
    bool? isInDebugMode = false,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #initialize,
              [callbackDispatcher],
              {#isInDebugMode: isInDebugMode},
            ),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> registerOneOffTask(
    String? uniqueName,
    String? taskName, {
    String? tag,
    _i4.ExistingWorkPolicy? existingWorkPolicy,
    Duration? initialDelay = Duration.zero,
    _i4.Constraints? constraints,
    _i4.BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay = Duration.zero,
    _i4.OutOfQuotaPolicy? outOfQuotaPolicy,
    Map<String, dynamic>? inputData,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #registerOneOffTask,
              [uniqueName, taskName],
              {
                #tag: tag,
                #existingWorkPolicy: existingWorkPolicy,
                #initialDelay: initialDelay,
                #constraints: constraints,
                #backoffPolicy: backoffPolicy,
                #backoffPolicyDelay: backoffPolicyDelay,
                #outOfQuotaPolicy: outOfQuotaPolicy,
                #inputData: inputData,
              },
            ),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> registerPeriodicTask(
    String? uniqueName,
    String? taskName, {
    Duration? frequency,
    Duration? flexInterval,
    String? tag,
    _i4.ExistingWorkPolicy? existingWorkPolicy,
    Duration? initialDelay = Duration.zero,
    _i4.Constraints? constraints,
    _i4.BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay = Duration.zero,
    _i4.OutOfQuotaPolicy? outOfQuotaPolicy,
    Map<String, dynamic>? inputData,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #registerPeriodicTask,
              [uniqueName, taskName],
              {
                #frequency: frequency,
                #flexInterval: flexInterval,
                #tag: tag,
                #existingWorkPolicy: existingWorkPolicy,
                #initialDelay: initialDelay,
                #constraints: constraints,
                #backoffPolicy: backoffPolicy,
                #backoffPolicyDelay: backoffPolicyDelay,
                #outOfQuotaPolicy: outOfQuotaPolicy,
                #inputData: inputData,
              },
            ),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<bool> isScheduledByUniqueName(String? uniqueName) =>
      (super.noSuchMethod(
            Invocation.method(#isScheduledByUniqueName, [uniqueName]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<void> registerProcessingTask(
    String? uniqueName,
    String? taskName, {
    Duration? initialDelay = Duration.zero,
    _i4.Constraints? constraints,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #registerProcessingTask,
              [uniqueName, taskName],
              {#initialDelay: initialDelay, #constraints: constraints},
            ),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> cancelByUniqueName(String? uniqueName) =>
      (super.noSuchMethod(
            Invocation.method(#cancelByUniqueName, [uniqueName]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> cancelByTag(String? tag) =>
      (super.noSuchMethod(
            Invocation.method(#cancelByTag, [tag]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> cancelAll() =>
      (super.noSuchMethod(
            Invocation.method(#cancelAll, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> printScheduledTasks() =>
      (super.noSuchMethod(
            Invocation.method(#printScheduledTasks, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);
}
