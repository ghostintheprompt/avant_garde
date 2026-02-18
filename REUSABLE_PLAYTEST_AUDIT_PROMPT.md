# REUSABLE PLAYTEST AUDIT PROMPT
## Sierra-Quality Pre-Launch Engineering Analysis

**Purpose:** Drag this file into any game workspace before playtest/launch to get comprehensive engineering audits.

**What This Does:** Runs 5 systematic audits (UI, Economy, Performance, Bugs, Code) to find issues before players do.

**Time Investment:**
- Analysis: 4-6 hours (Claude does this)
- Fixes: 10-20 hours (you do this)
- Result: Professional launch quality

---

## 🎯 THE PROMPT

Copy everything below the line and paste into Claude when you drag this file into a new workspace:

---

# PLAYTEST READINESS AUDIT REQUEST

I need a comprehensive pre-launch engineering audit for my game, similar to what Sierra On-Line, Dope Wars, and Gangbusters developers would do.

**Context:**
- Game: [YOUR GAME NAME]
- Genre: [GENRE]
- Platform: [Web/iOS/Android/Desktop]
- Status: [X months/years of development]
- Goal: Prepare for playtest and launch

**What I Need:**

Run all 5 Phase 1 audits sequentially, creating detailed markdown reports for each:

## AUDIT 1: UI/UX Polish (Sierra-Style)
**Focus:** Pixel-perfect interface, consistency, mobile-first design

**Analyze:**
1. Visual consistency across all screens
2. Color palette usage and brand coherence
3. Typography hierarchy and readability
4. Interaction feedback (hover, active, disabled states)
5. Touch target sizes (44x44px minimum for mobile)
6. Animation quality (60fps, GPU-accelerated)
7. Information hierarchy (most important content above fold)
8. Mobile optimization (iPhone SE to iPhone Pro Max)
9. Accessibility (WCAG AA compliance, color contrast)
10. Screen real estate efficiency (maximize content, minimize chrome)

**Deliverable:** SIERRA_UI_AUDIT_REPORT.md with:
- Critical/High/Medium/Low severity issues
- Specific file:line references
- Before/after recommendations
- Estimated fix time for each issue

---

## AUDIT 2: Game Economy/Loop Balance (Dope Wars-Style)
**Focus:** Risk/reward, addictive core loop, economic pressure

**Analyze:**
1. Core gameplay loop (map the cycle, timing, rewards)
2. Economic balance (starting capital, costs, profits)
3. Risk/reward proportionality (harder = more reward?)
4. Progression pacing (early/mid/late game difficulty curve)
5. Dominant strategies (is one approach obviously best?)
6. Resource pressure (are choices meaningful?)
7. "One more turn" factor (what drives replay?)
8. Soft-lock scenarios (can players get stuck?)
9. Exploit potential (money duplication, price manipulation)
10. Time pressure mechanics (loans, deadlines, decay)

**Deliverable:** ECONOMIC_BALANCE_REPORT.md with:
- Profitability analysis by strategy
- Risk/reward matrix
- Progression curve graph
- Balance recommendations with specific value changes
- Estimated tuning time

---

## AUDIT 3: Performance Profiling (60fps Mobile)
**Focus:** Load time, frame rate, battery, memory

**Analyze:**
1. Bundle size analysis (total, gzipped, by category)
2. Time to Interactive (target <2s on 4G)
3. Code splitting opportunities (lazy loading)
4. React optimization (memo, useCallback, useMemo usage)
5. CSS performance (GPU vs CPU rendering)
6. Animation frame rate (60fps target)
7. Memory usage and leaks
8. Battery drain estimation
9. Network usage (if online)
10. Device compatibility (oldest to newest target devices)

**Deliverable:** PERFORMANCE_PROFILING_REPORT.md with:
- Current vs target metrics
- Bottleneck identification
- Optimization priorities
- Estimated performance gains
- Implementation time for each fix

---

## AUDIT 4: Crash & Bug Hunt (Sierra-Style Testing)
**Focus:** Edge cases, soft-locks, crashes, data corruption

**Analyze:**
1. Error handling (try-catch coverage, error boundaries)
2. Data boundary testing (0, negative, null, undefined, NaN)
3. State machine validation (impossible states, race conditions)
4. Array operations (empty arrays, out-of-bounds access)
5. Division by zero protection
6. localStorage/save corruption handling
7. Game-over triggers (when should game end?)
8. Soft-lock scenarios (0 resources, stuck states)
9. User input validation (if applicable)
10. Edge case test scenarios (documented)

**Deliverable:** BUG_HUNT_REPORT.md with:
- Critical/High/Medium/Low bug priority
- Steps to reproduce each bug
- Soft-lock scenarios to test
- Fix recommendations with file references
- Estimated fix time

---

## AUDIT 5: Production Code Quality
**Focus:** Technical debt, maintainability, best practices

