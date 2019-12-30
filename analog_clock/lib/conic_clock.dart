// Copyright 2020 Zheng Haotian. All rights reserved.

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

final radiansPerMilliSeconds = radians(360 / 60000);
final radiansPerHours = radians(360 / 12);

class ConicClock extends StatefulWidget {
  const ConicClock(this.model);

  final ClockModel model;

  @override
  _ConicClockState createState() => _ConicClockState();
}

class _ConicClockState extends State<ConicClock> {
  var _now = DateTime.now();
  var _location = '';
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(ConicClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      _timer = Timer(
        Duration(milliseconds: 30),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    final time = DateFormat.Hms().format(DateTime.now());

    TextTheme textTheme = Theme.of(context).textTheme;
    textTheme = textTheme.copyWith(
        body1: textTheme.body1.copyWith(fontFamily: "IBM Plex Mono"),
        caption: textTheme.caption.copyWith
          (
            fontFamily: "IBM Plex Mono",
            fontSize: 40,
            fontWeight: FontWeight.w100,
            letterSpacing: 3,
            fontStyle: FontStyle.italic
        )
    );

    List<Color> colors = [Color(0xffAAD6C3),Color(0xff044B72),Color(0xff021226)];
    List<Color> colorsReversed = [Color(0xff021226),Color(0xff044B72),Color(0xffAAD6C3)];

    final secondsRadialRotation = (_now.second * 1000.0 + _now.millisecond) * radiansPerMilliSeconds - radians(90);
    final hoursRadialRotation = (_now.hour) * radiansPerHours - radians(90);
    final cityOpacity = (cos((_now.second * 1000.0 + _now.millisecond) * radiansPerMilliSeconds + radians(180)) + 1) / 2.0;


    return Semantics.fromProperties(
        properties: SemanticsProperties(
          label: 'Analog clock with time $time',
          value: time,
        ),
        child:
        Container(
          // Add box decoration
          decoration: BoxDecoration(
            // Box decoration takes a gradient
              gradient: SweepGradient(
                  colors: colors,
                  stops: [0.0, 0.5, 1],
                  transform: GradientRotation(secondsRadialRotation),
                  startAngle: secondsRadialRotation * 0.000000000000001
              )
          ),
          child: new Stack(children: <Widget>[
//            BackdropFilter(
//              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
//              child: Container(
//                color: Colors.black.withOpacity(0),
//              ),
//            ),
            Positioned(
              child:
              ShaderMask(
                  blendMode: BlendMode.srcIn,  // Add this
                  shaderCallback: (Rect bounds) {
                    return SweepGradient(
                        colors:colorsReversed,
                        stops: [0.0, 0.5, 1],
                        transform: GradientRotation(secondsRadialRotation),
                        startAngle: secondsRadialRotation * 0.000000000000001
                    ).createShader(bounds);
                  },
                  child: Stack(children: <Widget>[
                    Positioned(
                      bottom:0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Opacity(child: Text(_location, textAlign: TextAlign.center, style: textTheme.caption), opacity: cityOpacity)
                      ),
                    )
                  ],)
              ),
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,),
          ],
          ),
        )
    );
  }
}
