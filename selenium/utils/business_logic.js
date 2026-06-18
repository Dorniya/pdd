/**
 * Pure JavaScript implementation of dashboard metrics logic to facilitate isolated unit testing.
 */

/**
 * Calculates current consecutive day streak based on history session dates.
 * @param {Array<string>} dates Array of ISO date strings representing daily sessions.
 * @returns {number} The streak in days.
 */
function calculateStreak(dates) {
  if (!dates || dates.length === 0) return 0;
  
  // Parse and sort unique dates in descending order (newest first)
  const uniqueDates = [...new Set(dates)]
    .map(d => new Date(d).toDateString())
    .map(dStr => new Date(dStr))
    .sort((a, b) => b - a);

  const today = new Date();
  const yesterday = new Date();
  yesterday.setDate(today.getDate() - 1);
  
  const newest = uniqueDates[0];
  const newestStr = newest.toDateString();
  
  // Streak is 0 if newest session is older than yesterday
  if (newestStr !== today.toDateString() && newestStr !== yesterday.toDateString()) {
    return 0;
  }
  
  let streak = 1;
  let currentRef = newest;
  
  for (let i = 1; i < uniqueDates.length; i++) {
    const nextDate = uniqueDates[i];
    const diffTime = Math.abs(currentRef - nextDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays === 1) {
      streak++;
      currentRef = nextDate;
    } else if (diffDays > 1) {
      break; // Streak broken
    }
    // If diffDays is 0 (same day), ignore and continue
  }
  
  return streak;
}

/**
 * Calculates the average accuracy of AI pose alignment across all completed sessions.
 * @param {Array<number>} accuracies Array of percentage accuracy integers.
 * @returns {number} Rounded average accuracy percentage.
 */
function calculateAverageAccuracy(accuracies) {
  if (!accuracies || accuracies.length === 0) return 0;
  const sum = accuracies.reduce((total, val) => total + val, 0);
  return Math.round(sum / accuracies.length);
}

/**
 * Formats a duration in seconds to a human-readable duration string.
 * @param {number} totalSeconds Total elapsed seconds.
 * @returns {string} Formatted duration (e.g., '05:30' or '01:15:00').
 */
function formatDuration(totalSeconds) {
  if (totalSeconds === null || totalSeconds === undefined || totalSeconds < 0) return '00:00';
  
  const hrs = Math.floor(totalSeconds / 3600);
  const mins = Math.floor((totalSeconds % 3600) / 60);
  const secs = Math.floor(totalSeconds % 60);
  
  const pad = (num) => num.toString().padStart(2, '0');
  
  if (hrs > 0) {
    return `${pad(hrs)}:${pad(mins)}:${pad(secs)}`;
  }
  return `${pad(mins)}:${pad(secs)}`;
}

/**
 * Calculates BMI from weight and height.
 */
function calculateBMI(weightKg, heightCm) {
  if (!weightKg || !heightCm || weightKg <= 0 || heightCm <= 0) return 0;
  const heightM = heightCm / 100;
  const bmi = weightKg / (heightM * heightM);
  return parseFloat(bmi.toFixed(1));
}

/**
 * Classifies BMI into status ranges.
 */
function classifyBMI(bmi) {
  if (bmi <= 0) return 'Unknown';
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
}

/**
 * Classifies Blood Pressure based on systolic and diastolic values.
 */
function classifyBP(systolic, diastolic) {
  if (!systolic || !diastolic || systolic <= 0 || diastolic <= 0) return 'Unknown';
  
  if (systolic > 180 || diastolic > 120) {
    return 'Hypertensive Crisis';
  }
  if (systolic >= 140 || diastolic >= 90) {
    return 'Stage 2 Hypertension';
  }
  if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) {
    return 'Stage 1 Hypertension';
  }
  if (systolic >= 120 && systolic < 130 && diastolic < 80) {
    return 'Elevated';
  }
  if (systolic < 120 && diastolic < 80) {
    return 'Normal';
  }
  return 'Stage 1 Hypertension'; // general fallback
}

/**
 * Calculates calorie burn based on weight, duration, and yoga intensity.
 */
function calculateCalorieBurn(weightKg, durationMinutes, intensity = 'medium') {
  if (!weightKg || !durationMinutes || weightKg <= 0 || durationMinutes <= 0) return 0;
  
  const metFactors = {
    'low': 2.5,
    'medium': 3.5,
    'high': 5.0
  };
  
  const met = metFactors[intensity.toLowerCase()] || 3.5;
  // standard MET formula: Calories = MET * 3.5 * weightKg / 200 * durationMinutes
  const calories = met * 3.5 * weightKg * durationMinutes / 200;
  return Math.round(calories);
}

module.exports = {
  calculateStreak,
  calculateAverageAccuracy,
  formatDuration,
  calculateBMI,
  classifyBMI,
  classifyBP,
  calculateCalorieBurn
};