**Analyze:**
1. console.log statements (should be 0)
2. TypeScript strictness and 'any' usage
3. @ts-ignore pragmas (should be 0)
4. TODO/FIXME comments (categorize by urgency)
5. Code organization and architecture
6. Test coverage (if tests exist)
7. Linting/formatting setup (ESLint, Prettier)
8. Documentation quality (JSDoc, README)
9. Dead code and duplication
10. Security vulnerabilities (if applicable)

**Deliverable:** PRODUCTION_CODE_AUDIT.md with:
- Code quality score (1-10)
- Technical debt inventory
- Best practices observed
- Launch readiness verdict
- Post-launch recommendations

---

## FINAL DELIVERABLE: Executive Summary

**Create:** PLAYTEST_READINESS_SUMMARY.md with:
- Overall scores for each audit area
- Top 5-10 critical issues ranked by priority
- Estimated total fix time to playtest-ready
- Estimated total fix time to launch-ready
- Week-by-week launch plan
- Success metrics for launch day
- Clear go/no-go recommendation

---

## 📋 EXECUTION INSTRUCTIONS FOR CLAUDE

**Process:**
1. Read the entire codebase (don't just spot check)
2. Analyze all code, data, and config files
3. Run each audit sequentially (1 → 2 → 3 → 4 → 5)
4. Create detailed markdown reports (be specific, not generic)
5. Include file:line references for every issue
6. Provide actionable fix recommendations
7. Estimate fix time for each issue
8. Create final executive summary

**Quality Standards:**
- Sierra On-Line: Pixel-perfect UI, no crashes, polished
- Dope Wars: Addictive risk/reward loop, balanced economy
- Gangbusters: Meaningful choices, no soft-locks, player agency

**Tone:**
- Professional but honest
- Specific, not vague
- Actionable recommendations
- Celebrate strengths, identify weaknesses
- Clear priorities (must fix vs nice to have)

**Output:**
- 6-7 markdown files (5 audits + 1 summary + optional prompts doc)
- ~150-200 pages total
- Ready to execute fixes immediately

---

## ⏱️ EXPECTED TIMELINE

**Claude's Work (4-6 hours):**
- Audit 1: UI/UX (1-1.5 hrs)
- Audit 2: Economy (1 hr)
- Audit 3: Performance (1 hr)
- Audit 4: Bugs (1-1.5 hrs)
- Audit 5: Code (1 hr)
- Summary (30 min)

**Your Work (10-20 hours):**
- Critical fixes (5-10 hrs)
- High priority fixes (5-10 hrs)
- Medium priority (defer to v1.1)

**Total:** ~2 weeks from audit to playtest

---

## 🎯 SUCCESS CRITERIA

**After audits complete, you should have:**
- Clear list of 5-10 critical issues
- Estimated fix time for each
- Prioritized roadmap to launch
- Confidence in launch quality
- No surprises during playtest

**Red Flags to Watch For:**
- >20 hours of critical fixes (too much, scope down)
- Multiple "rebuild this system" recommendations (too late)
- 0 console logs but crashes exist (false confidence)
- UI inconsistencies (players notice immediately)
- Soft-lock scenarios (playtest disaster)

---

## 🚀 HOW TO USE THIS PROMPT

**Step 1: Prepare Your Game**
- [ ] Code is in stable state (builds without errors)
- [ ] Feature-complete (or very close)
- [ ] 4-12 weeks from target launch date
- [ ] Ready to hear hard truths

**Step 2: Run The Audit**
1. Open Claude Code (CLI or API)
2. Navigate to your game directory
3. Drag this file into workspace OR paste prompt
4. Type: "proceed" and let Claude work
5. Claude will run all 5 audits sequentially

**Step 3: Review Reports**
- Read PLAYTEST_READINESS_SUMMARY.md first
- Then dive into specific audit reports
- Prioritize critical fixes
- Create fix schedule

**Step 4: Execute Fixes**
- Start with critical issues (launch blockers)
- Then high priority (professional polish)
- Defer medium/low to v1.1 unless time permits

**Step 5: Playtest**
- Fix critical issues BEFORE sending to testers
- Use playtest to validate fixes
- Iterate based on real feedback

---

## 💡 CUSTOMIZATION TIPS

**For Different Game Types:**

**Mobile Game (iOS/Android):**
- Emphasize performance (battery, memory, load time)
- Focus on touch targets and one-thumb use
- Check App Store guideline compliance
- Test on oldest supported device

**Web Game (Browser):**
- Emphasize bundle size and load time
- Check cross-browser compatibility
- Test on 3G connection
- Optimize for both desktop and mobile

**Desktop Game (Steam/Epic):**
- Less emphasis on bundle size
- More emphasis on settings/options
- Check for common crash scenarios
- Performance across GPU ranges

**Narrative Game:**
- Economy audit focuses on pacing, not min-maxing
- UI audit focuses on readability
- Bug audit focuses on soft-locks and story breaks

**Action Game:**
- Performance is CRITICAL (60fps minimum)
- Input latency testing
- Frame drops during intense moments

**Strategy Game:**
- Economy audit is CRITICAL (balance, exploits)
- UI audit focuses on information density
- Bug audit focuses on edge case strategies

---

## 📊 EXPECTED FINDINGS (Typical Results)

**Most games at this stage have:**
- 5-10 critical issues (2-10 hours to fix)
- 10-15 high priority issues (5-15 hours to fix)
- 20-30 medium issues (defer to v1.1)
- 50+ low priority issues (nice-to-haves)

**Common Critical Issues:**
- UI inconsistency (partial redesigns)
- No error handling (localStorage, network)
- Performance problems (bundle size, no optimization)
- Game balance issues (dominant strategies)
- Soft-lock scenarios (0 resources, impossible states)

**Rare But Possible:**
- "This is launch-ready, just ship it" (5% of games)
- "This needs 40+ hours of work" (rebuild territory)
- "Code quality is excellent but game is unbalanced"
- "Game is fun but code is a mess" (tech debt)

---

## 🎓 LEARNING FROM AUDITS

**After your first audit:**
- Study the reports to understand what Claude looks for
- Note patterns in your weak areas
- Apply learnings to next game during development
- Use reports as checklist during dev (prevent issues)

**After your second audit:**
- Compare to first audit (did you improve?)
- Build reusable components/systems that pass audits
- Create your own pre-launch checklist
- Internalize quality standards

**After your third audit:**
- You'll anticipate most issues
- Audits become validation, not discovery
- Faster fixes (you've seen these before)
- Ship cleaner games from the start

---

## 📝 NOTES

**What This Prompt Does Well:**
- Finds issues before players do
- Provides actionable fix plans
- Estimates time investment accurately
- Celebrates your strengths, identifies weaknesses

**What This Prompt Doesn't Do:**
- Doesn't playtest (you need real humans)
- Doesn't design features (just audits what exists)
- Doesn't write fixes (gives recommendations)
- Doesn't judge creative decisions (only technical)

**Best Used When:**
- 80-90% feature complete
- 4-12 weeks from launch
- Code is stable (not mid-refactor)
- Ready to invest 10-20 hours in polish

**Don't Use If:**
- Just started development (<50% complete)
- Actively rebuilding core systems
- No time to fix issues found (what's the point?)
- Looking for validation, not honest feedback

---

## 🔄 VERSION HISTORY

**v1.0 (Feb 2026) - Neon Leviathan**
- Initial prompt based on 2-year whaling sim audit
- 5 audits: UI, Economy, Performance, Bugs, Code
- ~200 pages of reports
- Successfully identified 15.5 hours of critical fixes

**Future Versions:**
- Could add: Accessibility audit (WCAG, screen readers)
- Could add: Multiplayer audit (if applicable)
- Could add: Monetization audit (IAP, ads)
- Could add: Content audit (writing quality, typos)

---

## 📧 SUPPORT

**If audits reveal issues you don't understand:**
1. Ask Claude to explain specific findings in detail
2. Ask for code examples showing the fix
3. Ask for alternative solutions
4. Prioritize ruthlessly (not everything is critical)

**If estimated fix time seems wrong:**
- Claude bases on typical developer speed
- Adjust for your experience level
- Some fixes cascade (fixing one reveals more)
- Add 50% buffer for unknowns

**If reports seem too harsh:**
- Remember: finding issues now >> finding during playtest
- Sierra-quality standards are HIGH (that's the point)
- Your code is probably better than you think
- Focus on critical issues, defer the rest

---

## 🎯 FINAL CHECKLIST

**Before running this audit:**
- [ ] Game is 80%+ feature complete
- [ ] Code builds without errors
- [ ] You have 4-12 weeks until launch
- [ ] You're ready to spend 10-20 hours fixing issues
- [ ] You want honest feedback, not validation

**After audit complete:**
- [ ] Read summary report first
- [ ] Understand all critical issues
- [ ] Create fix schedule
- [ ] Timebox fixes (don't gold-plate)
- [ ] Fix critical issues BEFORE playtest

**Before playtest:**
- [ ] All critical bugs fixed
- [ ] Performance is acceptable (not perfect)
- [ ] UI is consistent (not pixel-perfect)
- [ ] No soft-locks or crashes
- [ ] TestFlight/build works on real devices

**Ready to ship when:**
- [ ] Playtest feedback is positive
- [ ] No crash reports
- [ ] Performance meets targets
- [ ] UI polish complete
- [ ] All launch blockers resolved

---

## 🏁 CONCLUSION

**This prompt represents 4-6 hours of Claude's work analyzing your game with Sierra-quality standards.**

**Use it wisely:**
- Run 4-12 weeks before launch
- Take findings seriously
- Prioritize ruthlessly
- Fix critical issues
- Ship something great

**Your players won't know about the bugs you prevented.**

**But they'll FEEL the quality.**

**That's what this audit is for.** 🎮

---

**END OF REUSABLE PROMPT**

**Usage:** Drag this file into next game workspace → Copy prompt section → Paste to Claude → Type "proceed"
