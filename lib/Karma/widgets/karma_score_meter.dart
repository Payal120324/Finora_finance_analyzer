import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class KarmaScoreMeter extends StatelessWidget {
  final int score;
  const KarmaScoreMeter({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    Color c;
    String emoji;
    if (score >= 80) {
      c = Colors.green;
      emoji = '😃';
    } else if (score >= 50) {
      c = Colors.orange;
      emoji = '🙂';
    } else {
      c = Colors.red;
      emoji = '😟';
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: SfRadialGauge(
            axes: [
              RadialAxis(
                minimum: 0,
                maximum: 100,
                showLabels: false,
                showTicks: false,
                axisLineStyle: AxisLineStyle(
                  thickness: .15,
                  thicknessUnit: GaugeSizeUnit.factor,
                  cornerStyle: CornerStyle.bothCurve,
                  color: c.withOpacity(.3),
                ),
                pointers: [
                  RangePointer(
                    value: score.toDouble(),
                    width: .15,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: c,
                    cornerStyle: CornerStyle.bothCurve,
                  )
                ],
                annotations: [
                  GaugeAnnotation(
                    widget: Text('$emoji\n$score',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    angle: 90,
                    positionFactor: .1,
                  )
                ],
              )
            ],
          ),
        ),
        Text(
          score >= 80 ? 'Healthy' : score >= 50 ? 'Improving' : 'At Risk',
          style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w600),
        )
      ],
    );
  }
}
