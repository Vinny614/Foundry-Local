# Foundry Local + MCP Agent

This directory contains the agent application that combines Foundry Local (Phi model) with MCP tool calling for data analytics.

## Overview

The agent:
1. Receives natural language queries from users
2. Uses Foundry Local's Phi model for understanding and generation
3. Calls local MCP tools to query the SQLite database
4. Synthesizes results into natural language responses

## Files

- `agent.py` - Main agent application
- `requirements.txt` - Python dependencies
- `example_queries.txt` - Sample questions to try

## Installation

```powershell
# Install Python dependencies (if any beyond standard library)
pip install -r requirements.txt
```

## Usage

```powershell
# Run the agent
python agent.py
```

## Example Queries

1. "What products do we have in the database?"
2. "What are the top 5 products by revenue?"
3. "Which region has the highest total sales?"
4. "Show me sales data for the Electronics category"
5. "Compare sales between Electronics and Furniture categories"
6. "What is the total profit for each region?"

## Architecture

```
User Query
    ↓
[Foundry Local - Phi Model]
    ↓
Determine if tool call needed
    ↓
[MCP Client]
    ↓
[MCP Server] → [SQLite DB]
    ↓
Results
    ↓
[Foundry Local - Phi Model]
    ↓
Natural Language Response
```

## Offline Operation

This agent works completely offline once:
- Foundry Local has cached the Phi model
- The database is populated
- The MCP server script is available locally

No internet connection is required for inference or tool calls.
