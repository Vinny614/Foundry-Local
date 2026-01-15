# Start MCP Server for SQL Database
# This script creates and starts a simple MCP server that exposes read-only SQL tools

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "MCP Server Setup and Start Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Define paths
$mcpDir = "C:\FoundryDemo\mcp-server"
$dataDir = "C:\FoundryDemo\data"
$dbPath = "$dataDir\analytics.db"

# Check if database exists
if (-not (Test-Path $dbPath)) {
    Write-Error "Database not found at $dbPath. Please run install_db_and_seed_data.ps1 first."
    exit 1
}

# Create MCP server directory
Write-Host "Creating MCP server directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $mcpDir -Force | Out-Null

# Step 1: Install Python if not present
Write-Host "Checking for Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version
    Write-Host "Python is installed: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Installing Python..." -ForegroundColor Yellow
    winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Start-Sleep -Seconds 5
    $pythonVersion = python --version
    Write-Host "Python installed: $pythonVersion" -ForegroundColor Green
}

# Step 2: Create Python MCP server
Write-Host "Creating MCP server application..." -ForegroundColor Yellow

$mcpServerCode = @'
"""
Simple MCP Server for SQLite Analytics Database
Provides read-only tools for querying sales data
"""
import sqlite3
import json
import sys
from typing import Any

DB_PATH = r"C:\FoundryDemo\data\analytics.db"

