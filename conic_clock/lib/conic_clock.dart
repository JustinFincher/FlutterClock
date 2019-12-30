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
  var _weather = '';
  var _time = '';
  var _halfDay = false;
  Timer _timer;

//  Color lightColor = Color(0xffAAD6C3);
//  Color midColor = Color(0xff044B72);
//  Color darkColor = Color(0xff021226);
  Color lightColor = Color(0xffD6AABB);
  Color midColor = Color(0xff5798FF);
  Color darkColor = Color(0xffFF007A);

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
      _halfDay = !widget.model.is24HourFormat;
      _weather = '${widget.model.temperatureString} (${widget.model.low}-${widget.model.high})' + '\n' + widget.model.weatherString.toUpperCase();
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      _location = DateFormat.MMMd().format(_now) + '\n' + widget.model.location;
      _time = _halfDay ? DateFormat("hh:mm a").format(_now) : DateFormat("HH:mm").format(_now);
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
        subhead: textTheme.subhead.copyWith(
            fontFamily: "IBM Plex Sans Condensed",
            fontSize: 100,
            letterSpacing: 6,
            fontWeight: FontWeight.w100,
            fontStyle: FontStyle.italic,
            color: Colors.white
        ),
        caption: textTheme.caption.copyWith(
            fontFamily: "IBM Plex Mono",
            fontSize: 40,
            fontWeight: FontWeight.w100,
            letterSpacing: 3,
            fontStyle: FontStyle.italic,
            color: Colors.white
        )
    );

    final secondsRadialRotation = (_now.second * 1000.0 + _now.millisecond) * radiansPerMilliSeconds - radians(90);
    final cityOpacity = (cos((_now.second * 1000.0 + _now.millisecond) * radiansPerMilliSeconds + radians(180)) + 1) / 2.0;


    return Semantics.fromProperties(
        properties: SemanticsProperties(
          label: 'Analog clock with time $time',
          value: time,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [lightColor.withAlpha(255), midColor.withAlpha(255), darkColor.withAlpha(255)],
                    stops: [0.0 + cityOpacity * 0.0001, 0.5, 1],
                    transform: GradientRotation(secondsRadialRotation),
                  )
              ),
              child: new Stack(children: <Widget>
              [
                Positioned(
                    child:
                    ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return SweepGradient(
                            colors: [darkColor.withAlpha(255),Color(0x00000000),Color(0x00000000),lightColor.withAlpha(255)],
                            stops: [0.0, 0.2, 0.8, 1],
                            transform: GradientRotation(secondsRadialRotation),
                          ).createShader(Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight));
                        },
                        child: Container(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: Stack(children: <Widget>[
                              Positioned(
                                bottom:0,
                                left: 0,
                                right: 0,
                                child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(_location, textAlign: TextAlign.left, style: textTheme.caption)
                                ),
                              ),
                              Positioned(
                                top:0,
                                right: 0,
                                child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(_weather, textAlign: TextAlign.right, style: textTheme.caption),
                                )
                              ),
                            ],
                            )
                        )
                    )
                ),
                Positioned(
                    child:
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                        shaderCallback: (Rect bounds) {
                          return SweepGradient(
                            colors: [darkColor.withAlpha(255),Color(0x00000000),Color(0x00000000),lightColor.withAlpha(255)],
                            stops: [0.1, 0.3, 0.7, 0.9],
                            transform: GradientRotation(secondsRadialRotation),
                          ).createShader(Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight));
                        },
                        child: Container(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: Stack(children: <Widget>[
                              Positioned(
                                top:0,
                                left: 0,
                                child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(_time, textAlign: TextAlign.left, style: textTheme.subhead)
                                ),
                              ),
                              Positioned(
                                bottom:0,
                                right: 0,
                                child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(_time, textAlign: TextAlign.right, style: textTheme.subhead)
                                ),
                              ),
                            ],
                            )
                        )
                    )
                ),
//                Positioned(
//                    child:
//                    ShaderMask(
//                        shaderCallback: (Rect bounds) {
//                          return SweepGradient(
//                            colors: [Color(0x00AAD6C3),Color(0xFFFFFFFF),Color(0xFFFFFFFF),Color(0x00021226)],
//                            stops: [0.05, 0.35, 0.65, 0.95],
//                            transform: GradientRotation(secondsRadialRotation),
//                          ).createShader(Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight));
//                        },
//                        child: Container(
//                            width: constraints.maxWidth,
//                            height: constraints.maxHeight,
//                            child: Stack(children: <Widget>[
//                              Center(child: Text(_time, textAlign: TextAlign.center, style: textTheme.title))
//                            ],
//                            )
//                        )
//                    )
//                ),
              ],
              ),
            );
          },
        )
    );
  }
}
