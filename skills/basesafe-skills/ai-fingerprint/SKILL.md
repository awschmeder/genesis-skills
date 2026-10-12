---
name: ai-fingerprint
description: Generate comprehensive AI system fingerprint with architecture analysis and Strand generation. Use when analyzing AI/LLM systems for security assessment or system profiling.
# disable-model-invocation: true
# user-invocable: true
compatibility: "Paths use ${CLAUDE_SKILL_DIR} (Claude Code); elsewhere run from the skill root as scripts/..."
allowed-tools: Read Write Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/ai_fingerprint.py scan *) Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/ai_fingerprint.py embed *) Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/ai_fingerprint.py cheatsheet) Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/load_json_test.py *) Bash(mkdir -p *)
---

# AI Fingerprint - System Analysis and Strand Generation

You are executing the **AI Fingerprint** skill. This performs comprehensive AI system analysis and generates a unique strand fingerprint that characterizes the system's LLM, RAG, and Agentic properties.

## Architecture Overview

This skill is a **prompt-first architecture** where YOU (Claude Code) handle all reasoning and analysis, while Python utilities provide fast data operations (file scanning, strand generation).

## Your Task

Execute a 2-stage fingerprinting process that produces:
1. **System Analysis JSON**: Complete architectural analysis with security-relevant details
2. **Strand Fingerprint**: Compact string representation (e.g., `A1ITMX-S1N4NNED-NXNNXNN`)

## Arguments

The user provides a target directory path and optional flags.

Expected format: `<target_dir> [--output-dir <path>] [--ai-system-type <type>]`

Examples:
- `./my-app` — analyze my-app with defaults
- `./my-app --output-dir ./custom` — use custom output directory
- `./codebase --ai-system-type RAG` — focus on RAG system analysis

## Execution Steps

### EXECUTION GUIDE - APPLIES TO ALL PHASES AND STEPS
**When executing bash or unix (e.g. ls, wc, etc.) commands, never ever string them together into a single command.**
 - Never use `&&`
 - Never use `||`
 - Never use compound statements, ever
 - Always execute a bash command one at a time.
 - Always execute a unix command one-at-a-time, never compound them.

**When generating JSON, write it to disk with the Write tool, then validate it.**
 - Write the JSON file with the Write tool.
 - Validate it with `load_json_test.py` to confirm it parses.
 - Take your time. Fix and re-validate until it passes.

### Phase 0: Argument Parsing & Setup

**Parse these arguments:**
- `target_dir` (required): Path to AI system codebase to analyze
- `--output-dir <path>` (optional, default: derived from target)
- `--ai-system-type [LLM|RAG|Agentic|All]` (optional, default: All)

**Validate and set paths:**
1. Target directory exists and is readable
2. Derive output directory location (results will be created alongside the target directory):
Resolve absolute paths yourself (no shell substitution), then create the directory with a single command:
- `TARGET_DIR`: absolute path of the target
- `OUTPUT_DIR`: `<parent of TARGET_DIR>/ai_fingerprint_results/<target name>`, e.g. `/bob/ai_fingerprint_results/fish`

```bash
mkdir -p <absolute OUTPUT_DIR>
```

In the rest of this document `<OUTPUT_DIR>` and `<TARGET_DIR>` stand for those absolute paths; substitute them literally in commands.

**Scan codebase:**
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/ai_fingerprint.py scan <TARGET_DIR> --output <OUTPUT_DIR>/file_scan.json
```

This gives you a quick inventory of AI-related files without reading everything.

---

### Phase 1: System Analysis

**Objective**: Understand the codebase architecture from a security and AI systems perspective.

**Process:**

1. **Read the file scan results:**
Use the Read tool on <OUTPUT_DIR>/file_scan.json.

2. **Identify key files** to examine:
   - AI/LLM integration files (look for: openai, anthropic, langchain, etc.)
   - Configuration files
   - Entry points (main.py, app.py, index.js, etc.)
   - Agent/tool definition files
   - Database/vector store files

3. **Read critical files** (up to 20-30 files) focusing on:
   - AI/LLM integration points
   - Prompt construction
   - Input handling
   - Authentication/authorization
   - Data storage (vector DBs, regular DBs)
   - Tool definitions (for agentic systems)
   - RAG pipeline components

4. **Apply the system analysis prompt to yourself:**

Read the prompt at: `prompts/system_analysis.md`

Follow its instructions to analyze what you've learned about the codebase.

5. **Write structured JSON output:**

Save your analysis as JSON to:
```
<OUTPUT_DIR>/system_analysis.json
```

Use the JSON structure specified in the prompt. **CRITICAL**: Output ONLY valid JSON with no markdown code blocks or explanatory text.

**Validate the JSON:**

Validate the file with the bundled script:
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/load_json_test.py <OUTPUT_DIR>/system_analysis.json
```

If validation fails, fix the JSON and retry.

---