class MCPServer:
    """Minimal MCP server implementation"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        
    def execute_query(self, query: str) -> list[dict[str, Any]]:
        """Execute a read-only SQL query"""
        # Basic SQL injection protection - only allow SELECT
        if not query.strip().upper().startswith("SELECT"):
            raise ValueError("Only SELECT queries are allowed")
        
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        try:
            cursor.execute(query)
            results = [dict(row) for row in cursor.fetchall()]
            return results
        finally:
            conn.close()
    
    def get_schema(self) -> dict[str, Any]:
        """Get database schema information"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            # Get all tables
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
            tables = [row[0] for row in cursor.fetchall()]
            
            schema = {}
            for table in tables:
                cursor.execute(f"PRAGMA table_info({table});")
                columns = [{"name": row[1], "type": row[2]} for row in cursor.fetchall()]
                schema[table] = columns
            
            return schema
        finally:
            conn.close()
    
    def get_table_summary(self, table_name: str) -> dict[str, Any]:
        """Get summary statistics for a table"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        try:
            # Get row count
            cursor.execute(f"SELECT COUNT(*) as count FROM {table_name};")
            count = cursor.fetchone()["count"]
            
            # Get column names
            cursor.execute(f"PRAGMA table_info({table_name});")
            columns = [row[1] for row in cursor.fetchall()]
            
            # Get sample rows
            cursor.execute(f"SELECT * FROM {table_name} LIMIT 5;")
            sample = [dict(row) for row in cursor.fetchall()]
            
            return {
                "table": table_name,
                "row_count": count,
                "columns": columns,
                "sample_rows": sample
            }
        finally:
            conn.close()
    
    def handle_tool_call(self, tool: str, arguments: dict[str, Any]) -> dict[str, Any]:
        """Handle MCP tool calls"""
        try:
            if tool == "execute_query":
                query = arguments.get("query", "")
                results = self.execute_query(query)
                return {"success": True, "results": results, "count": len(results)}
            
            elif tool == "get_schema":
                schema = self.get_schema()
                return {"success": True, "schema": schema}
            
            elif tool == "get_table_summary":
                table_name = arguments.get("table_name", "sales")
                summary = self.get_table_summary(table_name)
                return {"success": True, "summary": summary}
            
            else:
                return {"success": False, "error": f"Unknown tool: {tool}"}
        
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def list_tools(self) -> list[dict[str, Any]]:
        """List available MCP tools"""
        return [
            {
                "name": "execute_query",
                "description": "Execute a read-only SQL SELECT query on the sales database",
                "parameters": {
                    "query": {
                        "type": "string",
                        "description": "SQL SELECT query to execute"
                    }
                }
            },
            {
                "name": "get_schema",
                "description": "Get the database schema (tables and columns)",
                "parameters": {}
            },
            {
                "name": "get_table_summary",
                "description": "Get summary statistics and sample data for a table",
                "parameters": {
                    "table_name": {
                        "type": "string",
                        "description": "Name of the table (default: sales)"
                    }
                }
            }
        ]

def main():
    """Main entry point for MCP server"""
    server = MCPServer(DB_PATH)
    
    print("MCP Server started", file=sys.stderr)
    print(f"Database: {DB_PATH}", file=sys.stderr)
    print("Listening for tool calls on stdin/stdout", file=sys.stderr)
    
    # Simple stdin/stdout protocol
    for line in sys.stdin:
        try:
            request = json.loads(line.strip())
            action = request.get("action")
            
            if action == "list_tools":
                response = {"tools": server.list_tools()}
            
            elif action == "call_tool":
                tool = request.get("tool")
                arguments = request.get("arguments", {})
                response = server.handle_tool_call(tool, arguments)
            
            else:
                response = {"success": False, "error": f"Unknown action: {action}"}
            
            print(json.dumps(response), flush=True)
        
        except json.JSONDecodeError as e:
            print(json.dumps({"success": False, "error": f"Invalid JSON: {e}"}), flush=True)
        except Exception as e:
            print(json.dumps({"success": False, "error": str(e)}), flush=True)

if __name__ == "__main__":
    main()
'@

$mcpServerCode | Out-File -FilePath "$mcpDir\mcp_server.py" -Encoding UTF8
Write-Host "MCP server created: $mcpDir\mcp_server.py" -ForegroundColor Green

# Step 3: Create startup script
Write-Host "Creating MCP server startup script..." -ForegroundColor Yellow
$startupScript = @"
# Start MCP Server
`$ErrorActionPreference = "Stop"

Write-Host "Starting MCP Server..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

# Start the server
python "$mcpDir\mcp_server.py"
"@

$startupScript | Out-File -FilePath "$mcpDir\start_server.ps1" -Encoding UTF8
Write-Host "Startup script created: $mcpDir\start_server.ps1" -ForegroundColor Green

# Step 4: Create test script
Write-Host "Creating MCP server test script..." -ForegroundColor Yellow
$testScript = @'
# Test MCP Server
$ErrorActionPreference = "Stop"

Write-Host "Testing MCP Server..." -ForegroundColor Cyan

$mcpDir = "C:\FoundryDemo\mcp-server"

# Test 1: List tools
Write-Host "`nTest 1: Listing available tools" -ForegroundColor Yellow
$request1 = @{action="list_tools"} | ConvertTo-Json -Compress
$response1 = $request1 | python "$mcpDir\mcp_server.py"
Write-Host $response1 -ForegroundColor Green

# Test 2: Get schema
Write-Host "`nTest 2: Getting database schema" -ForegroundColor Yellow
$request2 = @{action="call_tool"; tool="get_schema"; arguments=@{}} | ConvertTo-Json -Compress
$response2 = $request2 | python "$mcpDir\mcp_server.py"
Write-Host $response2 -ForegroundColor Green

# Test 3: Get table summary
Write-Host "`nTest 3: Getting table summary" -ForegroundColor Yellow
$request3 = @{action="call_tool"; tool="get_table_summary"; arguments=@{table_name="sales"}} | ConvertTo-Json -Compress
$response3 = $request3 | python "$mcpDir\mcp_server.py"
Write-Host $response3 -ForegroundColor Green

# Test 4: Execute query
Write-Host "`nTest 4: Executing SQL query" -ForegroundColor Yellow
$request4 = @{action="call_tool"; tool="execute_query"; arguments=@{query="SELECT * FROM sales LIMIT 3"}} | ConvertTo-Json -Compress
$response4 = $request4 | python "$mcpDir\mcp_server.py"
Write-Host $response4 -ForegroundColor Green

Write-Host "`nAll tests completed!" -ForegroundColor Green
'@

$testScript | Out-File -FilePath "$mcpDir\test_server.ps1" -Encoding UTF8
Write-Host "Test script created: $mcpDir\test_server.ps1" -ForegroundColor Green

# Step 5: Test the server
Write-Host "`nTesting MCP server..." -ForegroundColor Yellow
try {
    & "$mcpDir\test_server.ps1"
    Write-Host "MCP server test successful!" -ForegroundColor Green
} catch {
    Write-Warning "MCP server test failed: $_"
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "MCP Server Setup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Server Location: $mcpDir\mcp_server.py" -ForegroundColor Yellow
Write-Host ""
Write-Host "To start the server:" -ForegroundColor Yellow
Write-Host "  cd $mcpDir" -ForegroundColor Cyan
Write-Host "  .\start_server.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test the server:" -ForegroundColor Yellow
Write-Host "  .\test_server.ps1" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Next Step: Copy and run the agent application" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
