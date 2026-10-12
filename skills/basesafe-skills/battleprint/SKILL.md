---
name: battleprint
description: Perform red and blue team adversarial analysis on AI systems. Use after ai-fingerprint to identify attack vectors and defense strategies for LLM/RAG/Agentic systems.
# disable-model-invocation: true
# user-invocable: true
compatibility: "Paths use ${CLAUDE_SKILL_DIR} (Claude Code); elsewhere run from the skill root as scripts/..."
allowed-tools: Read Write Agent Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/load_json_test.py *) Bash(mkdir -p *)
# requires: ai-fingerprint
---

# Battleprint - Agentic Execution of Red and Blue Team Security Analysis

You are executing the **Battleprint** skill. This performs a red and blue team adversarial analysis sequence.

## Architecture Overview

This skill is a **prompt-first architecture** where YOU (Claude Code) handle all reasoning and analysis, while a bundled Python script validates the JSON files and the ai-fingerprint skill supplies the system analysis.

## Your Task

Execute a 4-stage analysis process that produces:
1. **Red Stage 1**: Complete red team analysis of the target code base
2. **Blue Stage 1**: Complete blue team analysis of the target code base
3. **Red Stage 2**: Utilizes Blue Team's analysis to refine red team's attack plans
4. **Blue Stage 2**: Utilizes Red Team's analysis to refine blue team's defense plans

## Arguments

The user provides a target directory path.

Expected format: `<target_dir>`

Examples:
- `./my-app` — analyze my-app directory
- `/bob/fish` — analyze absolute path

## Required Skills                                        
  - `ai-fingerprint`: Generates file_scan.json and system_analysis.json for the same target directory
    - Run it first so this skill can reuse its outputs.
    - Output location: `<parent>/ai_fingerprint_results/<target_name>/`  

## Execution Steps

### EXECUTION GUIDE - APPLIES TO ALL PHASES AND STEPS
**When executing bash or unix (e.g. ls, wc, etc.) commands, never ever string them together into a single command.**
 - Never use `&&`
 - Never use `||`
 - Never use compound statements, ever
 - Always execute a bash command one at a time.
 - Always execute a unix command one-at-a-time, never compound them.

**When generating JSON, never output it directly into the conversation.**
 - Write the JSON to its file with the Write tool.
 - Then validate it with `python3 ${CLAUDE_SKILL_DIR}/scripts/load_json_test.py <file>`.
 - Never write ad-hoc Python to generate or validate JSON.

### Phase 0: Setup and Check for AI-FingerPrint

**Parse and set paths:**

Resolve these absolute paths yourself (no shell needed):
- `TARGET_DIR`: the absolute path of the target directory
- `TARGET_BASE`: the parent directory of `TARGET_DIR`
- `TARGET_NAME`: the final path component of `TARGET_DIR`
- `FINGERPRINT_DIR`: `<TARGET_BASE>/ai_fingerprint_results/<TARGET_NAME>`
- `OUTPUT_DIR`: `<TARGET_BASE>/battleprint_results/<TARGET_NAME>`

Then create the output directory with a single command: `mkdir -p <absolute OUTPUT_DIR>`.

All subsequent references to these names mean the absolute paths; substitute them literally in commands.

**Verify fingerprint exists:**
1. Check if `$FINGERPRINT_DIR/system_analysis.json` exists
2. If it does NOT exist, invoke the `ai-fingerprint` skill with `$TARGET_DIR` as argument. Use a SEPARATE AGENT (via Agent tool) for this to prevent context bleed.
3. Read `$FINGERPRINT_DIR/file_scan.json` and `$FINGERPRINT_DIR/system_analysis.json` into the current context.

---

### Phase 1: Stage 1 Red and Blue

**Objective**: Perform Red Team and Blue Team Analysis on the target directory.

**Process:**

1. **Read the file scan results:**
Use the Read tool on "$FINGERPRINT_DIR/file_scan.json".

2. **Read the system analysis results:**
Use the Read tool on "$FINGERPRINT_DIR/system_analysis.json".

3. **Parallel Execute 2 Agents**
   
   Use the Agent tool to spawn two agents in parallel. Each Agent invocation is automatically in fresh context.
   
   a. Red Team Agent - use `prompts/red_team_stage1.md` with the fingerprint data
   b. Blue Team Agent - use `prompts/blue_team_stage1.md` with the fingerprint data
   
   Each agent should write its output to:
   - Red: `$OUTPUT_DIR/red_stage_1.json`
   - Blue: `$OUTPUT_DIR/blue_stage_1.json`

4. **Verify Stage 1 Complete**

Validate each file with the bundled script:
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/load_json_test.py <OUTPUT_DIR>/red_stage_1.json
```
and 
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/load_json_test.py <OUTPUT_DIR>/blue_stage_1.json
```
### Phase 2: Stage 2 Red and Blue

**Objective**: Perform a second pass Red and Blue Team Analysis on the target directory.

**Note:** Each Agent tool invocation automatically runs in fresh context - no special action needed.

**Red Team Agent (Stage 2)**
1. **Read the file scan results:**
Use the Read tool on "$FINGERPRINT_DIR/file_scan.json".

2. **Read the system analysis results:**
Use the Read tool on "$FINGERPRINT_DIR/system_analysis.json".

3. **Read blue team's plans:**
Use the Read tool on "$OUTPUT_DIR/blue_stage_1.json".

4. **Execute Red Team Stage 2**
   
   Use Agent tool with `prompts/red_team_stage2.md` and the above context.
   
   Write output to: `$OUTPUT_DIR/red_stage_2.json`

5. **Verify Stage 2 Complete**
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/load_json_test.py <OUTPUT_DIR>/red_stage_2.json
```

**Blue Team Agent (Stage 2)**
1. **Read the file scan results:**
Use the Read tool on "$FINGERPRINT_DIR/file_scan.json".

2. **Read the system analysis results:**
Use the Read tool on "$FINGERPRINT_DIR/system_analysis.json".

3. **Read red team's plans:**
Use the Read tool on "$OUTPUT_DIR/red_stage_1.json".

4. **Execute Blue Team Stage 2**
   
   Use Agent tool with `prompts/blue_team_stage2.md` and the above context.
   
   Write output to: `$OUTPUT_DIR/blue_stage_2.json`

5. **Verify Stage 2 Complete**
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/load_json_test.py <OUTPUT_DIR>/blue_stage_2.json
```

### Phase 3: Synthesis

Perform synthesis and provide final results:

1. Output a final_analysis.json with the top 8 exploits found in red_team 2. Did blue_team 2 have an answer for these?
2. Provide an analysis of the efficacy of this battleprint algorithm:
   a. Did the blue team improve from stage 1 to stage 2 (i.e. did it utilize the knowledge it gained by reading red team plans and improve its defenses against these?). If so, how?
   b. Did the red team improve from stage 1 to stage 2? If so, how?
3. Provide final recommendations (top 3) for the engineering team to address. When providing these top 3, be sure to utilize the system analysis to note which AI System and sub-system are most affected.
4. Provide a weakness indicator for each element in the strand. Use relative weakness (i.e. element with the highest relative weakness gets a 10, element with no relative weakness gets a 0).

**All output should be in 2 forms:**
1. JSON file: `$OUTPUT_DIR/final_analysis.json` (enables downstream processing)
2. Markdown file: `$OUTPUT_DIR/final_analysis.md` (allows for easy readability)

**Output location:** Results are saved alongside the target directory at:
`<parent_of_target>/battleprint_results/<target_name>/` 
