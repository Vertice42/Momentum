import 'dart:math';
import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DrawWave extends CustomPainter {
  int captureSize;
  int wavesize;
  List<int> wave;

  DrawWave(List wave, int wavesize) {
    this.wavesize = wavesize;
    this.captureSize = wave.length;
    this.wave = wave;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (wave.length < 2) return;

    double height = size.height / 2.3;
    //Starts painting in the middle of the screen//??

    double spacing = size.width / captureSize;
    //"spacing" determining the line spacing is by consequence the size of the sound wave

    var paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    //activates anti aliasing and sets the thickness of the line

    double startLineW = 0, endLineW = spacing;
    //Initialise Lines
    int effectSpacing = new Random().nextInt(3);
    int alpha = 0;
    //Randomize the space between lines to create the color
    for (int i = 1; i < captureSize; i++) {
      //AlphaMultiplier defines the size of the opaque trace
      int alphaMultiplier = 5;
      if (i <= captureSize / 2) {
        alpha += alphaMultiplier;
      } else {
        alpha -= alphaMultiplier;
      }
      //add an increasing opacity effect
      double startLineH, endLineH;
      startLineH = wave[i - 1].toDouble() / 10;
      endLineH = wave[i].toDouble();
      if (startLineH < 0) startLineH = startLineH * -1;
      if (endLineH < 0) endLineH = endLineH * -1;
      //these lines cancel negative waves
      startLineH = height + startLineH;
      endLineH = height + endLineH;
      //decreases the amplitude of the sound wave
      int alphaMain = alpha;
      if (alphaMain > 200) alphaMain = 200;
      int alphaEffect = alphaMain ~/ 2;
      if (alphaEffect < 0) alphaMain = 0;
      //put a limit on the alpha value
      paint.color = Color.fromARGB(alphaEffect, 0, 250, 250);
      canvas.drawLine(
          Offset(startLineW + effectSpacing, startLineH + effectSpacing),
          Offset(endLineW + effectSpacing, endLineH + effectSpacing),
          paint);
      //Blue Line
      paint.color = Color.fromARGB(alphaEffect, 250, 0, 0);
      canvas.drawLine(
          Offset(startLineW - effectSpacing, startLineH - effectSpacing),
          Offset(endLineW - effectSpacing, endLineH - effectSpacing),
          paint);
      //Read Line
      paint.color = Color.fromARGB(alphaMain, 0, 0, 0);
      canvas.drawLine(
          Offset(startLineW, startLineH), Offset(endLineW, endLineH), paint);
      //white main line
      startLineW += spacing;
      endLineW += spacing;
      //advances to the next wave point

      if (i % 48 == 0) {
        developer.log((i % 48 == 0).toString());
        canvas.drawLine(Offset(startLineW, 0), Offset(startLineW, 10), paint);
        TextSpan span = new TextSpan(
            style: new TextStyle(
                color: Colors.blue[800], fontSize: 10, fontFamily: 'Roboto'),
            text: (i / 48).toString());
        TextPainter tp =
            new TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, new Offset(startLineW, 0.0));
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
