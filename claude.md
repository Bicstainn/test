# Project Sage - Development Guidelines

> **IMPORTANT**: Read this file FIRST before any development task.

---

## Core Principles

### Principle 1: Think Before Code
**Please think in English. Give yourself more time to think before you start coding.**

- Analyze the requirement thoroughly before implementation
- Consider edge cases and potential conflicts with existing code
- Plan the approach mentally before writing any code
- When in doubt, explore the codebase first

### Principle 2: Reuse Over Create
**Use existing variables instead of creating new ones. Connect to existing resources instead of adding new ones.**

- Always search for existing variables/functions that serve the purpose
- Check `Vari.md` for the current variable registry before creating new ones
- Extend existing modules rather than creating parallel structures
- If a similar component exists, refactor it to be reusable instead of duplicating

### Principle 3: Keep Variable Registry Updated
**Sync the variable name list (`Vari.md`) after every addition or removal of variables.**

- After adding a new variable: immediately update `Vari.md`
- After removing a variable: immediately remove it from `Vari.md`
- Include variable name, type, purpose, and location
- This is non-negotiable - no commit without registry sync

---

## Quick Checklist

Before coding:
- [ ] Read and understand the requirement
- [ ] Check existing code for reusable components
- [ ] Review `Vari.md` for existing variables

After coding:
- [ ] Update `Vari.md` if variables changed
- [ ] Verify no duplicate variables were created
- [ ] Test the changes work with existing systems