### Phase 2: Strand Generation

**Objective**: Generate a compact strand fingerprint from the system analysis.

**Process:**

1. **Generate and embed strand in one step:**
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/ai_fingerprint.py embed <OUTPUT_DIR>/system_analysis.json
```

This will:
- Generate the strand fingerprint from the analysis
- Add it as a top-level `"strand"` field in the JSON
- Save the updated JSON file

Example result:
```json
{
  "strand": "A1ITMX-S1N4NNED-NXNNXNN",
  "ai_system_type": "LLM",
  ...
}
```

2. **Display strand cheatsheet for user reference:**
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/ai_fingerprint.py cheatsheet
```

---

## Final Summary Presentation

Once all phases are complete, present a comprehensive summary to the user:

```
🎯 AI FINGERPRINT COMPLETE

Target: <target_name>
System Type: <detected_type>
Strand: <strand_fingerprint>

📊 System Characteristics:

LLM Component (6 chars): <llm_part>
  • Provider: <API/Local/Hybrid>
  • Models: <count>
  • Activity: <Inference/Training/Finetuning>
  • Modality: <input/output>

Agentic Component (8 chars): <agentic_part>
  • Topology: <single/multi/hierarchical>
  • Agent Count: <count>
  • Autonomy: <level>
  • Tools: <count>
  • Sandboxing: <level>
  • Human Gates: <present/none>

RAG Component (7 chars): <rag_part>
  • Pattern: <basic/advanced/agentic/none>
  • Retrieval: <dense/sparse/hybrid>
  • Corpus: <documents/tools/mixed>
  • Vector DB: <type>

🔍 Key Architecture Insights:
  • <insight 1>
  • <insight 2>
  • <insight 3>

📁 Output Files:
  • System Analysis: <OUTPUT_DIR>/system_analysis.json
  • File Scan: <OUTPUT_DIR>/file_scan.json
  • CWE Context: <OUTPUT_DIR>/cwe_context.txt
  • Strand Output: <OUTPUT_DIR>/strand_output.txt
  
📍 Output Location: Results are saved alongside the target directory at:
  <parent_of_target>/ai_fingerprint_results/<target_name>/
```

Include:
- The complete strand fingerprint
- Breakdown of what each component means
- Key architectural insights
- Security-relevant observations
- File locations for all outputs

---

## Integration with Other Skills

This fingerprinting skill is designed to be used as a **prerequisite** for security analysis skills like `battleprint`.

**Typical workflow:**

1. Run `ai-fingerprint` to generate system_analysis.json and strand
2. Use the system_analysis.json as input to downstream security tools
3. The strand provides a compact identifier for the system's profile

**Example:**
```bash
# Step 1: Generate fingerprint
/ai-fingerprint ./my-ai-app

# Step 2: Use fingerprint in security analysis
/battleprint ./my-ai-app
```

The battleprint skill can detect if a fingerprint already exists and reuse it, or generate a new one.

---

## Error Handling

**If file scanning fails:**
- Check target directory permissions
- Try manual file reading of key directories
- Continue with manual inventory

**If JSON validation fails:**
- load_json_test.py only reports VALID or INVALID; re-read the file to locate the error, then fix the JSON
- Ensure no markdown code blocks (````json) in output
- Ensure proper JSON syntax (quotes, commas, brackets)

**If strand generation fails:**
- Check that system_analysis.json is valid
- Verify strand.py script exists in battleprint skill
- Generate a fallback strand: `XXXXXX-XXXXXXXX-XXXXXXX`

**If CWE context is missing:**
- Continue without CWE classifications (less precise but still valuable)
- Note in output that CWE context was unavailable

---

## Important Notes

**Dependencies:**
- This skill includes all required Python utilities in the `scripts/` directory
- No external dependencies on battleprint_skill
- Scripts are standalone and self-contained

**Memory Efficiency**: 
- Don't try to read ALL files
- Use file scanning to identify the ~20-30 most relevant files
- Focus on AI-related, config, and entry point files

**JSON Quality**: 
- The system_analysis.json is critical for downstream tools
- Must be valid JSON with proper structure
- Use load_json_test.py to ensure correctness

**Strand Interpretation**:
- The strand is a compact fingerprint, not a full analysis
- Reference the cheatsheet for interpretation
- Each position encodes specific characteristics

**Output Quality**: 
- Provide evidence-based analysis with file references
- Include line numbers where relevant
- Be thorough but concise

---

## Technical Notes

- **No API keys needed**: You're already Claude Code, no external LLM calls
- **Pure Python utilities**: All helper scripts are non-LLM operations  
- **Prompt-driven analysis**: Your reasoning powers drive the analysis
- **Structured outputs**: JSON schemas ensure consistency
- **Reusable artifacts**: Outputs can be used by multiple downstream tools

This skill is the foundation for AI system security analysis - it creates the fingerprint that other tools can build upon!
