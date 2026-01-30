import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;

            final bool isCompactW = w < 380;
            final bool isShortH = h < 720;

            final double pagePad = isCompactW ? 16 : 24;
            final double gap = isShortH ? (isCompactW ? 10 : 12) : (isCompactW ? 12 : 16);

            final Widget content = Padding(
              padding: EdgeInsets.all(pagePad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: viewModel.refreshBluetoothConnection,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D1E33),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2E3350),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            viewModel.isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                            size: 20,
                            color: viewModel.isConnected ? const Color(0xFF00FF88) : const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    flex: isShortH ? 5 : 6,
                    child: _SongPanel(viewModel: viewModel),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    flex: isShortH ? 6 : 7,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final double controlsH = c.maxHeight;

                        final double throttleWidth = (isCompactW ? 110.0 : 120.0).clamp(96.0, 130.0).toDouble();

                        return Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _SteeringWheelControl(
                                  height: controlsH.clamp(220.0, 520.0).toDouble(),
                                  onValueChanged: (v) {
                                    viewModel.sendSteering(v);
                                  },
                                  onHornDown: viewModel.hornDown,
                                  onHornUp: viewModel.hornUp,
                                ),
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _BiThrottlePedal(
                                  height: controlsH.clamp(220.0, 520.0).toDouble(),
                                  width: throttleWidth,
                                  enabledForward: viewModel.isForwardThrottleEnabled,
                                  enabledBackward: viewModel.isBackwardThrottleEnabled,
                                  setForwardActive: viewModel.setForwardThrottleActive,
                                  setBackwardActive: viewModel.setBackwardThrottleActive,
                                  sendForward: viewModel.sendForwardThrottle,
                                  sendBackward: viewModel.sendBackwardThrottle,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );

            final bool needsScrollFallback = h < 620;

            if (!needsScrollFallback) return content;

            final double songH = (h * 0.46).clamp(220.0, 340.0).toDouble();
            final double controlsH = (h * 0.54).clamp(260.0, 520.0).toDouble();
            final double throttleWidth = (isCompactW ? 110.0 : 120.0).clamp(96.0, 130.0).toDouble();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(pagePad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: viewModel.refreshBluetoothConnection,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D1E33),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2E3350),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              viewModel.isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                              size: 20,
                              color: viewModel.isConnected ? const Color(0xFF00FF88) : const Color(0xFFFF6B6B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gap),
                    SizedBox(
                      height: songH,
                      child: _SongPanel(viewModel: viewModel),
                    ),
                    SizedBox(height: gap),
                    SizedBox(
                      height: controlsH,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _SteeringWheelControl(
                                height: controlsH,
                                onValueChanged: (v) {
                                  viewModel.sendSteering(v);
                                },
                                onHornDown: viewModel.hornDown,
                                onHornUp: viewModel.hornUp,
                              ),
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _BiThrottlePedal(
                                height: controlsH,
                                width: throttleWidth,
                                enabledForward: viewModel.isForwardThrottleEnabled,
                                enabledBackward: viewModel.isBackwardThrottleEnabled,
                                setForwardActive: viewModel.setForwardThrottleActive,
                                setBackwardActive: viewModel.setBackwardThrottleActive,
                                sendForward: viewModel.sendForwardThrottle,
                                sendBackward: viewModel.sendBackwardThrottle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gap),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();

  @override
  void onViewModelReady(HomeViewModel viewModel) {
    viewModel.initialize();
    super.onViewModelReady(viewModel);
  }
}

