// Assert that `devcontainer up` reported success, from the log it was teed to.
//
// The CLI prints its result as a single JSON object on the last line, but that
// line arrives on the merged stream (the result is not on stdout alone), so the
// log is scanned backwards for the outermost JSON object rather than trusting
// one stream. `set -o pipefail` covers a non zero exit of the CLI itself.
//
// Usage: node .github/actions/devcontainer-up/assert-devcontainer-up.mjs <log file>
// Exit code is 1 when the log holds no result, or a result other than success.

import { readFile } from "node:fs/promises";

const logPath = process.argv[2];
if (!logPath) {
    console.error("usage: assert-devcontainer-up.mjs <devcontainer up log file>");
    process.exit(2);
}

const content = await readFile(logPath, "utf8");
const lines = content.split("\n");
let result = null;
for (let index = lines.length - 1; index >= 0; index--) {
    const trimmed = lines[index].trim();
    if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
        try {
            result = JSON.parse(trimmed);
            break;
        } catch {
            // A log line can contain braces, keep looking upwards.
        }
    }
}

if (result === null || result.outcome === undefined) {
    console.error(`${logPath}: no devcontainer up result found`);
    process.exit(1);
}
if (result.outcome !== "success") {
    console.error(`devcontainer up reported outcome "${result.outcome}"`);
    process.exit(1);
}
console.log(`devcontainer up succeeded (container ${result.containerId ?? "?"}, remote user ${result.remoteUser ?? "?"})`);
