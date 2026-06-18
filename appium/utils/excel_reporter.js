const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');
const config = require('../config/config.json');

async function generateExcelReport(results) {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Mobile E2E Test Report');

  // Set gridlines visible
  sheet.views = [{ showGridLines: true }];

  // 1. Add Title & Metadata Block
  sheet.mergeCells('A1:L1');
  const titleCell = sheet.getCell('A1');
  titleCell.value = 'Mobile E2E Test Automation Execution Report';
  titleCell.font = { name: 'Arial', size: 16, bold: true, color: { argb: 'FFFFFFFF' } };
  titleCell.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF1565C0' } // Blue header
  };
  titleCell.alignment = { vertical: 'middle', horizontal: 'center' };
  sheet.getRow(1).height = 40;

  // 2. Add Stats Summary Block
  const total = results.length;
  const passed = results.filter(r => r.status === 'Pass').length;
  const failed = total - passed;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(1) + '%' : '0%';

  sheet.getCell('A3').value = 'Execution Summary';
  sheet.getCell('A3').font = { bold: true, size: 12 };
  
  sheet.getCell('A4').value = 'Total Tests';
  sheet.getCell('B4').value = total;
  sheet.getCell('A5').value = 'Passed';
  sheet.getCell('B5').value = passed;
  sheet.getCell('D4').value = 'Failed';
  sheet.getCell('E4').value = failed;
  sheet.getCell('D5').value = 'Pass Rate';
  sheet.getCell('E5').value = passRate;

  // Format stats labels and values
  ['A4', 'A5', 'D4', 'D5'].forEach(cell => {
    sheet.getCell(cell).font = { bold: true };
    sheet.getCell(cell).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF5F5F5' } };
  });
  
  sheet.getCell('B5').font = { color: { argb: 'FF2E7D32' }, bold: true };
  sheet.getCell('E4').font = { color: { argb: 'FFC62828' }, bold: true };
  sheet.getCell('E5').font = { color: { argb: 'FF2E7D32' }, bold: true };

  // 3. Define Table Columns
  const headers = [
    'Test Case ID', 'Module', 'Feature', 'Test Description', 'Test Type', 
    'Expected Result', 'Actual Result', 'Status', 'Execution Time', 
    'Error Details', 'Screenshot Path', 'Execution Date'
  ];

  const headerRowIndex = 7;
  const headerRow = sheet.getRow(headerRowIndex);
  headerRow.values = headers;
  headerRow.height = 28;

  headerRow.eachCell((cell) => {
    cell.font = { name: 'Arial', size: 10, bold: true, color: { argb: 'FFFFFFFF' } };
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF0D47A1' } // Dark Blue
    };
    cell.alignment = { vertical: 'middle', horizontal: 'center' };
    cell.border = {
      top: { style: 'thin' }, left: { style: 'thin' },
      bottom: { style: 'medium' }, right: { style: 'thin' }
    };
  });

  // 4. Populate Data Rows
  let currentRow = headerRowIndex + 1;

  results.forEach((test) => {
    const row = sheet.getRow(currentRow);
    row.values = [
      test.id || `TC-${currentRow - headerRowIndex}`,
      test.module || 'General',
      test.feature || 'N/A',
      test.description || 'Test case execution',
      test.type || 'Functional',
      test.expected || 'Should pass without error',
      test.actual || 'Success',
      test.status || 'Pass',
      test.duration !== undefined ? `${test.duration} ms` : 'N/A',
      test.error || '',
      test.screenshot || '',
      test.date || new Date().toISOString()
    ];

    // Style the status cell
    const statusCell = row.getCell(8);
    if (test.status === 'Pass') {
      statusCell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFE8F5E9' } // Soft light green
      };
      statusCell.font = { color: { argb: 'FF2E7D32' }, bold: true };
    } else {
      statusCell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFFFEBEE' } // Soft light red
      };
      statusCell.font = { color: { argb: 'FFC62828' }, bold: true };
    }

    // Set thin borders for all cells in data row
    row.eachCell((cell) => {
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFE0E0E0' } },
        left: { style: 'thin', color: { argb: 'FFE0E0E0' } },
        bottom: { style: 'thin', color: { argb: 'FFE0E0E0' } },
        right: { style: 'thin', color: { argb: 'FFE0E0E0' } }
      };
      cell.alignment = { vertical: 'middle' };
    });

    currentRow++;
  });

  // 5. Auto-fit column widths
  sheet.columns.forEach((column, index) => {
    let maxLen = 0;
    sheet.eachRow({ includeEmpty: false }, (row, rowNum) => {
      if (rowNum >= headerRowIndex) {
        const val = row.getCell(index + 1).value;
        if (val) {
          maxLen = Math.max(maxLen, val.toString().length);
        }
      }
    });
    column.width = Math.min(Math.max(maxLen + 4, 12), 40);
  });

  // Ensure report directory exists
  const reportPath = path.resolve(__dirname, '..', config.excelReportPath);
  const dir = path.dirname(reportPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  // Write workbook to file
  await workbook.xlsx.writeFile(reportPath);
  console.log(`[ExcelReporter] Excel report successfully generated at: ${reportPath}`);
}

module.exports = {
  generateExcelReport
};
