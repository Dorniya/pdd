const Mocha = require('mocha');
const path = require('path');
const fs = require('fs');
const { createDriver, takeScreenshot } = require('./utils/driver_helper');
const { generateExcelReport } = require('./utils/excel_reporter');
const { generateHtmlReport } = require('./utils/html_reporter');
const config = require('./config/config.json');

// Helper to parse descriptive structured test titles
function parseTestTitle(title, filePath) {
  const parts = title.split('|').map(p => p.trim());
  const fileDir = path.basename(path.dirname(filePath));
  
  if (parts.length >= 5) {
    return {
      id: parts[0],
      module: parts[1],
      feature: parts[2],
      description: parts[3],
      type: parts[4]
    };
  }
  
  const typeMap = {
    'e2e': 'End-to-End',
    'functional': 'Functional',
    'validation': 'Validation',
    'unit': 'Unit'
  };
  
  return {
    id: '',
    module: fileDir.charAt(0).toUpperCase() + fileDir.slice(1),
    feature: path.basename(filePath, '.test.js'),
    description: title,
    type: typeMap[fileDir.toLowerCase()] || 'Regression'
  };
}

async function main() {
  console.log('==================================================');
  console.log('      Starting Yoga App Appium Mobile Suite      ');
  console.log('==================================================');

  let driver = null;
  const isUnitOnly = process.argv.includes('--unit');

  if (!isUnitOnly) {
    try {
      console.log('[Runner] Initializing Appium driver session...');
      driver = await createDriver();
      global.driver = driver;
      console.log('[Runner] Appium session successfully established.');
    } catch (error) {
      console.error('[Runner] CRITICAL: Failed to initialize Appium driver session:', error.stack || error.message);
      process.exit(1);
    }
  }

  // Initialize Mocha instance
  const mocha = new Mocha({
    timeout: config.defaultTimeout,
    reporter: 'spec'
  });

  // Load root hooks for failure diagnostics
  mocha.rootHooks({
    async afterEach() {
      if (this.currentTest && this.currentTest.state === 'failed' && global.driver) {
        try {
          const testName = this.currentTest.fullTitle();
          console.log(`[RootHooks] Mobile test failed: "${testName}". Capturing screenshot...`);
          this.currentTest.screenshotPath = await takeScreenshot(global.driver, testName);
        } catch (e) {
          console.error('[RootHooks] Error gathering diagnostics:', e.message);
        }
      }
    }
  });

  // Find all test files matching *.test.js in subdirectories inside tests/
  const searchDirs = [
    'tests/e2e',
    'tests/functional',
    'tests/validation',
    'tests/ui_ux',
    'tests/vulnerability',
    'tests/unit'
  ];
  const testFiles = [];

  searchDirs.forEach(dir => {
    // If running unit tests only, skip mobile device interaction directories
    if (isUnitOnly && !dir.endsWith('unit') && !dir.endsWith('vulnerability')) return;
    
    const dirPath = path.join(__dirname, dir);
    if (fs.existsSync(dirPath)) {
      fs.readdirSync(dirPath)
        .filter(file => file.endsWith('.test.js'))
        .forEach(file => {
          const fullPath = path.join(dirPath, file);
          mocha.addFile(fullPath);
          testFiles.push(fullPath);
        });
    }
  });

  if (testFiles.length === 0) {
    console.log('[Runner] No test files found. Exiting.');
    if (driver) await driver.deleteSession();
    process.exit(0);
  }

  console.log(`[Runner] Registered ${testFiles.length} test file(s).`);

  const results = [];
  const startTime = Date.now();

  // Run the test runner
  const runner = mocha.run(async (failures) => {
    const totalDuration = Date.now() - startTime;
    console.log('\n==================================================');
    console.log('               Execution Completed                ');
    console.log('==================================================');
    
    // Shut down driver if running mobile session
    if (driver) {
      console.log('[Runner] Shutting down Appium session...');
      try {
        await driver.deleteSession();
      } catch (err) {
        console.error('[Runner] Error closing Appium session:', err.message);
      }
    }

    console.log('[Runner] Processing test results and generating reports...');
    try {
      await generateExcelReport(results);
      generateHtmlReport(results, { totalDuration });
      
      console.log(`[Runner] Reports written successfully. Total Failures: ${failures}`);
      process.exit(failures ? 1 : 0);
    } catch (reportError) {
      console.error('[Runner] Error generating execution reports:', reportError.message);
      process.exit(1);
    }
  });

  // Listen for test pass/fail hooks to collect metrics
  runner.on('pass', (test) => {
    const info = parseTestTitle(test.title, test.file);
    results.push({
      id: info.id || `TC-PASS-${results.length + 1}`,
      module: info.module,
      feature: info.feature,
      description: info.description,
      type: info.type,
      expected: 'Test should execute and complete successfully.',
      actual: 'Completed successfully without any assertions failing.',
      status: 'Pass',
      duration: test.duration || 0,
      date: new Date().toISOString()
    });
  });

  runner.on('fail', (test, err) => {
    const info = parseTestTitle(test.title, test.file);
    results.push({
      id: info.id || `TC-FAIL-${results.length + 1}`,
      module: info.module,
      feature: info.feature,
      description: info.description,
      type: info.type,
      expected: 'Test should execute and complete successfully.',
      actual: `Failed: ${err.message}`,
      status: 'Fail',
      duration: test.duration || 0,
      error: err.stack || err.message,
      screenshot: test.screenshotPath || '',
      date: new Date().toISOString()
    });
  });
}

main().catch(err => {
  console.error('[Runner] Fatal runner error:', err);
  process.exit(1);
});
