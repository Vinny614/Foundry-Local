"""
Foundry Local + MCP Agent Application
This agent uses Foundry Local for inference and calls local MCP tools for data analysis
"""
import json
import subprocess
import sys
from typing import Any, Dict, List, Optional

# Configuration
FOUNDRY_MODEL = "phi-3-mini-4k-instruct"
MCP_SERVER_PATH = r"C:\FoundryDemo\mcp-server\mcp_server.py"

# MCP Tool Definitions for the model
MCP_TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "execute_query",
            "description": "Execute a read-only SQL SELECT query on the sales database to retrieve data. Use this to answer questions about sales, products, regions, and revenue.",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "SQL SELECT query to execute. Only SELECT statements are allowed. Example: SELECT * FROM sales WHERE region = 'East' LIMIT 10"
                    }
                },
                "required": ["query"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_schema",
            "description": "Get the database schema showing all tables and their columns. Use this to understand what data is available before querying.",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_table_summary",
            "description": "Get summary statistics and sample data for a table. Useful for understanding the structure and content of a table.",
            "parameters": {
                "type": "object",
                "properties": {
                    "table_name": {
                        "type": "string",
                        "description": "Name of the table to summarize (default: sales)"
                    }
                },
                "required": []
            }
        }
    }
]


class MCPClient:
    """Client for interacting with the local MCP server"""
    
    def __init__(self, server_path: str):
        self.server_path = server_path
    
    def call_tool(self, tool_name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Call an MCP tool and return the result"""
        request = {
            "action": "call_tool",
            "tool": tool_name,
            "arguments": arguments
        }
        
        try:
            # Call the MCP server via subprocess
            result = subprocess.run(
                [sys.executable, self.server_path],
                input=json.dumps(request) + "\n",
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0 and result.stdout:
                return json.loads(result.stdout)
            else:
                return {
                    "success": False,
                    "error": f"MCP server error: {result.stderr}"
                }
        
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "MCP server timeout"}
        except Exception as e:
            return {"success": False, "error": f"Failed to call MCP tool: {str(e)}"}


class FoundryLocalClient:
    """Client for interacting with Foundry Local"""
    
    def __init__(self, model: str):
        self.model = model
        self._check_service()
    
    def _check_service(self):
        """Check if Foundry Local service is running"""
        try:
            result = subprocess.run(
                ["foundry", "service", "status"],
                capture_output=True,
                text=True,
                timeout=10
            )
            print(f"Foundry Local status: {result.stdout}")
        except Exception as e:
            print(f"Warning: Could not check Foundry Local status: {e}")
    
    def chat_completion(
        self,
        messages: List[Dict[str, str]],
        tools: Optional[List[Dict[str, Any]]] = None,
        temperature: float = 0.7,
        max_tokens: int = 2000
    ) -> Dict[str, Any]:
        """
        Send a chat completion request to Foundry Local
        Note: Foundry Local may have limited tool/function calling support
        This is a simplified implementation
        """
        # Build prompt from messages
        prompt = self._build_prompt(messages, tools)
        
        # For demo purposes, we'll use foundry CLI to get response
        # In production, you'd use the REST API or SDK
        try:
            # Run foundry model with prompt
            result = subprocess.run(
                ["foundry", "model", "run", self.model],
                input=prompt,
                capture_output=True,
                text=True,
                timeout=120
            )
            
            response_text = result.stdout.strip() if result.returncode == 0 else result.stderr
            
            return {
                "choices": [
                    {
                        "message": {
                            "role": "assistant",
                            "content": response_text
                        },
                        "finish_reason": "stop"
                    }
                ]
            }
        
        except Exception as e:
            return {
                "choices": [
                    {
                        "message": {
                            "role": "assistant",
                            "content": f"Error calling Foundry Local: {str(e)}"
                        },
                        "finish_reason": "error"
                    }
                ]
            }
    
    def _build_prompt(
        self,
        messages: List[Dict[str, str]],
        tools: Optional[List[Dict[str, Any]]] = None
    ) -> str:
        """Build a prompt string from messages and tools"""
        prompt_parts = []
        
        # Add system message if present
        for msg in messages:
            if msg["role"] == "system":
                prompt_parts.append(f"System: {msg['content']}\n")
        
        # Add tool descriptions if tools are provided
        if tools:
            prompt_parts.append("\nAvailable Tools:\n")
            for tool in tools:
                func = tool.get("function", {})
                prompt_parts.append(f"- {func.get('name')}: {func.get('description')}\n")
        
        # Add conversation messages
        prompt_parts.append("\nConversation:\n")
        for msg in messages:
            if msg["role"] == "user":
                prompt_parts.append(f"User: {msg['content']}\n")
            elif msg["role"] == "assistant":
                prompt_parts.append(f"Assistant: {msg['content']}\n")
        
        prompt_parts.append("\nAssistant:")
        
        return "".join(prompt_parts)


class Agent:
    """Main agent that orchestrates Foundry Local and MCP tools"""
    
    def __init__(self):
        self.foundry = FoundryLocalClient(FOUNDRY_MODEL)
        self.mcp = MCPClient(MCP_SERVER_PATH)
        self.conversation_history: List[Dict[str, str]] = []
    
    def run(self, user_query: str) -> str:
        """Process a user query with tool calling"""
        print(f"\n{'='*60}")
        print(f"User Query: {user_query}")
        print(f"{'='*60}\n")
        
        # Step 1: Add user message to history
        self.conversation_history.append({
            "role": "user",
            "content": user_query
        })
        
        # Step 2: Get initial response from model with tool info
        system_message = {
            "role": "system",
            "content": (
                "You are a helpful data analyst assistant. You have access to a sales database with information about products, categories, regions, and revenue. "
                "When the user asks a question, determine if you need to query the database. "
                "If so, respond with a SQL query in the format: TOOL_CALL: execute_query | SELECT ... "
                "Otherwise, provide a direct answer. Be concise and helpful."
            )
        }
        
        messages = [system_message] + self.conversation_history
        
        print("Thinking...")
        response = self.foundry.chat_completion(messages, tools=MCP_TOOLS)
        
        assistant_message = response["choices"][0]["message"]["content"]
        print(f"\nInitial Response:\n{assistant_message}\n")
        
        # Step 3: Check if the model requested a tool call
        # Simple pattern matching for tool calls (since Foundry Local may not support native function calling)
        if "TOOL_CALL:" in assistant_message or "SELECT" in assistant_message.upper():
            # Extract SQL query
            sql_query = self._extract_sql_query(assistant_message)
            
            if sql_query:
                print(f"Executing SQL Query: {sql_query}\n")
                
                # Call MCP tool
                tool_result = self.mcp.call_tool("execute_query", {"query": sql_query})
                
                if tool_result.get("success"):
                    results = tool_result.get("results", [])
                    print(f"Query returned {len(results)} results\n")
                    
                    # Format results for the model
                    results_text = json.dumps(results, indent=2)
                    
                    # Get final analysis from model
                    self.conversation_history.append({
                        "role": "assistant",
                        "content": f"I queried the database with: {sql_query}"
                    })
                    
                    self.conversation_history.append({
                        "role": "user",
                        "content": f"Here are the query results:\n{results_text}\n\nPlease analyze these results and provide insights."
                    })
                    
                    print("Analyzing results...")
                    final_response = self.foundry.chat_completion(
                        [system_message] + self.conversation_history
                    )
                    
                    final_message = final_response["choices"][0]["message"]["content"]
                    self.conversation_history.append({
                        "role": "assistant",
                        "content": final_message
                    })
                    
                    return final_message
                else:
                    error_msg = f"Tool call failed: {tool_result.get('error')}"
                    print(f"Error: {error_msg}\n")
                    return error_msg
        
        # No tool call needed, return the response
        self.conversation_history.append({
            "role": "assistant",
            "content": assistant_message
        })
        
        return assistant_message
    
    def _extract_sql_query(self, text: str) -> Optional[str]:
        """Extract SQL query from model response"""
        # Look for SELECT statements
        lines = text.split("\n")
        for line in lines:
            line_upper = line.strip().upper()
            if line_upper.startswith("SELECT"):
                # Find the end of the query (semicolon or end of line)
                query = line.strip()
                if query.endswith(";"):
                    query = query[:-1]
                return query
        
        # Alternative: look for TOOL_CALL pattern
        if "TOOL_CALL:" in text:
            parts = text.split("TOOL_CALL:")
            if len(parts) > 1:
                tool_part = parts[1].strip()
                if "|" in tool_part:
                    query = tool_part.split("|", 1)[1].strip()
                    return query
        
        return None
    
    def get_schema(self) -> Dict[str, Any]:
        """Get database schema"""
        return self.mcp.call_tool("get_schema", {})
    
    def get_table_summary(self, table_name: str = "sales") -> Dict[str, Any]:
        """Get table summary"""
        return self.mcp.call_tool("get_table_summary", {"table_name": table_name})


def main():
    """Main entry point"""
    print("="*60)
    print("Foundry Local + MCP Agent Demo")
    print("Offline AI with Local Tool Calling")
    print("="*60)
    
    agent = Agent()
    
    # Example queries to demonstrate the system
    example_queries = [
        "What products do we have in the database?",
        "What are the top 5 products by revenue?",
        "Which region has the highest total sales?",
        "Show me sales data for the Electronics category",
    ]
    
    print("\nExample queries you can ask:")
    for i, query in enumerate(example_queries, 1):
        print(f"{i}. {query}")
    
    print("\n" + "="*60)
    print("Starting demo with example queries...")
    print("="*60)
    
    # Run example query
    example = example_queries[1]  # Top 5 products by revenue
    response = agent.run(example)
    
    print(f"\n{'='*60}")
    print("FINAL ANSWER:")
    print(f"{'='*60}")
    print(response)
    print(f"{'='*60}\n")
    
    # Interactive mode
    print("\nEnter 'quit' to exit, or ask a question:")
    while True:
        try:
            user_input = input("\nYou: ").strip()
            if user_input.lower() in ['quit', 'exit', 'q']:
                print("Goodbye!")
                break
            
            if user_input:
                response = agent.run(user_input)
                print(f"\n{'='*60}")
                print("ANSWER:")
                print(f"{'='*60}")
                print(response)
                print(f"{'='*60}")
        
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"\nError: {e}")


if __name__ == "__main__":
    main()
