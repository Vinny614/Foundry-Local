# Create local SQL database and seed with sample data
# This script creates a SQLite database with sample analytics data

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Database Setup and Seed Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Define paths
$dataDir = "C:\FoundryDemo\data"
$dbPath = "$dataDir\analytics.db"
$csvPath = "$dataDir\sales_data.csv"

# Create directory
Write-Host "Creating data directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

# Step 1: Install SQLite (portable version)
Write-Host "Installing SQLite..." -ForegroundColor Yellow
$sqliteUrl = "https://www.sqlite.org/2024/sqlite-tools-win-x64-3460100.zip"
$sqliteZip = "$env:TEMP\sqlite-tools.zip"
$sqliteDir = "C:\FoundryDemo\sqlite"

if (-not (Test-Path "$sqliteDir\sqlite3.exe")) {
    try {
        Write-Host "Downloading SQLite..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $sqliteUrl -OutFile $sqliteZip -UseBasicParsing
        
        Write-Host "Extracting SQLite..." -ForegroundColor Yellow
        Expand-Archive -Path $sqliteZip -DestinationPath $sqliteDir -Force
        
        # Move files from nested folder
        $nestedFolder = Get-ChildItem -Path $sqliteDir -Directory | Select-Object -First 1
        if ($nestedFolder) {
            Get-ChildItem -Path $nestedFolder.FullName -File | Move-Item -Destination $sqliteDir -Force
            Remove-Item -Path $nestedFolder.FullName -Recurse -Force
        }
        
        Write-Host "SQLite installed successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to install SQLite: $_"
        exit 1
    }
} else {
    Write-Host "SQLite already installed" -ForegroundColor Green
}

$sqlite = "$sqliteDir\sqlite3.exe"

# Step 2: Create sample CSV data
Write-Host "Creating sample sales data..." -ForegroundColor Yellow
$csvData = @"
date,product,category,region,quantity,revenue,cost
2024-01-15,Laptop,Electronics,East,25,37500,22500
2024-01-16,Mouse,Electronics,West,150,4500,1800
2024-01-17,Keyboard,Electronics,East,100,6000,3000
2024-01-18,Monitor,Electronics,South,40,16000,8000
2024-01-19,Desk,Furniture,North,30,15000,9000
2024-01-20,Chair,Furniture,East,50,12500,7500
2024-01-21,Laptop,Electronics,West,35,52500,31500
2024-01-22,Tablet,Electronics,South,60,24000,14400
2024-01-23,Phone,Electronics,North,80,40000,24000
2024-01-24,Desk,Furniture,West,20,10000,6000
2024-01-25,Mouse,Electronics,East,200,6000,2400
2024-01-26,Keyboard,Electronics,North,120,7200,3600
2024-01-27,Monitor,Electronics,West,55,22000,11000
2024-01-28,Chair,Furniture,South,65,16250,9750
2024-01-29,Laptop,Electronics,East,40,60000,36000
2024-01-30,Tablet,Electronics,West,70,28000,16800
2024-02-01,Phone,Electronics,South,90,45000,27000
2024-02-02,Desk,Furniture,North,25,12500,7500
2024-02-03,Mouse,Electronics,West,180,5400,2160
2024-02-04,Keyboard,Electronics,East,110,6600,3300
2024-02-05,Monitor,Electronics,South,45,18000,9000
2024-02-06,Chair,Furniture,West,55,13750,8250
2024-02-07,Laptop,Electronics,North,30,45000,27000
2024-02-08,Tablet,Electronics,East,65,26000,15600
2024-02-09,Phone,Electronics,West,85,42500,25500
"@

$csvData | Out-File -FilePath $csvPath -Encoding UTF8
Write-Host "Sample data created: $csvPath" -ForegroundColor Green

# Step 3: Create database and table
Write-Host "Creating database and table..." -ForegroundColor Yellow
$createTableSql = @"
CREATE TABLE IF NOT EXISTS sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    product TEXT NOT NULL,
    category TEXT NOT NULL,
    region TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    revenue REAL NOT NULL,
    cost REAL NOT NULL
);
"@

$createTableSql | & $sqlite $dbPath
Write-Host "Database table created" -ForegroundColor Green

# Step 4: Import CSV data
Write-Host "Importing CSV data into database..." -ForegroundColor Yellow
$importSql = @"
.mode csv
.import '$csvPath' temp_sales
INSERT INTO sales (date, product, category, region, quantity, revenue, cost)
SELECT date, product, category, region, quantity, revenue, cost FROM temp_sales WHERE date != 'date';
DROP TABLE temp_sales;
"@

$importSql | & $sqlite $dbPath
Write-Host "Data imported successfully" -ForegroundColor Green

# Step 5: Verify data
Write-Host "Verifying data..." -ForegroundColor Yellow
$countSql = "SELECT COUNT(*) as record_count FROM sales;"
$count = $countSql | & $sqlite $dbPath
Write-Host "Total records in database: $count" -ForegroundColor Green

# Step 6: Create some useful views
Write-Host "Creating summary views..." -ForegroundColor Yellow
$createViewsSql = @"
CREATE VIEW IF NOT EXISTS sales_by_category AS
SELECT category, 
       SUM(quantity) as total_quantity,
       SUM(revenue) as total_revenue,
       SUM(cost) as total_cost,
       SUM(revenue - cost) as total_profit
FROM sales
GROUP BY category;

CREATE VIEW IF NOT EXISTS sales_by_region AS
SELECT region,
       SUM(quantity) as total_quantity,
       SUM(revenue) as total_revenue,
       SUM(cost) as total_cost,
       SUM(revenue - cost) as total_profit
FROM sales
GROUP BY region;

CREATE VIEW IF NOT EXISTS top_products AS
SELECT product,
       SUM(quantity) as total_quantity,
       SUM(revenue) as total_revenue
FROM sales
GROUP BY product
ORDER BY total_revenue DESC
LIMIT 10;
"@

$createViewsSql | & $sqlite $dbPath
Write-Host "Summary views created" -ForegroundColor Green

# Step 7: Create sample query script
Write-Host "Creating sample query script..." -ForegroundColor Yellow
$querySql = @"
-- Sample queries for the sales database

-- Query 1: Total sales by category
SELECT * FROM sales_by_category;

-- Query 2: Total sales by region
SELECT * FROM sales_by_region;

-- Query 3: Top 10 products by revenue
SELECT * FROM top_products;

-- Query 4: Daily revenue trend
SELECT date, SUM(revenue) as daily_revenue, SUM(revenue - cost) as daily_profit
FROM sales
GROUP BY date
ORDER BY date;

-- Query 5: Average order value by region
SELECT region, 
       AVG(revenue) as avg_order_value,
       AVG(quantity) as avg_quantity
FROM sales
GROUP BY region;
"@

$querySql | Out-File -FilePath "$dataDir\sample_queries.sql" -Encoding UTF8
Write-Host "Sample queries saved to: $dataDir\sample_queries.sql" -ForegroundColor Green

# Step 8: Display summary
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Database Setup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Database Location: $dbPath" -ForegroundColor Yellow
Write-Host "SQLite Location: $sqlite" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can query the database with:" -ForegroundColor Yellow
Write-Host "  $sqlite $dbPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Example queries:" -ForegroundColor Yellow
Write-Host "  SELECT * FROM sales LIMIT 5;" -ForegroundColor Cyan
Write-Host "  SELECT * FROM sales_by_category;" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Next Step: Run start_mcp_server.ps1" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
