import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/moonjoin/motion/moonjoin_motion.dart';
import 'package:moonjoin/common/widgets/moonjoin/motion/moonjoin_motion_painters.dart';

/// THE official MoonJoin status animation — the single reusable widget for every
/// animated status across the platform. Give it a [MoonJoinMotionState]; it renders
/// the approved moon at that phase and performs the **Arc-Light** reveal once
/// (Node appears → Arc-Light travels the rim → Moon resolves → calm settle), then
/// holds still — except the two genuinely-active states (Preparing, On the way),
/// which carry one refined ongoing motion. No rotation, no loop, no loader.
class MoonJoinStatusAnimation extends StatefulWidget {
  final MoonJoinMotionState state;
  final double size;
  /// When false the reveal/ambient hold their current frame (e.g. offscreen).
  final bool play;
  const MoonJoinStatusAnimation({super.key, required this.state, this.size = 56, this.play = true});

  @override
  State<MoonJoinStatusAnimation> createState() => _MoonJoinStatusAnimationState();
}

class _MoonJoinStatusAnimationState extends State<MoonJoinStatusAnimation> with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _ambient;
  late MoonJoinMoonSpec _spec;

  @override
  void initState() {
    super.initState();
    _spec = MoonJoinMotion.spec(widget.state);
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
    _ambient = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _start();
  }

  void _start() {
    if (!widget.play) {
      _reveal.stop();
      _ambient.stop();
      return;
    }
    _reveal.forward(from: 0);
    if (_spec.ambient != MoonAmbient.none) {
      _ambient.repeat();
    } else {
      _ambient.stop();
    }
  }

  @override
  void didUpdateWidget(covariant MoonJoinStatusAnimation old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _spec = MoonJoinMotion.spec(widget.state);
      _start();
    } else if (old.play != widget.play) {
      _start();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MoonJoinMotionPalette.of(context);
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_reveal, _ambient]),
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: MoonJoinMoonPainter(
              spec: _spec,
              reveal: _reveal.value,
              ambient: _ambient.value,
              palette: palette,
            ),
          ),
        ),
      ),
    );
  }
}
