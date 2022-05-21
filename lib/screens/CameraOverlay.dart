import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:project/controllers/UserController.dart';
import '../main.dart';
import 'IndexScreen.dart';

class CameraOverlay extends StatefulWidget {
  const CameraOverlay(
      {
      // {required this.loggedCompleter,
      required this.closeOverlay,
      required this.onTakePicture,
      Key? key})
      : super(key: key);

  // final Completer<bool> loggedCompleter;
  final void Function() closeOverlay;
  final void Function(XFile file) onTakePicture;

  @override
  State<CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay>
    with WidgetsBindingObserver {
  late bool logged;
  bool isPaused = false;
  CameraController? controller;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("didChangeAppLifecycleState overlay");
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller!.description);
      }
    }
  }

  @override
  void initState() {
    print("initState overlay");
    WidgetsBinding.instance!.addObserver(this);

    onNewCameraSelected(cameras[1]);
    super.initState();
  }

  @override
  void dispose() {
    print("dispose overlay");
    WidgetsBinding.instance!.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("build overlay paused: ${controller?.value.isPreviewPaused}");
    double cameraSize = MediaQuery.of(context).size.width;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Material(
        color: Colors.transparent,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: cameraSize,
                height: cameraSize,
                child: ClipOval(
                  child: OverflowBox(
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: SizedBox(
                        width: cameraSize,
                        child: CameraPreview(
                          controller!,
                          child: isPaused
                              ? const Center(child: CircularProgressIndicator())
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Ink(
                    decoration: const ShapeDecoration(
                      color: Colors.lightBlue,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      onPressed: widget.closeOverlay,
                    ),
                  ),
                  Ink(
                    decoration: const ShapeDecoration(
                      color: Colors.lightBlue,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      color: Colors.white,
                      onPressed: () async {
                        if (controller!.value.isTakingPicture) {
                          return;
                        }

                        XFile file = await controller!.takePicture();
                        await controller!.pausePreview();
                        setState(() {
                          isPaused = true;
                        });

                        widget.onTakePicture(file);
                      },
                    ),
                  ),
                ],
              ),
            ]),
      ),
    );
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }

    final CameraController cameraController =
        CameraController(cameraDescription, ResolutionPreset.medium);

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Camera error ${cameraController.value.errorDescription}')));
      }
    });

    try {
      await cameraController.initialize();
      // The exposure mode is currently not supported on the web.

    } on CameraException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.code}\n${e.description}')));
    }

    if (mounted) {
      setState(() {});
    }
  }
}
