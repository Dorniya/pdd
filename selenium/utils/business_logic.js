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

/**
 * Validates an email address format.
 * @param {string} email
 * @returns {boolean}
 */
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email.trim());
}

/**
 * Validates a password meets minimum strength requirements.
 * @param {string} password
 * @returns {{ valid: boolean, reasons: string[] }}
 */
function validatePassword(password) {
  const reasons = [];
  if (!password || typeof password !== 'string') return { valid: false, reasons: ['Password is required'] };
  if (password.length < 8) reasons.push('Too short (min 8 chars)');
  if (!/[A-Z]/.test(password)) reasons.push('Missing uppercase letter');
  if (!/[0-9]/.test(password)) reasons.push('Missing digit');
  return { valid: reasons.length === 0, reasons };
}

/**
 * Calculates age in full years from a date of birth string.
 * @param {string} dob ISO date string
 * @returns {number}
 */
function calculateAge(dob) {
  if (!dob) return 0;
  const birth = new Date(dob);
  if (isNaN(birth)) return 0;
  const today = new Date();
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age < 0 ? 0 : age;
}

/**
 * Validates blood pressure string format "systolic/diastolic".
 * @param {string} bp
 * @returns {boolean}
 */
function isValidBloodPressure(bp) {
  if (!bp || typeof bp !== 'string') return false;
  const match = bp.match(/^(\d{2,3})\/(\d{2,3})$/);
  if (!match) return false;
  const sys = parseInt(match[1]);
  const dia = parseInt(match[2]);
  return sys >= 60 && sys <= 260 && dia >= 30 && dia <= 160;
}

/**
 * Parses a blood pressure string into systolic and diastolic values.
 * @param {string} bp e.g. "120/80"
 * @returns {{ systolic: number, diastolic: number } | null}
 */
function parseBloodPressure(bp) {
  if (!isValidBloodPressure(bp)) return null;
  const parts = bp.split('/');
  return { systolic: parseInt(parts[0]), diastolic: parseInt(parts[1]) };
}

/**
 * Clamps a value between a min and max.
 * @param {number} value
 * @param {number} min
 * @param {number} max
 * @returns {number}
 */
function clamp(value, min, max) {
  if (value === null || value === undefined || isNaN(value)) return min;
  return Math.min(Math.max(value, min), max);
}

/**
 * Normalizes an accuracy value to the range [0, 100].
 * @param {number} value
 * @returns {number}
 */
function normalizeAccuracy(value) {
  return clamp(Math.round(value), 0, 100);
}

/**
 * Calculates progress percentage from current and total values.
 * @param {number} current
 * @param {number} total
 * @returns {number} Rounded percentage (0-100)
 */
function calculateProgressPercentage(current, total) {
  if (!total || total <= 0) return 0;
  if (current <= 0) return 0;
  return Math.min(100, Math.round((current / total) * 100));
}

/**
 * Determines a yoga skill level label based on total sessions completed.
 * @param {number} sessions
 * @returns {string}
 */
function getYogaLevel(sessions) {
  if (!sessions || sessions < 0) return 'Beginner';
  if (sessions < 5) return 'Beginner';
  if (sessions < 20) return 'Intermediate';
  if (sessions < 50) return 'Advanced';
  return 'Expert';
}

/**
 * Formats a calorie count for display.
 * @param {number} calories
 * @returns {string}
 */
function formatCalories(calories) {
  if (calories === null || calories === undefined || isNaN(calories) || calories < 0) return '0 kcal';
  if (calories >= 1000) {
    return `${(calories / 1000).toFixed(1)}k kcal`;
  }
  return `${Math.round(calories)} kcal`;
}

/**
 * Validates a resting heart rate value (normal range 30-220 bpm).
 * @param {number} hr
 * @returns {boolean}
 */
function isValidHeartRate(hr) {
  if (hr === null || hr === undefined || isNaN(hr)) return false;
  return hr >= 30 && hr <= 220;
}

/**
 * Calculates Basal Metabolic Rate using Mifflin-St Jeor equation.
 * @param {number} weightKg
 * @param {number} heightCm
 * @param {number} age
 * @param {string} gender 'male' or 'female'
 * @returns {number} BMR in kcal/day (rounded)
 */