class _SongPanel extends StatelessWidget {
  const _SongPanel({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final songs = viewModel.songs;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2E3350),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Müzikler',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                InkWell(
                  onTap: viewModel.stopSong,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121427),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF2E3350),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.stop_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: viewModel.playSelectedSong,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121427),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF2E3350),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF00FF88),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (viewModel.isSongPlaying && viewModel.playingSongName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.equalizer_rounded,
                    color: Color(0xFF00FF88),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Çalıyor: ${viewModel.playingSongName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8D8E98),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF121427),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E3350),
                  width: 1,
                ),
              ),
              child: songs.isEmpty
                  ? const Center(
                child: Text(
                  'Liste boş. Yenileye basıp LIST iste.',
                  style: TextStyle(
                    color: Color(0xFF8D8E98),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: songs.length,
                itemBuilder: (context, i) {
                  final s = songs[i];
                  final selected = s.index == viewModel.selectedSongIndex;

                  return InkWell(
                    onTap: () => viewModel.setSelectedSongIndex(s.index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? const Color(0xFF00D9FF) : const Color(0xFF3D3E52),
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00D9FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${s.index}. ${s.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? Colors.white : const Color(0xFF8D8E98),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => viewModel.playSongByIndex(s.index),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D1E33),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF2E3350),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFF00FF88),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SteeringWheelControl extends StatefulWidget {
  const _SteeringWheelControl({
    required this.height,
    required this.onValueChanged,
    required this.onHornDown,
    required this.onHornUp,
  });

  final double height;
  final ValueChanged<double> onValueChanged;
  final VoidCallback onHornDown;
  final VoidCallback onHornUp;

  @override
  State<_SteeringWheelControl> createState() => _SteeringWheelControlState();
}

class _SteeringWheelControlState extends State<_SteeringWheelControl> with SingleTickerProviderStateMixin {
  static const double _maxAngleDeg = 55.0;
  static const double _deadZone = 0.04;

  static const Color _hornActiveColor = Color(0xFF00D9FF);

  late final AnimationController _snapController;

  double _value = 0.0;
  bool _dragging = false;

  double _snapStart = 0.0;
  bool _snapping = false;

  bool _hornPressed = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
      if (!_snapping) return;
      final double v = (_snapStart * (1.0 - _snapController.value)).clamp(-1.0, 1.0);
      setState(() {
        _value = v.abs() < _deadZone ? 0.0 : v;
      });
      widget.onValueChanged(_value);
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _setFromDx(double dx, double width) {
    final double half = (width / 2).clamp(1.0, double.infinity);
    double v = (dx / half).clamp(-1.0, 1.0);
    if (v.abs() < _deadZone) v = 0.0;

    setState(() {
      _value = v;
    });

    widget.onValueChanged(_value);
  }

  void _snapToCenter() {
    _dragging = false;

    _snapController.stop();
    _snapController.value = 0.0;

    _snapStart = _value;
    _snapping = true;

    _snapController.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _value = 0.0;
      });
      _snapping = false;
      widget.onValueChanged(0.0);
    });
  }

  void _hornDown() {
    if (_hornPressed) return;
    setState(() {
      _hornPressed = true;
    });
    widget.onHornDown();
  }

  void _hornUp() {
    if (!_hornPressed) return;
    setState(() {
      _hornPressed = false;
    });
    widget.onHornUp();
  }

  @override
  Widget build(BuildContext context) {
    final double maxAngleRad = (_maxAngleDeg * math.pi) / 180.0;

    return LayoutBuilder(
      builder: (context, c) {
        final double w = c.maxWidth;
        final double h = widget.height;

        final double wheelSize = math.min(w, h * 1.2).clamp(140.0, 340.0).toDouble();
        final double angle = (_value * maxAngleRad).clamp(-maxAngleRad, maxAngleRad);

        final Color hornColor = _hornPressed ? _hornActiveColor : Colors.white;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            _snapController.stop();
            _snapping = false;
            _dragging = true;
            final double dx = d.localPosition.dx - (w / 2);
            _setFromDx(dx, w);
          },
          onPanUpdate: (d) {
            if (!_dragging) return;
            final double dx = d.localPosition.dx - (w / 2);
            _setFromDx(dx, w);
          },
          onPanEnd: (_) => _snapToCenter(),
          onPanCancel: _snapToCenter,
          child: SizedBox(
            height: h,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1E33),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF2E3350),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 54,
                  height: 56,
                  child: Listener(
                    onPointerDown: (_) => _hornDown(),
                    onPointerUp: (_) => _hornUp(),
                    onPointerCancel: (_) => _hornUp(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hornColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.campaign_rounded,
                          color: hornColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -wheelSize / 2,
                  child: Transform.rotate(
                    angle: angle,
                    child: Image.asset(
                      'assets/images/steering.png',
                      width: wheelSize,
                      height: wheelSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 14,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_car_rounded,
                        color: Color(0xFF00D9FF),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _value == 0.0 ? 'Direksiyon' : (_value > 0 ? 'Sağ' : 'Sol'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121427),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E3350),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          ((_value.abs() * 100).round()).toString(),
                          style: const TextStyle(
                            color: Color(0xFF8D8E98),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _ThrottleDirection { up, down }

class _BiThrottlePedal extends StatefulWidget {
  const _BiThrottlePedal({
    required this.height,
    required this.width,
    required this.enabledForward,
    required this.enabledBackward,
    required this.setForwardActive,
    required this.setBackwardActive,
    required this.sendForward,
    required this.sendBackward,
  });

  final double height;
  final double width;

  final bool enabledForward;
  final bool enabledBackward;

  final ValueChanged<bool> setForwardActive;
  final ValueChanged<bool> setBackwardActive;

  final ValueChanged<int> sendForward;
  final ValueChanged<int> sendBackward;

  @override
  State<_BiThrottlePedal> createState() => _BiThrottlePedalState();
}

class _BiThrottlePedalState extends State<_BiThrottlePedal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double _progress = 0.0;
  bool _dragging = false;

  int _lastSentSigned = 999999;

  bool _isReleasing = false;
  double _releaseStartProgress = 0.0;

  bool get _enabled => widget.enabledForward || widget.enabledBackward;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
      if (!_isReleasing) return;
      final double p = (_releaseStartProgress * (1.0 - _controller.value)).clamp(-1.0, 1.0);
      setState(() {
        _progress = p;
      });
      _sendFromProgress();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendFromProgress() {
    final int signed = (_progress * 255).round().clamp(-255, 255);
    if (signed == _lastSentSigned) return;
    _lastSentSigned = signed;

    if (signed > 0) {
      widget.setBackwardActive(false);
      widget.sendBackward(0);
      widget.setForwardActive(true);
      widget.sendForward(signed);
    } else if (signed < 0) {
      widget.setForwardActive(false);
      widget.sendForward(0);
      widget.setBackwardActive(true);
      widget.sendBackward(signed.abs());
    } else {
      widget.setForwardActive(false);
      widget.setBackwardActive(false);
      widget.sendForward(0);
      widget.sendBackward(0);
    }
  }

  void _setProgressFromLocalDy(double localDy) {
    final double trackTop = widget.height < 240 ? 66 : 76;
    final double trackBottomPadding = widget.height < 240 ? 14 : 18;

    final double trackBottom = widget.height - trackBottomPadding;
    double dy = localDy;
    if (dy < trackTop) dy = trackTop;
    if (dy > trackBottom) dy = trackBottom;

    final double trackHeight = (widget.height - trackTop - trackBottomPadding).clamp(1.0, double.infinity);

    final double centerY = trackTop + (trackHeight / 2);
    final double half = trackHeight / 2;

    double v = (centerY - dy) / half;
    v = v.clamp(-1.0, 1.0);

    setState(() {
      _progress = v;
    });

    _sendFromProgress();
  }

  void _releaseToZero() {
    _dragging = false;

    widget.setForwardActive(false);
    widget.setBackwardActive(false);
    widget.sendForward(0);
    widget.sendBackward(0);
    _lastSentSigned = 0;

    _controller.stop();
    _controller.value = 0.0;

    _releaseStartProgress = _progress;
    _isReleasing = true;

    _controller.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _progress = 0.0;
      });
      _isReleasing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double trackTop = widget.height < 240 ? 66 : 76;
    final double trackBottomPadding = widget.height < 240 ? 14 : 18;

    final double thumbSize = widget.height < 240 ? 44 : 50;

    final double trackHeight = (widget.height - trackTop - trackBottomPadding).clamp(1.0, double.infinity);
    final double thumbTravel = (trackHeight - thumbSize).clamp(0.0, double.infinity);

    final double normalized = ((_progress + 1.0) / 2.0).clamp(0.0, 1.0);
    final double thumbTopInTrack = thumbTravel * (1.0 - normalized);

    final double centerLineY = trackTop + (trackHeight / 2);

    final int displayValue = (_progress * 255).round().clamp(-255, 255);

    final bool isForward = displayValue > 0;
    final bool isBackward = displayValue < 0;

    final String title = isForward
        ? 'İleri'
        : isBackward
        ? 'Geri'
        : '0';

    final IconData icon = isForward
        ? Icons.keyboard_arrow_up_rounded
        : isBackward
        ? Icons.keyboard_arrow_down_rounded
        : Icons.drag_handle_rounded;

    final double thumbCenterY = trackTop + thumbTopInTrack + (thumbSize / 2);
    final double activeFillTop = math.min(thumbCenterY, centerLineY);
    final double activeFillHeight = (math.max(thumbCenterY, centerLineY) - activeFillTop);

    return IgnorePointer(
      ignoring: !_enabled,
      child: Opacity(
        opacity: _enabled ? 1.0 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            if (!_enabled) return;
            _controller.stop();
            _isReleasing = false;
            _dragging = true;
            _setProgressFromLocalDy(d.localPosition.dy);
          },
          onPanUpdate: (d) {
            if (!_dragging) return;
            _setProgressFromLocalDy(d.localPosition.dy);
          },
          onPanEnd: (_) => _releaseToZero(),
          onPanCancel: _releaseToZero,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF2E3350),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  right: 12,
                  top: 10,
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        color: const Color(0xFF00D9FF),
                        size: widget.height < 240 ? 32 : 36,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.height < 240 ? 12 : 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF8D8E98),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Positioned(
                  left: (widget.width - 34) / 2,
                  top: trackTop,
                  bottom: trackBottomPadding,
                  child: Stack(
                    children: [
                      Container(
                        width: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFF3D3E52),
                            width: 2,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF2E3350),
                              Color(0xFF121427),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: centerLineY - trackTop,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D3E52).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 2,
                        right: 2,
                        top: (activeFillTop - trackTop).clamp(0.0, trackHeight),
                        height: activeFillHeight.clamp(0.0, trackHeight),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  const Color(0xFF00D9FF).withOpacity(0.85),
                                  const Color(0xFF00FF88).withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: (widget.width - thumbSize) / 2,
                  top: trackTop + thumbTopInTrack,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3D3E52),
                          Color(0xFF1D1E33),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF00D9FF),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D9FF).withOpacity(0.25),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        displayValue.abs().toString(),
                        style: TextStyle(
                          fontSize: widget.height < 240 ? 11 : 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: widget.height < 240 ? 8 : 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: 0,
                        child: const Icon(
                          Icons.expand_less_rounded,
                          color: Color(0xFF3D3E52),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Transform.rotate(
                        angle: math.pi,
                        child: const Icon(
                          Icons.expand_less_rounded,
                          color: Color(0xFF3D3E52),
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
