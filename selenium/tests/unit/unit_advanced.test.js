const { expect } = require('chai');
const {
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
} = require('../../utils/business_logic');

describe('Unit | Advanced Utility & Health Logic Helpers', function() {

  // ──────────────────────────────────────────────
  // isValidEmail()
  // ──────────────────────────────────────────────
  describe('isValidEmail()', function() {
    it('TC-ADV-01 | Unit | Email_Validation | Accepts a well-formed email address | Unit', function() {
      expect(isValidEmail('user@example.com')).to.be.true;
    });
    it('TC-ADV-02 | Unit | Email_Validation | Accepts email with subdomain | Unit', function() {
      expect(isValidEmail('user@mail.example.co.uk')).to.be.true;
    });
    it('TC-ADV-03 | Unit | Email_Validation | Rejects email missing @ symbol | Unit', function() {
      expect(isValidEmail('userexample.com')).to.be.false;
    });
    it('TC-ADV-04 | Unit | Email_Validation | Rejects email missing domain extension | Unit', function() {
      expect(isValidEmail('user@example')).to.be.false;
    });
    it('TC-ADV-05 | Unit | Email_Validation | Rejects null and undefined inputs | Unit', function() {
      expect(isValidEmail(null)).to.be.false;
      expect(isValidEmail(undefined)).to.be.false;
    });
    it('TC-ADV-06 | Unit | Email_Validation | Rejects empty string input | Unit', function() {
      expect(isValidEmail('')).to.be.false;
    });
    it('TC-ADV-07 | Unit | Email_Validation | Accepts email with plus sign in local part | Unit', function() {
      expect(isValidEmail('user+tag@example.com')).to.be.true;
    });
  });

  // ──────────────────────────────────────────────
  // validatePassword()
  // ──────────────────────────────────────────────
  describe('validatePassword()', function() {
    it('TC-ADV-08 | Unit | Password_Validation | Accepts strong password meeting all requirements | Unit', function() {
      const result = validatePassword('Secure1Pass');
      expect(result.valid).to.be.true;
      expect(result.reasons).to.have.length(0);
    });
    it('TC-ADV-09 | Unit | Password_Validation | Rejects password shorter than 8 characters | Unit', function() {
      const result = validatePassword('Ab1');
      expect(result.valid).to.be.false;
      expect(result.reasons).to.include('Too short (min 8 chars)');
    });
    it('TC-ADV-10 | Unit | Password_Validation | Rejects password missing uppercase letter | Unit', function() {
      const result = validatePassword('password1');
      expect(result.valid).to.be.false;
      expect(result.reasons).to.include('Missing uppercase letter');
    });
    it('TC-ADV-11 | Unit | Password_Validation | Rejects password missing digit | Unit', function() {
      const result = validatePassword('Passwordonly');
      expect(result.valid).to.be.false;
      expect(result.reasons).to.include('Missing digit');
    });
    it('TC-ADV-12 | Unit | Password_Validation | Rejects null password input | Unit', function() {
      const result = validatePassword(null);
      expect(result.valid).to.be.false;
    });
    it('TC-ADV-13 | Unit | Password_Validation | Returns multiple failure reasons when multiple rules fail | Unit', function() {
      const result = validatePassword('abc'); // too short, no uppercase, no digit
      expect(result.reasons.length).to.be.greaterThan(1);
    });
  });

  // ──────────────────────────────────────────────
  // calculateAge()
  // ──────────────────────────────────────────────
  describe('calculateAge()', function() {
    it('TC-ADV-14 | Unit | Age_Calculation | Correctly calculates age for a past birth date | Unit', function() {
      const dob = new Date();
      dob.setFullYear(dob.getFullYear() - 25);
      expect(calculateAge(dob.toISOString())).to.be.at.least(24);
    });
    it('TC-ADV-15 | Unit | Age_Calculation | Returns 0 for null dob | Unit', function() {
      expect(calculateAge(null)).to.equal(0);
    });
    it('TC-ADV-16 | Unit | Age_Calculation | Returns 0 for invalid date string | Unit', function() {
      expect(calculateAge('not-a-date')).to.equal(0);
    });
    it('TC-ADV-17 | Unit | Age_Calculation | Returns non-negative value for very old birth date | Unit', function() {
      expect(calculateAge('1920-01-01')).to.be.at.least(100);
    });
    it('TC-ADV-18 | Unit | Age_Calculation | Returns 0 for a future birth date | Unit', function() {
      const future = new Date();
      future.setFullYear(future.getFullYear() + 5);
      expect(calculateAge(future.toISOString())).to.equal(0);
    });
  });

  // ──────────────────────────────────────────────
  // isValidBloodPressure() & parseBloodPressure()
  // ──────────────────────────────────────────────
  describe('isValidBloodPressure()', function() {
    it('TC-ADV-19 | Unit | BP_Validation | Accepts standard normal blood pressure string | Unit', function() {
      expect(isValidBloodPressure('120/80')).to.be.true;
    });
    it('TC-ADV-20 | Unit | BP_Validation | Accepts high but within range blood pressure | Unit', function() {
      expect(isValidBloodPressure('180/110')).to.be.true;
    });
    it('TC-ADV-21 | Unit | BP_Validation | Rejects missing slash separator | Unit', function() {
      expect(isValidBloodPressure('12080')).to.be.false;
    });
    it('TC-ADV-22 | Unit | BP_Validation | Rejects text string input | Unit', function() {
      expect(isValidBloodPressure('invalidbp')).to.be.false;
    });
    it('TC-ADV-23 | Unit | BP_Validation | Rejects null and undefined inputs | Unit', function() {
      expect(isValidBloodPressure(null)).to.be.false;
      expect(isValidBloodPressure(undefined)).to.be.false;
    });
    it('TC-ADV-24 | Unit | BP_Validation | Rejects out-of-range systolic values | Unit', function() {
      expect(isValidBloodPressure('300/80')).to.be.false;
    });
  });

  describe('parseBloodPressure()', function() {
    it('TC-ADV-25 | Unit | BP_Parsing | Correctly parses valid blood pressure into systolic and diastolic | Unit', function() {
      const result = parseBloodPressure('120/80');
      expect(result).to.deep.equal({ systolic: 120, diastolic: 80 });
    });
    it('TC-ADV-26 | Unit | BP_Parsing | Returns null for invalid blood pressure string | Unit', function() {
      expect(parseBloodPressure('invalidbp')).to.be.null;
    });
    it('TC-ADV-27 | Unit | BP_Parsing | Returns null for null input | Unit', function() {
      expect(parseBloodPressure(null)).to.be.null;
    });
    it('TC-ADV-28 | Unit | BP_Parsing | Correctly parses hypertensive crisis values | Unit', function() {
      const result = parseBloodPressure('185/115');
      expect(result.systolic).to.equal(185);
      expect(result.diastolic).to.equal(115);
    });
  });

  // ──────────────────────────────────────────────
  // clamp() & normalizeAccuracy()
  // ──────────────────────────────────────────────
  describe('clamp()', function() {
    it('TC-ADV-29 | Unit | Clamp_Utility | Returns value unchanged when within bounds | Unit', function() {
      expect(clamp(50, 0, 100)).to.equal(50);
    });
    it('TC-ADV-30 | Unit | Clamp_Utility | Returns min when value is below minimum | Unit', function() {
      expect(clamp(-5, 0, 100)).to.equal(0);
    });
    it('TC-ADV-31 | Unit | Clamp_Utility | Returns max when value exceeds maximum | Unit', function() {
      expect(clamp(150, 0, 100)).to.equal(100);
    });
    it('TC-ADV-32 | Unit | Clamp_Utility | Returns min for null input value | Unit', function() {
      expect(clamp(null, 0, 100)).to.equal(0);
    });
    it('TC-ADV-33 | Unit | Clamp_Utility | Works correctly with negative bounds | Unit', function() {
      expect(clamp(-50, -100, -10)).to.equal(-50);
      expect(clamp(0, -100, -10)).to.equal(-10);
    });
  });

  describe('normalizeAccuracy()', function() {
    it('TC-ADV-34 | Unit | Accuracy_Normalization | Returns value unchanged when already in 0-100 range | Unit', function() {
      expect(normalizeAccuracy(85)).to.equal(85);
    });
    it('TC-ADV-35 | Unit | Accuracy_Normalization | Clamps negative accuracy to 0 | Unit', function() {
      expect(normalizeAccuracy(-10)).to.equal(0);
    });
    it('TC-ADV-36 | Unit | Accuracy_Normalization | Clamps accuracy above 100 to 100 | Unit', function() {
      expect(normalizeAccuracy(150)).to.equal(100);
    });
    it('TC-ADV-37 | Unit | Accuracy_Normalization | Rounds decimal accuracy to nearest integer | Unit', function() {
      expect(normalizeAccuracy(84.6)).to.equal(85);
    });
  });

  // ──────────────────────────────────────────────
  // calculateProgressPercentage()
  // ──────────────────────────────────────────────
  describe('calculateProgressPercentage()', function() {
    it('TC-ADV-38 | Unit | Progress_Calculation | Calculates correct percentage for partial progress | Unit', function() {
      expect(calculateProgressPercentage(25, 100)).to.equal(25);
    });
    it('TC-ADV-39 | Unit | Progress_Calculation | Calculates 100% when current equals total | Unit', function() {
      expect(calculateProgressPercentage(50, 50)).to.equal(100);
    });
    it('TC-ADV-40 | Unit | Progress_Calculation | Returns 0 when total is zero | Unit', function() {
      expect(calculateProgressPercentage(5, 0)).to.equal(0);
    });
    it('TC-ADV-41 | Unit | Progress_Calculation | Caps at 100 when current exceeds total | Unit', function() {
      expect(calculateProgressPercentage(150, 100)).to.equal(100);
    });
    it('TC-ADV-42 | Unit | Progress_Calculation | Returns 0 when current is zero | Unit', function() {
      expect(calculateProgressPercentage(0, 100)).to.equal(0);
    });
  });

  // ──────────────────────────────────────────────
  // getYogaLevel()
  // ──────────────────────────────────────────────
  describe('getYogaLevel()', function() {
    it('TC-ADV-43 | Unit | Yoga_Level | Returns Beginner for zero sessions | Unit', function() {
      expect(getYogaLevel(0)).to.equal('Beginner');
    });
    it('TC-ADV-44 | Unit | Yoga_Level | Returns Beginner for sessions under 5 | Unit', function() {
      expect(getYogaLevel(3)).to.equal('Beginner');
    });
    it('TC-ADV-45 | Unit | Yoga_Level | Returns Intermediate for sessions between 5 and 19 | Unit', function() {
      expect(getYogaLevel(10)).to.equal('Intermediate');
    });
    it('TC-ADV-46 | Unit | Yoga_Level | Returns Advanced for sessions between 20 and 49 | Unit', function() {
      expect(getYogaLevel(35)).to.equal('Advanced');
    });
    it('TC-ADV-47 | Unit | Yoga_Level | Returns Expert for sessions 50 or more | Unit', function() {
      expect(getYogaLevel(100)).to.equal('Expert');
    });
    it('TC-ADV-48 | Unit | Yoga_Level | Returns Beginner for null input | Unit', function() {
      expect(getYogaLevel(null)).to.equal('Beginner');
    });
  });

  // ──────────────────────────────────────────────
  // formatCalories()
  // ──────────────────────────────────────────────
  describe('formatCalories()', function() {
    it('TC-ADV-49 | Unit | Calorie_Formatting | Formats small calorie count correctly | Unit', function() {
      expect(formatCalories(350)).to.equal('350 kcal');
    });
    it('TC-ADV-50 | Unit | Calorie_Formatting | Formats large calorie count with k notation | Unit', function() {
      expect(formatCalories(1500)).to.equal('1.5k kcal');
    });
    it('TC-ADV-51 | Unit | Calorie_Formatting | Returns 0 kcal for null input | Unit', function() {
      expect(formatCalories(null)).to.equal('0 kcal');
    });
    it('TC-ADV-52 | Unit | Calorie_Formatting | Returns 0 kcal for negative input | Unit', function() {
      expect(formatCalories(-100)).to.equal('0 kcal');
    });
    it('TC-ADV-53 | Unit | Calorie_Formatting | Formats exactly 1000 calories with k notation | Unit', function() {
      expect(formatCalories(1000)).to.equal('1.0k kcal');
    });
  });

  // ──────────────────────────────────────────────
  // isValidHeartRate()
  // ──────────────────────────────────────────────
  describe('isValidHeartRate()', function() {
    it('TC-ADV-54 | Unit | HeartRate_Validation | Accepts normal resting heart rate of 72 bpm | Unit', function() {
      expect(isValidHeartRate(72)).to.be.true;
    });
    it('TC-ADV-55 | Unit | HeartRate_Validation | Accepts boundary minimum heart rate 30 bpm | Unit', function() {
      expect(isValidHeartRate(30)).to.be.true;
    });
    it('TC-ADV-56 | Unit | HeartRate_Validation | Accepts boundary maximum heart rate 220 bpm | Unit', function() {
      expect(isValidHeartRate(220)).to.be.true;
    });
    it('TC-ADV-57 | Unit | HeartRate_Validation | Rejects heart rate below 30 bpm | Unit', function() {
      expect(isValidHeartRate(20)).to.be.false;
    });
    it('TC-ADV-58 | Unit | HeartRate_Validation | Rejects heart rate above 220 bpm | Unit', function() {
      expect(isValidHeartRate(230)).to.be.false;
    });
    it('TC-ADV-59 | Unit | HeartRate_Validation | Rejects null and undefined inputs | Unit', function() {
      expect(isValidHeartRate(null)).to.be.false;
      expect(isValidHeartRate(undefined)).to.be.false;
    });
  });

  // ──────────────────────────────────────────────
  // calculateBMR()
  // ──────────────────────────────────────────────
  describe('calculateBMR()', function() {
    it('TC-ADV-60 | Unit | BMR_Calculation | Correctly calculates male BMR | Unit', function() {
      // Male: (10*70) + (6.25*175) - (5*30) + 5 = 700 + 1093.75 - 150 + 5 = 1648.75 -> 1649
      expect(calculateBMR(70, 175, 30, 'male')).to.equal(1649);
    });
    it('TC-ADV-61 | Unit | BMR_Calculation | Correctly calculates female BMR | Unit', function() {
      // Female: (10*60) + (6.25*160) - (5*25) - 161 = 600 + 1000 - 125 - 161 = 1314
      expect(calculateBMR(60, 160, 25, 'female')).to.equal(1314);
    });
    it('TC-ADV-62 | Unit | BMR_Calculation | Returns 0 for invalid gender input | Unit', function() {
      expect(calculateBMR(70, 175, 30, 'unknown')).to.equal(0);
    });
    it('TC-ADV-63 | Unit | BMR_Calculation | Returns 0 for zero weight | Unit', function() {
      expect(calculateBMR(0, 175, 30, 'male')).to.equal(0);
    });
    it('TC-ADV-64 | Unit | BMR_Calculation | Returns 0 for zero age | Unit', function() {
      expect(calculateBMR(70, 175, 0, 'male')).to.equal(0);
    });
  });

  // ──────────────────────────────────────────────
  // daysBetween()
  // ──────────────────────────────────────────────
  describe('daysBetween()', function() {
    it('TC-ADV-65 | Unit | Date_Calculation | Returns 0 for same date | Unit', function() {
      const today = new Date().toISOString();
      expect(daysBetween(today, today)).to.equal(0);
    });
    it('TC-ADV-66 | Unit | Date_Calculation | Returns 7 for dates exactly one week apart | Unit', function() {
      const d1 = new Date('2025-01-01').toISOString();
      const d2 = new Date('2025-01-08').toISOString();
      expect(daysBetween(d1, d2)).to.equal(7);
    });
    it('TC-ADV-67 | Unit | Date_Calculation | Returns absolute value regardless of order | Unit', function() {
      const d1 = new Date('2025-01-01').toISOString();
      const d2 = new Date('2025-01-08').toISOString();
      expect(daysBetween(d2, d1)).to.equal(7);
    });
    it('TC-ADV-68 | Unit | Date_Calculation | Returns 0 for null date inputs | Unit', function() {
      expect(daysBetween(null, null)).to.equal(0);
    });
    it('TC-ADV-69 | Unit | Date_Calculation | Returns 365 for dates one year apart | Unit', function() {
      expect(daysBetween('2024-01-01T00:00:00Z', '2025-01-01T00:00:00Z')).to.equal(366); // 2024 is a leap year
    });
  });

  // ──────────────────────────────────────────────
  // generateSessionId()
  // ──────────────────────────────────────────────
  describe('generateSessionId()', function() {
    it('TC-ADV-70 | Unit | Session_ID | Returns a non-empty string | Unit', function() {
      const id = generateSessionId();
      expect(id).to.be.a('string').and.not.equal('');
    });
    it('TC-ADV-71 | Unit | Session_ID | Starts with session_ prefix | Unit', function() {
      expect(generateSessionId()).to.match(/^session_/);
    });
    it('TC-ADV-72 | Unit | Session_ID | Generates unique IDs across calls | Unit', function() {
      const id1 = generateSessionId();
      const id2 = generateSessionId();
      expect(id1).to.not.equal(id2);
    });
  });

  // ──────────────────────────────────────────────
  // isHealthyWeight()
  // ──────────────────────────────────────────────
  describe('isHealthyWeight()', function() {
    it('TC-ADV-73 | Unit | Weight_Health | Returns true for healthy BMI range | Unit', function() {
      expect(isHealthyWeight(70, 175)).to.be.true; // BMI ~22.9
    });
    it('TC-ADV-74 | Unit | Weight_Health | Returns false for underweight individual | Unit', function() {
      expect(isHealthyWeight(40, 175)).to.be.false; // BMI ~13.1
    });
    it('TC-ADV-75 | Unit | Weight_Health | Returns false for obese individual | Unit', function() {
      expect(isHealthyWeight(120, 175)).to.be.false; // BMI ~39.2
    });
  });

  // ──────────────────────────────────────────────
  // formatLargeNumber()
  // ──────────────────────────────────────────────
  describe('formatLargeNumber()', function() {
    it('TC-ADV-76 | Unit | Number_Formatting | Formats small number without abbreviation | Unit', function() {
      expect(formatLargeNumber(500)).to.equal('500');
    });
    it('TC-ADV-77 | Unit | Number_Formatting | Formats thousands with k suffix | Unit', function() {
      expect(formatLargeNumber(1500)).to.equal('1.5k');
    });
    it('TC-ADV-78 | Unit | Number_Formatting | Formats millions with M suffix | Unit', function() {
      expect(formatLargeNumber(2500000)).to.equal('2.5M');
    });
    it('TC-ADV-79 | Unit | Number_Formatting | Returns 0 for null input | Unit', function() {
      expect(formatLargeNumber(null)).to.equal('0');
    });
    it('TC-ADV-80 | Unit | Number_Formatting | Returns 0 for negative numbers | Unit', function() {
      expect(formatLargeNumber(-100)).to.equal('0');
    });
  });

  // ──────────────────────────────────────────────
  // calculateTotalMinutes()
  // ──────────────────────────────────────────────
  describe('calculateTotalMinutes()', function() {
    it('TC-ADV-81 | Unit | Total_Minutes | Correctly sums session durations into total minutes | Unit', function() {
      const sessions = [{ durationSeconds: 1800 }, { durationSeconds: 900 }]; // 30 + 15 = 45 mins
      expect(calculateTotalMinutes(sessions)).to.equal(45);
    });
    it('TC-ADV-82 | Unit | Total_Minutes | Returns 0 for empty session array | Unit', function() {
      expect(calculateTotalMinutes([])).to.equal(0);
    });
    it('TC-ADV-83 | Unit | Total_Minutes | Returns 0 for null input | Unit', function() {
      expect(calculateTotalMinutes(null)).to.equal(0);
    });
    it('TC-ADV-84 | Unit | Total_Minutes | Handles sessions with missing durationSeconds gracefully | Unit', function() {
      const sessions = [{ durationSeconds: 600 }, {}]; // 10 + 0 = 10 mins
      expect(calculateTotalMinutes(sessions)).to.equal(10);
    });
    it('TC-ADV-85 | Unit | Total_Minutes | Rounds fractional minutes to nearest integer | Unit', function() {
      const sessions = [{ durationSeconds: 90 }]; // 1.5 mins -> rounds to 2
      expect(calculateTotalMinutes(sessions)).to.equal(2);
    });
  });

  // ──────────────────────────────────────────────
  // getMostRecentDate()
  // ──────────────────────────────────────────────
  describe('getMostRecentDate()', function() {
    it('TC-ADV-86 | Unit | Date_Selection | Returns the most recent date from an array | Unit', function() {
      const dates = ['2025-01-01T00:00:00Z', '2025-06-15T00:00:00Z', '2024-12-31T00:00:00Z'];
      const result = getMostRecentDate(dates);
      expect(new Date(result).getFullYear()).to.equal(2025);
      expect(new Date(result).getMonth()).to.equal(5); // June (0-indexed)
    });
    it('TC-ADV-87 | Unit | Date_Selection | Returns null for empty array | Unit', function() {
      expect(getMostRecentDate([])).to.be.null;
    });
    it('TC-ADV-88 | Unit | Date_Selection | Returns null for null input | Unit', function() {
      expect(getMostRecentDate(null)).to.be.null;
    });
    it('TC-ADV-89 | Unit | Date_Selection | Returns the single element for single-item array | Unit', function() {
      const date = '2025-03-20T00:00:00Z';
      const result = getMostRecentDate([date]);
      expect(new Date(result).getTime()).to.equal(new Date(date).getTime());
    });
  });

  // ──────────────────────────────────────────────
  // mgdlToMmol() & classifyBloodSugar()
  // ──────────────────────────────────────────────
  describe('mgdlToMmol()', function() {
    it('TC-ADV-90 | Unit | BloodSugar_Conversion | Correctly converts 180 mg/dL to mmol/L | Unit', function() {
      expect(mgdlToMmol(180)).to.equal(10.0);
    });
    it('TC-ADV-91 | Unit | BloodSugar_Conversion | Returns 0 for null input | Unit', function() {
      expect(mgdlToMmol(null)).to.equal(0);
    });
    it('TC-ADV-92 | Unit | BloodSugar_Conversion | Returns 0 for zero input | Unit', function() {
      expect(mgdlToMmol(0)).to.equal(0);
    });
    it('TC-ADV-93 | Unit | BloodSugar_Conversion | Correctly converts fasting blood sugar 99 mg/dL | Unit', function() {
      expect(mgdlToMmol(99)).to.equal(5.5);
    });
  });

  describe('classifyBloodSugar()', function() {
    it('TC-ADV-94 | Unit | BloodSugar_Classification | Classifies low blood sugar correctly | Unit', function() {
      expect(classifyBloodSugar(55)).to.equal('Low');
    });
    it('TC-ADV-95 | Unit | BloodSugar_Classification | Classifies normal blood sugar correctly | Unit', function() {
      expect(classifyBloodSugar(90)).to.equal('Normal');
    });
    it('TC-ADV-96 | Unit | BloodSugar_Classification | Classifies pre-diabetic range correctly | Unit', function() {
      expect(classifyBloodSugar(110)).to.equal('Pre-diabetic');
    });
    it('TC-ADV-97 | Unit | BloodSugar_Classification | Classifies high blood sugar correctly | Unit', function() {
      expect(classifyBloodSugar(180)).to.equal('High');
    });
    it('TC-ADV-98 | Unit | BloodSugar_Classification | Returns Unknown for zero or null input | Unit', function() {
      expect(classifyBloodSugar(0)).to.equal('Unknown');
      expect(classifyBloodSugar(null)).to.equal('Unknown');
    });
    it('TC-ADV-99 | Unit | BloodSugar_Classification | Classifies boundary fasting normal value 99 mg/dL | Unit', function() {
      expect(classifyBloodSugar(99)).to.equal('Normal');
    });
    it('TC-ADV-100 | Unit | BloodSugar_Classification | Classifies boundary pre-diabetic value 100 mg/dL | Unit', function() {
      expect(classifyBloodSugar(100)).to.equal('Pre-diabetic');
    });
  });
});
