// Danger runs inside GitHub Actions (no external bot, no hosting) and posts a
// single summary comment enforcing PR hygiene. Rules are advisory (warn/
// message) except a couple of clear correctness guards.
const { danger, warn, message, fail } = require("danger");

const pr = danger.github.pr;
const files = [
  ...danger.git.created_files,
  ...danger.git.modified_files,
];

// 1. PRs should explain themselves.
if ((pr.body || "").trim().length < 20) {
  warn("Please add a short description of **what** this PR changes and **why**.");
}

// 2. Big PRs are hard to review.
const changes = pr.additions + pr.deletions;
if (changes > 600) {
  warn(`This PR touches ~${changes} lines. Consider splitting it into smaller, focused PRs.`);
}

// 3. The vendored engine layer should stay upstream's; flag edits to it.
const touchedVendor = files.filter((f) => f.includes("Sources/SideTerminal/Vendor/"));
if (touchedVendor.length > 0) {
  warn(
    "This PR edits the vendored engine layer (`Vendor/`). Prefer upstreaming " +
      "such changes; if intentional, explain why in the description."
  );
}

// 4. Engine build changes must go through patches/, never a committed clone.
if (files.some((f) => f.startsWith("ghostty/"))) {
  fail("The engine tree (`ghostty/`) must not be committed — use `patches/` instead.");
}

// 5. Nudge tests when core logic changes.
const touchedCore = files.some((f) => f.startsWith("app/Core/Sources/"));
const touchedCoreTests = files.some((f) => f.startsWith("app/Core/Tests/"));
if (touchedCore && !touchedCoreTests) {
  warn("You changed `app/Core` logic but no tests — consider adding or updating a test.");
}

if (changes <= 600 && touchedVendor.length === 0) {
  message("Thanks for the contribution! 🙌");
}