function calculateBMR(weightKg, heightCm, age, gender) {
  if (!weightKg || !heightCm || !age || weightKg <= 0 || heightCm <= 0 || age <= 0) return 0;
  let bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
  if (gender === 'male') {
    bmr += 5;
  } else if (gender === 'female') {
    bmr -= 161;
  } else {
    return 0; // Unknown gender
  }
  return Math.round(bmr);
}

/**
 * Calculates the number of days between two ISO date strings.
 * @param {string} date1
 * @param {string} date2
 * @returns {number} Absolute number of days between dates
 */
function daysBetween(date1, date2) {
  if (!date1 || !date2) return 0;
  const d1 = new Date(date1);
  const d2 = new Date(date2);
  if (isNaN(d1) || isNaN(d2)) return 0;
  const diffMs = Math.abs(d2 - d1);
  return Math.round(diffMs / (1000 * 60 * 60 * 24));
}

/**
 * Generates a unique session ID string (timestamp-based).
 * @returns {string}
 */
function generateSessionId() {
  return `session_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

/**
 * Determines if a weight in kg is within a healthy BMI range for the given height.
 * @param {number} weightKg
 * @param {number} heightCm
 * @returns {boolean}
 */
function isHealthyWeight(weightKg, heightCm) {
  const bmi = calculateBMI(weightKg, heightCm);
  return bmi >= 18.5 && bmi < 25;
}

/**
 * Formats a large number as an abbreviated string (e.g. 1200 -> "1.2k").
 * @param {number} value
 * @returns {string}
 */
function formatLargeNumber(value) {
  if (value === null || value === undefined || isNaN(value)) return '0';
  if (value < 0) return '0';
  if (value >= 1000000) return `${(value / 1000000).toFixed(1)}M`;
  if (value >= 1000) return `${(value / 1000).toFixed(1)}k`;
  return `${Math.round(value)}`;
}

/**
 * Calculates total minutes from an array of session duration objects { durationSeconds }.
 * @param {Array<{durationSeconds: number}>} sessions
 * @returns {number}
 */
function calculateTotalMinutes(sessions) {
  if (!sessions || sessions.length === 0) return 0;
  const totalSeconds = sessions.reduce((sum, s) => sum + (s.durationSeconds || 0), 0);
  return Math.round(totalSeconds / 60);
}

/**
 * Returns the most recent date from an array of ISO date strings.
 * @param {string[]} dates
 * @returns {string|null}
 */
function getMostRecentDate(dates) {
  if (!dates || dates.length === 0) return null;
  const valid = dates.map(d => new Date(d)).filter(d => !isNaN(d));
  if (valid.length === 0) return null;
  const latest = new Date(Math.max(...valid));
  return latest.toISOString();
}

/**
 * Converts blood sugar from mg/dL to mmol/L.
 * @param {number} mgdl
 * @returns {number}
 */
function mgdlToMmol(mgdl) {
  if (!mgdl || mgdl <= 0) return 0;
  return parseFloat((mgdl / 18.0182).toFixed(1));
}

/**
 * Classifies blood sugar level.
 * @param {number} mgdl
 * @returns {string}
 */
function classifyBloodSugar(mgdl) {
  if (!mgdl || mgdl <= 0) return 'Unknown';
  if (mgdl < 70) return 'Low';
  if (mgdl <= 99) return 'Normal';
  if (mgdl <= 125) return 'Pre-diabetic';
  return 'High';
}

module.exports = {
  calculateStreak,
  calculateAverageAccuracy,
  formatDuration,
  calculateBMI,
  classifyBMI,
  classifyBP,
  calculateCalorieBurn,
  isValidEmail,
  validatePassword,
  calculateAge,
  isValidBloodPressure,
  parseBloodPressure,
  clamp,
  normalizeAccuracy,
  calculateProgressPercentage,
  getYogaLevel,
  formatCalories,
  isValidHeartRate,
  calculateBMR,
  daysBetween,
  generateSessionId,
  isHealthyWeight,
  formatLargeNumber,
  calculateTotalMinutes,
  getMostRecentDate,
  mgdlToMmol,
  classifyBloodSugar
};
