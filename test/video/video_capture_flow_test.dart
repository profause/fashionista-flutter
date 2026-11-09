import 'package:fashionista/data/models/trends/bloc/video_capture_cubit.dart';
import 'package:fashionista/data/models/trends/bloc/video_editor_state.dart';
import 'package:fashionista/data/models/trends/bloc/video_capture_state.dart';
import 'package:fashionista/presentation/screens/trends/video/video_capture_screen.dart';
import 'package:fashionista/presentation/screens/trends/video/video_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never touches the camera; the test drives the stage directly.
class _FakeCaptureCubit extends VideoCaptureCubit {
  _FakeCaptureCubit() : super();

  @override
  Future<void> initialize() async {}

  void useFrontCameraForTest() {
    emit(
      state.copyWith(
        isFrontCamera: true,
        isTorchAvailable: false,
        isTorchOn: false,
      ),
    );
  }

  void markRecorded(String path) {
    emit(
      VideoCaptureState(
        stage: VideoCaptureStage.recorded,
        recordedPath: path,
        elapsed: const Duration(seconds: 4),
      ),
    );
  }
}

void main() {
  late _FakeCaptureCubit cubit;

  setUp(() => cubit = _FakeCaptureCubit());
  tearDown(() => cubit.close());

  // The viewfinder shows a spinner while there is no camera, so the screen
  // never "settles": pump the route transition explicitly instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: VideoCaptureScreen(cubit: cubit)),
    );
    await tester.pump();
  }

  testWidgets('offers the three framing ratios, 9:16 by default', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(cubit.state.aspect, VideoAspectPreset.portrait);
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('4:5'), findsOneWidget);
    expect(find.text('9:16'), findsOneWidget);
  });

  testWidgets('picking a ratio changes the framing', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('1:1'));
    await tester.pump();

    expect(cubit.state.aspect, VideoAspectPreset.square);
  });

  testWidgets('the torch control is shown for the back camera only', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.flash_off), findsOneWidget);

    cubit.useFrontCameraForTest();
    await tester.pump();

    expect(find.byIcon(Icons.flash_off), findsNothing);
    expect(find.byIcon(Icons.flash_on), findsNothing);
  });

  testWidgets('a finished take opens the editor without another tap', (
    tester,
  ) async {
    await pumpScreen(tester);

    cubit.markRecorded('/tmp/take.mp4');
    await settle(tester);

    expect(find.byType(VideoEditorScreen), findsOneWidget);
    expect(find.byType(VideoCaptureScreen), findsOneWidget);
  });

  testWidgets('cancelling the edit returns to the take, not to the editor', (
    tester,
  ) async {
    await pumpScreen(tester);

    cubit.markRecorded('/tmp/take.mp4');
    await settle(tester);

    await tester.pageBack();
    await settle(tester);

    expect(find.byType(VideoEditorScreen), findsNothing);
    // The take is still there, so Retake / Edit remain available.
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Edit 4s clip'), findsOneWidget);
  });

  testWidgets('the same take never opens the editor twice', (tester) async {
    await pumpScreen(tester);

    cubit.markRecorded('/tmp/take.mp4');
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    // Re-emitting the recorded state must not push a second editor.
    cubit.markRecorded('/tmp/take.mp4');
    await settle(tester);

    expect(find.byType(VideoEditorScreen), findsNothing);
  });

  testWidgets('a new take opens the editor again', (tester) async {
    await pumpScreen(tester);

    cubit.markRecorded('/tmp/take-1.mp4');
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    cubit.markRecorded('/tmp/take-2.mp4');
    await settle(tester);

    expect(find.byType(VideoEditorScreen), findsOneWidget);
  });
}
