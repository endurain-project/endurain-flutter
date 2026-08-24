/// A flat run-in, a 100 m climb, then a flat run-out, starting at [base].
///
/// Elevation gain is smoothed with a 6-wide median filter and a 3-wide moving
/// average before deltas are summed (mirroring the Endurain backend), so a
/// fixture needs enough samples for a real ascent to survive the filters.
/// This profile yields exactly [climbElevationGainMeters].
List<double> climbElevationProfile({double base = 100}) => <double>[
  ...List<double>.filled(10, base),
  for (var step = 1; step <= 10; step += 1) base + step * 10,
  ...List<double>.filled(10, base + 100),
];

/// Total ascent that [climbElevationProfile] reports after smoothing.
const double climbElevationGainMeters = 100;
