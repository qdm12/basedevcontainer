// Strict JSONC syntax check for devcontainer.json files.
//
// The devcontainer CLI parses its configuration with jsonc-parser in recovery
// mode: malformed JSON is silently repaired (junk tokens are dropped) and
// unknown top level properties are ignored, so it cannot be used as a lint step.
// This script reports every syntax error instead, with the offending line.
//
// Usage: node .github/actions/devcontainer-jsonc/check-jsonc.mjs [file...]
// Defaults to every devcontainer.json under .devcontainer.
// Exit code is 1 when at least one file has a syntax error.

import { parse as parseJsonc, printParseErrorCode } from "jsonc-parser";
import { readFile, glob } from "node:fs/promises";

const defaultPattern = ".devcontainer/**/devcontainer.json";
const paths = process.argv.slice(2);
const files = [];
for await (const entry of paths.length > 0 ? paths : glob(defaultPattern, { exclude: ["**/node_modules/**"] })) {
    files.push(entry);
}

if (files.length === 0) {
    console.error(`no file matched ${defaultPattern}`);
    process.exit(1);
}

let failingFiles = 0;
for (const file of files.sort()) {
    const content = await readFile(file, "utf8");
    // jsonc-parser signature is parse(text, errors, options). It never throws on
    // invalid input: it collects errors and returns a best effort value, so the
    // error list is the only thing to trust. Comments stay allowed, since
    // devcontainer.json is JSONC; trailing commas are not part of the spec.
    const errors = [];
    const configuration = parseJsonc(content, errors, { allowTrailingComma: false });
    const messages = errors.map(error => {
        const line = content.slice(0, error.offset).split("\n").length;
        return `${file}:${line}: ${printParseErrorCode(error.error)}`;
    });
    if (configuration === null || typeof configuration !== "object" || Array.isArray(configuration)) {
        messages.push(`${file}:1: a devcontainer.json must contain a single JSON object`);
    }
    if (messages.length === 0) {
        console.log(`OK      ${file}`);
        continue;
    }
    failingFiles++;
    for (const message of messages) {
        console.log(`ERROR   ${message}`);
    }
}

if (failingFiles > 0) {
    console.error(`${failingFiles} file(s) have JSONC syntax errors`);
    process.exit(1);
}
