# Scratch Area Documentation

**This documentation has been restructured as a skill.**

Please see [SKILL.md](SKILL.md) for the complete working-in-scratch-areas skill documentation.

## Quick Summary

- **Setup:** Run `~/workspace/pickled-scratch-area/setup-scratch-area.sh` from repository root
- **Usage:** Save one-off scripts and documents to `.scratch/` subdirectories (not root)
- **Scripts:** Always use shebang, make executable with helper script, call directly
- **Documentation:** Every file needs a header with purpose and context
- **Organization:** Use subdirectories with README files to group related work
- **Archiving:** Never delete - add retrospective comments instead
- **Git:** Never use `git add .` - always use explicit paths to avoid committing `.scratch/` files
- **No /tmp:** Never use `/tmp` or project `tmp/` - always use `.scratch/`

See SKILL.md for complete workflows and best practices.
