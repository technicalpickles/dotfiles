# Bedrock Claude Model Pricing

AWS Bedrock does not expose pricing via API, so pricing must be manually updated periodically.

## Usage

### Generate environment variables for Fish shell

```bash
# Show selected models and eval command
bin/bedrock-claude-models

# Set environment variables
eval (bin/bedrock-claude-models --eval)
```

### Generate JSON for Claude Code settings

```bash
# Output JSON that can be added to ~/.claude/settings.json
bin/bedrock-claude-models --json
```

Example output:

```json
{
  "env": {
    "ANTHROPIC_MODEL": "anthropic.claude-opus-4-5-20251101-v1:0",
    "ANTHROPIC_SMALL_FAST_MODEL": "anthropic.claude-haiku-4-5-20251001-v1:0",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "anthropic.claude-sonnet-4-5-20250929-v1:0",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "anthropic.claude-haiku-4-5-20251001-v1:0",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "anthropic.claude-opus-4-5-20251101-v1:0"
  }
}
```

You can merge this into your `~/.claude/settings.json` file to use these models with Claude Code.

### View pricing information

```bash
bin/bedrock-claude-models --pricing
```

---

## Quick Update Process

### 1. Save the pricing page

1. Visit https://aws.amazon.com/bedrock/pricing/ in your browser
2. **File > Save Page As... > Format: Webpage, Complete**
3. Save as `Pricing.html` in the dotfiles directory

### 2. Extract and save pricing

```bash
cd ~/workspace/dotfiles
bin/bedrock-parse-pricing --save
```

This will:

1. Parse pricing from `Pricing.html`
2. Save JSON data to `config/bedrock-claude-pricing.json`
3. Display a human-readable table

The output table looks like:

```
| Model                                    | Input (per 1K tokens) | Output (per 1K tokens) | Input (per MTok) | Output (per MTok) |
|------------------------------------------|-----------------------|------------------------|------------------|-------------------|
| Claude Opus 4.5                          | $0.005                | $0.025                 | $5.00  /MTok     | $25.00 /MTok      |
| Claude Sonnet 4.5                        | $0.003                | $0.015                 | $3.00  /MTok     | $15.00 /MTok      |
| Claude Haiku 4.5                         | $0.001                | $0.005                 | $1.00  /MTok     | $5.00  /MTok      |
```

### 3. Verify the update

The pricing data is now stored in `config/bedrock-claude-pricing.json` and includes the date it was updated:

```json
{
  "lastUpdated": "2025-12-02",
  "source": "https://aws.amazon.com/bedrock/pricing/",
  "models": {
    "Claude Opus 4.5": { "inputPerMTok": 5.0, "outputPerMTok": 25.0 },
    "Claude Sonnet 4.5": { "inputPerMTok": 3.0, "outputPerMTok": 15.0 },
    "Claude Haiku 4.5": { "inputPerMTok": 1.0, "outputPerMTok": 5.0 }
  }
}
```

The `bin/bedrock-claude-models` script automatically reads from this file.

### 4. Test

```bash
bin/bedrock-claude-models --pricing
```

Verify the pricing looks correct.

## Notes

- **Global Cross-region Inference** pricing is shown by default (slightly higher than regional)
- Different regions have slightly different prices (typically 10% higher for cross-region)
- The script shows approximate pricing - always verify at https://aws.amazon.com/bedrock/pricing/
- Update pricing every 3-6 months or when new models are released
- Pricing is stored in `config/bedrock-claude-pricing.json` with a timestamp for tracking when it was last updated

## Files

- `bin/bedrock-claude-models` - Main script (queries Bedrock, generates env vars, reads pricing from JSON)
- `bin/bedrock-parse-pricing` - Helper to extract pricing from saved HTML and save to JSON
- `config/bedrock-claude-pricing.json` - Parsed pricing data with timestamp (version controlled)
- `Pricing.html` - Saved copy of pricing page (gitignored, update locally)
- `doc/bedrock-pricing.md` - This documentation
