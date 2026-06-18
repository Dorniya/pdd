const fs = require('fs');
const path = require('path');
const config = require('../config/config.json');

/**
 * Compiles a visual, interactive HTML dashboard summarizing test execution results.
 * @param {Array} results Array of test details and metrics.
 * @param {Object} durationInfo Object containing overall duration metrics.
 */
function generateHtmlReport(results, durationInfo) {
  const total = results.length;
  const passed = results.filter(r => r.status === 'Pass').length;
  const failed = total - passed;
  const skipped = 0; // standard setup
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(1) : 0;
  
  const testRows = results.map((test, index) => {
    const statusClass = test.status === 'Pass' ? 'status-pass' : 'status-fail';
    const hasError = test.error ? 'has-error' : '';
    const screenshotHtml = test.screenshot 
      ? `<div class="screenshot-preview">
           <strong>Failure Screenshot:</strong><br>
           <a href="${path.relative(path.dirname(config.htmlReportPath), test.screenshot)}" target="_blank">
             <img src="${path.relative(path.dirname(config.htmlReportPath), test.screenshot)}" alt="Failure Screenshot">
           </a>
         </div>`
      : '';
      
    const errorDetailsHtml = test.error
      ? `<div class="error-details-box">
           <strong>Error Message:</strong>
           <pre>${escapeHtml(test.error)}</pre>
           ${test.logs ? `<strong>Browser Logs:</strong><pre>${escapeHtml(test.logs)}</pre>` : ''}
           ${screenshotHtml}
         </div>`
      : '';

    return `
      <tr class="test-row ${test.status.toLowerCase()} ${hasError}" onclick="toggleDetails(${index})">
        <td>${escapeHtml(test.id || `TC-${index + 1}`)}</td>
        <td>${escapeHtml(test.module)}</td>
        <td>${escapeHtml(test.feature)}</td>
        <td class="description-cell">
          <strong>${escapeHtml(test.description)}</strong>
          <span class="type-badge">${escapeHtml(test.type)}</span>
        </td>
        <td><span class="status-badge ${statusClass}">${test.status}</span></td>
        <td class="time-cell">${test.duration} ms</td>
      </tr>
      ${test.error ? `
      <tr id="details-${index}" class="details-row" style="display: none;">
        <td colspan="6">
          ${errorDetailsHtml}
        </td>
      </tr>` : ''}
    `;
  }).join('');

  const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Test Automation Dashboard</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-dark: #0f172a;
      --bg-card: #1e293b;
      --border: #334155;
      --text-main: #f8fafc;
      --text-muted: #94a3b8;
      --green: #10b981;
      --red: #f43f5e;
      --blue: #3b82f6;
    }
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    body {
      font-family: 'Inter', sans-serif;
      background-color: var(--bg-dark);
      color: var(--text-main);
      padding: 2rem;
      min-height: 100vh;
    }
    
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 2rem;
      border-bottom: 1px solid var(--border);
      padding-bottom: 1.5rem;
    }
    
    .header h1 {
      font-size: 1.75rem;
      font-weight: 700;
      background: linear-gradient(to right, #10b981, #3b82f6);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    
    .meta-info {
      text-align: right;
      color: var(--text-muted);
      font-size: 0.875rem;
    }
    
    .stats-container {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2.5rem;
    }
    
    .stat-card {
      background-color: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 1.5rem;
      text-align: center;
      box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
      transition: transform 0.2s;
    }
    
    .stat-card:hover {
      transform: translateY(-2px);
    }
    
    .stat-label {
      font-size: 0.875rem;
      color: var(--text-muted);
      margin-bottom: 0.5rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    
    .stat-value {
      font-size: 2.25rem;
      font-weight: 700;
    }
    
    .stat-card.passed .stat-value { color: var(--green); }
    .stat-card.failed .stat-value { color: var(--red); }
    .stat-card.rate .stat-value {
      background: linear-gradient(to right, var(--green), #6ee7b7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    
    .filter-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
    }
    
    .filter-buttons {
      display: flex;
      gap: 0.75rem;
    }
    
    .filter-btn {
      background-color: var(--bg-card);
      border: 1px solid var(--border);
      color: var(--text-main);
      padding: 0.5rem 1rem;
      border-radius: 8px;
      font-weight: 500;
      cursor: pointer;
      font-size: 0.875rem;
      transition: all 0.2s;
    }
    
    .filter-btn:hover {
      background-color: #334155;
    }
    
    .filter-btn.active {
      background-color: var(--blue);
      border-color: var(--blue);
    }
    
    .search-input {
      background-color: var(--bg-card);
      border: 1px solid var(--border);
      color: var(--text-main);
      padding: 0.5rem 1rem;
      border-radius: 8px;
      font-size: 0.875rem;
      width: 280px;
      outline: none;
    }
    
    .search-input:focus {
      border-color: var(--blue);
    }
    
    .table-container {
      background-color: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1);
    }
    
    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 0.95rem;
    }
    
    th {
      background-color: #0f172a;
      color: var(--text-muted);
      font-weight: 600;
      padding: 1rem 1.5rem;
      border-bottom: 1px solid var(--border);
      text-transform: uppercase;
      font-size: 0.75rem;
      letter-spacing: 0.05em;
    }
    
    td {
      padding: 1.25rem 1.5rem;
      border-bottom: 1px solid var(--border);
      vertical-align: middle;
    }
    
    .test-row {
      cursor: pointer;
      transition: background-color 0.15s;
    }
    
    .test-row:hover {
      background-color: #334155;
    }
    
    .description-cell {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }
    
    .type-badge {
      font-size: 0.75rem;
      color: var(--text-muted);
      background-color: #0f172a;
      padding: 0.1rem 0.4rem;
      border-radius: 4px;
      align-self: flex-start;
    }
    
    .status-badge {
      display: inline-block;
      padding: 0.25rem 0.75rem;
      border-radius: 9999px;
      font-weight: 600;
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    
    .status-pass {
      background-color: rgba(16, 185, 129, 0.15);
      color: var(--green);
    }
    
    .status-fail {
      background-color: rgba(244, 63, 94, 0.15);
      color: var(--red);
    }
    
    .time-cell {
      color: var(--text-muted);
      font-size: 0.875rem;
    }
    
    .details-row {
      background-color: #0b0f19;
    }
    
    .error-details-box {
      padding: 1.5rem;
      border-left: 4px solid var(--red);
      background-color: rgba(244, 63, 94, 0.02);
      border-radius: 0 8px 8px 0;
      margin: 0.5rem 0;
    }
    
    .error-details-box strong {
      display: block;
      margin-bottom: 0.5rem;
      font-size: 0.875rem;
      color: var(--text-muted);
    }
    
    pre {
      background-color: #0f172a;
      border: 1px solid var(--border);
      padding: 1rem;
      border-radius: 8px;
      font-family: 'Courier New', Courier, monospace;
      font-size: 0.875rem;
      color: #e2e8f0;
      white-space: pre-wrap;
      word-break: break-all;
      margin-bottom: 1.25rem;
    }
    
    .screenshot-preview img {
      max-width: 100%;
      max-height: 360px;
      border: 1px solid var(--border);
      border-radius: 8px;
      margin-top: 0.5rem;
      box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.3);
      transition: transform 0.2s;
    }
    
    .screenshot-preview img:hover {
      transform: scale(1.02);
    }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <h1>Yoga App Test Automation Dashboard</h1>
      <p style="color: var(--text-muted); margin-top: 0.25rem;">Automated Selenium E2E Diagnostics</p>
    </div>
    <div class="meta-info">
      <div>Execution Date: <strong>${new Date().toLocaleString()}</strong></div>
      <div style="margin-top: 0.25rem;">Duration: <strong>${(durationInfo.totalDuration / 1000).toFixed(2)}s</strong></div>
    </div>
  </div>

  <div class="stats-container">
    <div class="stat-card">
      <div class="stat-label">Total Tests</div>
      <div class="stat-value">${total}</div>
    </div>
    <div class="stat-card passed">
      <div class="stat-label">Passed</div>
      <div class="stat-value">${passed}</div>
    </div>
    <div class="stat-card failed">
      <div class="stat-label">Failed</div>
      <div class="stat-value">${failed}</div>
    </div>
    <div class="stat-card rate">
      <div class="stat-label">Pass Rate</div>
      <div class="stat-value">${passRate}%</div>
    </div>
  </div>

  <div class="filter-bar">
    <div class="filter-buttons">
      <button class="filter-btn active" onclick="filterTests('all', this)">All Tests</button>
      <button class="filter-btn" onclick="filterTests('pass', this)">Passed</button>
      <button class="filter-btn" onclick="filterTests('fail', this)">Failed</button>
    </div>
    <input type="text" class="search-input" placeholder="Search module, feature, desc..." oninput="searchTests(this.value)">
  </div>

  <div class="table-container">
    <table id="test-table">
      <thead>
        <tr>
          <th style="width: 120px;">ID</th>
          <th style="width: 140px;">Module</th>
          <th style="width: 160px;">Feature</th>
          <th>Description</th>
          <th style="width: 120px;">Status</th>
          <th style="width: 120px;">Duration</th>
        </tr>
      </thead>
      <tbody>
        ${testRows}
      </tbody>
    </table>
  </div>

  <script>
    function toggleDetails(index) {
      const detailsRow = document.getElementById('details-' + index);
      if (detailsRow) {
        detailsRow.style.display = detailsRow.style.display === 'none' ? 'table-row' : 'none';
      }
    }

    function filterTests(status, button) {
      // Toggle button active class
      document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
      button.classList.add('active');

      const rows = document.querySelectorAll('#test-table tbody tr.test-row');
      rows.forEach((row, index) => {
        const detailsRow = document.getElementById('details-' + index);
        
        if (status === 'all') {
          row.style.display = 'table-row';
        } else if (status === 'pass' && row.classList.contains('pass')) {
          row.style.display = 'table-row';
        } else if (status === 'fail' && row.classList.contains('fail')) {
          row.style.display = 'table-row';
        } else {
          row.style.display = 'none';
          if (detailsRow) detailsRow.style.display = 'none';
        }
      });
    }

    function searchTests(query) {
      const lower = query.toLowerCase();
      const rows = document.querySelectorAll('#test-table tbody tr.test-row');
      
      rows.forEach((row, index) => {
        const detailsRow = document.getElementById('details-' + index);
        const text = row.textContent.toLowerCase();
        
        if (text.includes(lower)) {
          row.style.display = 'table-row';
        } else {
          row.style.display = 'none';
          if (detailsRow) detailsRow.style.display = 'none';
        }
      });
    }
  </script>
</body>
</html>
  `;

  // Make sure output folder exists
  const reportPath = path.resolve(config.htmlReportPath);
  const dir = path.dirname(reportPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(reportPath, htmlContent, 'utf8');
  console.log(`[HtmlReporter] Interactive HTML dashboard generated at: ${reportPath}`);
}

function escapeHtml(text) {
  if (!text) return '';
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

module.exports = {
  generateHtmlReport
};
