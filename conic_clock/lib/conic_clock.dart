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
  var _lightYearMode = false; // debug flag to see fast time lapse
  Timer _timer;

  Color _lightColor = Color(0xffAAD6C3); // sun/moon color
  Color _midColor = Color(0xff044B72);  // sky color
  Color _darkColor = Color(0xff021226); // ground color

  double _weatherColorOffsetH = 0;
  double _weatherColorOffsetS = 0;
  double _weatherColorOffsetV = 0;

  double _weatherColorOffsetTargetH = 0;
  double _weatherColorOffsetTargetS = 0;
  double _weatherColorOffsetTargetV = 0;

  double _tempColorOffsetS = 0;
  double _tempColorOffsetTargetS = 0;

//  Color lightColor = Color(0xffD6AABB);
//  Color midColor = Color(0xff5798FF);
//  Color darkColor = Color(0xffFF007A);

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
      
      switch(widget.model.weatherCondition)
      {
        case WeatherCondition.cloudy:
          _weatherColorOffsetTargetH = 0;
          _weatherColorOffsetTargetS = -0.2;
          _weatherColorOffsetTargetV = -0.1;
          break;
        case WeatherCondition.foggy:
          _weatherColorOffsetTargetH = 0;
          _weatherColorOffsetTargetS = -0.1;
          _weatherColorOffsetTargetV = 0;
          break;
        case WeatherCondition.rainy:
          _weatherColorOffsetTargetH = 0;
          _weatherColorOffsetTargetS = 0.2;
          _weatherColorOffsetTargetV = -0.2;
          break;
        case WeatherCondition.snowy:
          _weatherColorOffsetTargetH = 0;
          _weatherColorOffsetTargetS = -0.6;
          _weatherColorOffsetTargetV = 0.1;
          break;
        case WeatherCondition.sunny:
          _weatherColorOffsetTargetH = 0;
          _weatherColorOffsetTargetS = 0.4;
          _weatherColorOffsetTargetV = 0.3;
          break;
        case WeatherCondition.thunderstorm:
          _weatherColorOffsetTargetH = 0.1;
          _weatherColorOffsetTargetS = 0.4;
          _weatherColorOffsetTargetV = -0.8;
          break;
        case WeatherCondition.windy:
          _weatherColorOffsetTargetH = 0.05;
          _weatherColorOffsetTargetS = -0.1;
          _weatherColorOffsetTargetV = 0;
          break;
      }

      double currentTemp = 0;
      switch (widget.model.unit)
      {
        case TemperatureUnit.celsius:
          currentTemp = widget.model.temperature;
          break;
        case TemperatureUnit.fahrenheit:
          currentTemp = (widget.model.temperature - 32.0) * 5.0 / 9.0;
          break;
      }
      _tempColorOffsetTargetS = atan(currentTemp - 10.0) / radians(90) * 0.1;
    });
  }

  double _checkColorH(double h)
  {
    return min(max(0,h),360);
  }
  double _checkColorS(double h)
  {
    return min(max(0,h),1);
  }
  double _checkColorV(double h)
  {
    return min(max(0,h),1);
  }

  void _updateTime() {
    setState(() {
      _now = !_lightYearMode ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch((DateTime.now().millisecondsSinceEpoch * 4000).toInt());
      double dayProgress = (_now.hour * 60*60*1000 + _now.minute * 60*1000 + _now.second * 1000 + _now.millisecond) / (24*60*60*1000);
      //                0 midnight - 0.25 sunrise - 0.5 noon - 0.75 sunset - 1 midnight
      // sun/moon color pale green - pale yellow - pale red - pale pink - pale blue : pale color, weak
      // sky color      mid cyan - mid orange - pale blue - mid orange - mid cyan : vibrant color, primary
      // ground color   dark blue - mid red - light white - mid red - dark blue : bold color, contrast

      // weather & temp effect
      //  cloudy,      H= S- V-
      //  foggy,       H= S- V=
      //  rainy,       H= S+ V-
      //  snowy,       H= S- V+
      //  sunny,       H= S+ V+
      //  thunderstorm,H+ S+ V-
      //  windy,       H+ S- V=
      //
      //  temp up S+
      //  temp down S-

      _weatherColorOffsetH = lerpDouble(_weatherColorOffsetH, _weatherColorOffsetTargetH, 0.001);
      _weatherColorOffsetS = lerpDouble(_weatherColorOffsetS, _weatherColorOffsetTargetS, 0.001);
      _weatherColorOffsetV = lerpDouble(_weatherColorOffsetV, _weatherColorOffsetTargetV, 0.001);

      _tempColorOffsetS = lerpDouble(_tempColorOffsetS, _tempColorOffsetTargetS, 0.001);

      double lightColorH = _checkColorH((cos(dayProgress * radians(360) + _weatherColorOffsetH)) * 360.0);
      double lightColorS = _checkColorS(0.15 + (sin(dayProgress * radians(360)) + _weatherColorOffsetS + _tempColorOffsetS) * 0.1);
      double lightColorV = _checkColorV(0.7 + 0.3 * (sin(dayProgress * radians(180)) + _weatherColorOffsetV));

      double midColorH = _checkColorH((sin(dayProgress * radians(1080)) + _weatherColorOffsetH) * 30.0 + 230);
      double midColorS = _checkColorS(0.7 + 0.2 * (sin(dayProgress * radians(720)) + _weatherColorOffsetS + _tempColorOffsetS));
      double midColorV = _checkColorV(0.7 + 0.2 * (sin(dayProgress * radians(180)) + _weatherColorOffsetV));

      double darkColorH = _checkColorH(((cos(dayProgress * radians(360)) * 0.5 + 0.2) % 1.0 + _weatherColorOffsetH) * 360.0);
      double darkColorS = _checkColorS(0.8 + _weatherColorOffsetS + _tempColorOffsetS);
      double darkColorV = _checkColorV(0.25 + 0.2 * (sin(dayProgress * radians(720)) + _weatherColorOffsetV));

      _lightColor = HSVColor.fromAHSV(1.0,lightColorH, lightColorS, lightColorV).toColor();
      _midColor = HSVColor.fromAHSV(1.0,midColorH, midColorS, midColorV).toColor();
      _darkColor = HSVColor.fromAHSV(1.0,darkColorH, darkColorS, darkColorV).toColor();

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
            fontSize: 120,
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

    final radialRotation = _lightYearMode ? (DateTime.now().second * 1000.0 + DateTime.now().millisecond) * radiansPerMilliSeconds - radians(90) : (_now.second * 1000.0 + _now.millisecond) * radiansPerMilliSeconds - radians(90);
    final radialRotationSin = sin(radialRotation);


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
                    colors: [_lightColor.withAlpha(255), _midColor.withAlpha(255), _darkColor.withAlpha(255)],
                    stops: [0.0 + radialRotationSin * 0.0001, 0.5, 1],
                    transform: GradientRotation(radialRotation),
                  )
              ),
              child: new Stack(children: <Widget>
              [
                Positioned(
                    child:
                    ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return SweepGradient(
                            colors: [_darkColor.withAlpha(255),Color(0x00000000),Color(0x00000000),_lightColor.withAlpha(255)],
                            stops: [0.0, 0.2, 0.8, 1],
                            transform: GradientRotation(radialRotation),
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
                            colors: [_darkColor.withAlpha(255),Color(0x00000000),Color(0x00000000),_lightColor.withAlpha(255)],
                            stops: [0.1, 0.3, 0.7, 0.9],
                            transform: GradientRotation(radialRotation),
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
              ],
              ),
            );
          },
        )
    );
  }
}
