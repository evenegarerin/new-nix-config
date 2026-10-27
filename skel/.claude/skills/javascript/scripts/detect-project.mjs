#!/usr/bin/env node
// Read-only detector for a JavaScript project's conventions.
// Usage: node detect-project.mjs [dir] [--json]
// Prints a short summary (or JSON with --json). Never writes files or installs anything.

import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join, resolve, relative } from 'node:path';

const args = process.argv.slice(2);
const asJson = args.includes('--json');
const startDir = resolve(args.find((a) => !a.startsWith('--')) ?? process.cwd());

const readJson = (file) => {
  try {
    return JSON.parse(readFileSync(file, 'utf8'));
  } catch {
    return null;
  }
};
const readText = (file) => {
  try {
    return readFileSync(file, 'utf8').trim();
  } catch {
    return null;
  }
};

// Walk up from `from`, returning the first directory where predicate(dir) is true.
// Stops at the filesystem root or after passing a .git directory (repo boundary).
function findUp(from, predicate) {
  let dir = from;
  while (true) {
    if (predicate(dir)) return dir;
    if (existsSync(join(dir, '.git'))) return null;
    const parent = dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

const pkgDir = findUp(startDir, (d) => existsSync(join(d, 'package.json')));
const pkg = pkgDir ? readJson(join(pkgDir, 'package.json')) ?? {} : {};

const LOCKFILES = [
  ['pnpm-lock.yaml', 'pnpm'],
  ['yarn.lock', 'yarn'],
  ['bun.lock', 'bun'],
  ['bun.lockb', 'bun'],
  ['package-lock.json', 'npm'],
  ['npm-shrinkwrap.json', 'npm'],
  ['deno.lock', 'deno'],
];
const lockDir = findUp(pkgDir ?? startDir, (d) => LOCKFILES.some(([f]) => existsSync(join(d, f))));
const lockfiles = lockDir ? LOCKFILES.filter(([f]) => existsSync(join(lockDir, f))) : [];

// packageManager field (corepack) beats lockfile; check nearest pkg, then the lock/root pkg.
const rootPkg = lockDir && lockDir !== pkgDir ? readJson(join(lockDir, 'package.json')) ?? {} : pkg;
const pmField = pkg.packageManager ?? rootPkg.packageManager;
const packageManager = pmField?.split('@')[0] ?? lockfiles[0]?.[1] ?? (pkgDir ? 'npm (no lockfile found)' : null);

const warnings = [];
if (new Set(lockfiles.map(([, pm]) => pm)).size > 1) {
  warnings.push(`Multiple lockfiles (${lockfiles.map(([f]) => f).join(', ')}): ask which package manager is canonical.`);
}

// Monorepo detection
const workspaceRoot = findUp(pkgDir ?? startDir, (d) => {
  if (existsSync(join(d, 'pnpm-workspace.yaml'))) return true;
  const p = readJson(join(d, 'package.json'));
  return Boolean(p?.workspaces);
});
const monorepoTools = workspaceRoot
  ? ['turbo.json', 'nx.json', 'lerna.json'].filter((f) => existsSync(join(workspaceRoot, f)))
  : [];

const allDeps = {
  ...rootPkg.dependencies, ...rootPkg.devDependencies,
  ...pkg.dependencies, ...pkg.devDependencies, ...pkg.peerDependencies,
};
const has = (name) => Object.hasOwn(allDeps, name);
const fileIn = (dirs, names) =>
  dirs.filter(Boolean).flatMap((d) => names.filter((n) => existsSync(join(d, n))).map((n) => relative(startDir, join(d, n)) || n));

const configDirs = [...new Set([pkgDir, workspaceRoot, lockDir])];

// Module system
const moduleSystem = pkg.type === 'module' ? 'ESM ("type": "module")' : pkgDir ? 'CommonJS by default (.mjs files are ESM)' : 'unknown';

// Runtime targets
const nodeVersionFiles = Object.fromEntries(
  ['.nvmrc', '.node-version']
    .map((f) => [f, configDirs.map((d) => d && readText(join(d, f))).find(Boolean)])
    .filter(([, v]) => v),
);
const toolVersions = configDirs.map((d) => d && readText(join(d, '.tool-versions'))).find(Boolean);
const nodeFromToolVersions = toolVersions?.split('\n').find((l) => /^(nodejs|node)\s/.test(l))?.split(/\s+/)[1];
const browserslist =
  pkg.browserslist ?? (fileIn(configDirs, ['.browserslistrc']).length ? 'see .browserslistrc' : null);

// Tooling
const pick = (map) => Object.entries(map).filter(([, test]) => test()).map(([name]) => name);
const anyConfig = (names) => fileIn(configDirs, names).length > 0;

const testFrameworks = pick({
  vitest: () => has('vitest'),
  jest: () => has('jest') || anyConfig(['jest.config.js', 'jest.config.cjs', 'jest.config.mjs', 'jest.config.ts']),
  mocha: () => has('mocha'),
  ava: () => has('ava'),
  'node:test': () => /node\s+(--[\w-]+\s+)*--test/.test(Object.values(pkg.scripts ?? {}).join('\n')),
  playwright: () => has('@playwright/test'),
  cypress: () => has('cypress'),
});
const linters = pick({
  eslint: () => has('eslint') || anyConfig(['eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs', '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json']),
  biome: () => has('@biomejs/biome') || anyConfig(['biome.json', 'biome.jsonc']),
  oxlint: () => has('oxlint'),
  standard: () => has('standard'),
  xo: () => has('xo'),
});
const formatters = pick({
  prettier: () => has('prettier') || anyConfig(['.prettierrc', '.prettierrc.json', '.prettierrc.js', '.prettierrc.cjs', '.prettierrc.mjs', 'prettier.config.js', 'prettier.config.mjs']),
  biome: () => linters.includes('biome'),
});
const types = pick({
  typescript: () => has('typescript') || anyConfig(['tsconfig.json']),
  'checkJs (JSDoc types are enforced)': () =>
    configDirs.some((d) => {
      if (!d) return false;
      const raw = readText(join(d, 'jsconfig.json')) ?? readText(join(d, 'tsconfig.json'));
      return raw ? /"checkJs"\s*:\s*true/.test(raw) : false;
    }),
});
const frameworks = pick({
  react: () => has('react'), next: () => has('next'), vue: () => has('vue'), nuxt: () => has('nuxt'),
  svelte: () => has('svelte'), angular: () => has('@angular/core'), solid: () => has('solid-js'),
  express: () => has('express'), fastify: () => has('fastify'), hono: () => has('hono'), koa: () => has('koa'),
  nestjs: () => has('@nestjs/core'), electron: () => has('electron'), vite: () => has('vite'),
  webpack: () => has('webpack'), esbuild: () => has('esbuild'), rollup: () => has('rollup'),
});

const scripts = pkg.scripts ?? {};
const run = (name) => {
  if (!scripts[name]) return null;
  const pm = (packageManager ?? 'npm').split(' ')[0];
  if (pm === 'npm') return name === 'test' ? 'npm test' : `npm run ${name}`;
  if (pm === 'deno') return `deno task ${name}`;
  return `${pm} ${name === 'test' ? 'test' : `run ${name}`}`;
};
const verifyCommands = Object.fromEntries(
  ['lint', 'typecheck', 'type-check', 'check', 'test', 'test:unit', 'build', 'format', 'format:check']
    .map((s) => [s, run(s)])
    .filter(([, cmd]) => cmd),
);
if (!pkgDir) warnings.push('No package.json found: treat as standalone script(s); verify with `node --check` and a direct run.');
if (pkgDir && !scripts.test) warnings.push('No "test" script: find out how tests run before adding any, or verify by running the code directly.');
if (testFrameworks.length > 1) warnings.push(`Several test tools (${testFrameworks.join(', ')}): match the one used by the nearest existing test file.`);

const sample = (() => {
  // Show a couple of existing test files so new tests can copy their style.
  if (!pkgDir) return [];
  const out = [];
  const walk = (dir, depth) => {
    if (depth > 4 || out.length >= 3) return;
    let entries = [];
    try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      if (out.length >= 3) return;
      if (e.name === 'node_modules' || e.name.startsWith('.') || e.name === 'dist' || e.name === 'build') continue;
      const p = join(dir, e.name);
      if (e.isDirectory()) walk(p, depth + 1);
      else if (/\.(test|spec)\.[cm]?[jt]sx?$/.test(e.name) || (/[\\/]__tests__[\\/]/.test(p) && /\.[cm]?[jt]sx?$/.test(e.name))) out.push(relative(startDir, p));
    }
  };
  walk(pkgDir, 0);
  return out;
})();

const result = {
  packageDir: pkgDir ? relative(startDir, pkgDir) || '.' : null,
  packageName: pkg.name ?? null,
  packageManager,
  lockfiles: lockfiles.map(([f]) => f),
  monorepo: workspaceRoot ? { root: relative(startDir, workspaceRoot) || '.', tools: monorepoTools } : null,
  moduleSystem,
  exports: pkg.exports ? 'defined (keep public entry points stable)' : null,
  targets: {
    node: pkg.engines?.node ?? nodeVersionFiles['.nvmrc'] ?? nodeVersionFiles['.node-version'] ?? nodeFromToolVersions ?? pkg.volta?.node ?? null,
    nodeVersionFiles,
    browserslist,
  },
  testFrameworks,
  existingTestFiles: sample,
  linters,
  formatters,
  types,
  frameworks,
  verifyCommands,
  warnings,
};

if (asJson) {
  console.log(JSON.stringify(result, null, 2));
} else {
  const line = (label, value) => {
    if (value == null || (Array.isArray(value) && value.length === 0) || (typeof value === 'object' && !Array.isArray(value) && Object.keys(value).length === 0)) return;
    const text = Array.isArray(value) ? value.join(', ') : typeof value === 'object' ? JSON.stringify(value) : value;
    console.log(`${label.padEnd(18)} ${text}`);
  };
  line('Package', result.packageName ? `${result.packageName} (${result.packageDir})` : result.packageDir);
  line('Package manager', result.packageManager);
  line('Lockfiles', result.lockfiles);
  line('Monorepo', result.monorepo && `root ${result.monorepo.root}${result.monorepo.tools.length ? ` (${result.monorepo.tools.join(', ')})` : ''}`);
  line('Modules', result.moduleSystem);
  line('Exports', result.exports);
  line('Node target', result.targets.node);
  line('Browsers', typeof result.targets.browserslist === 'string' ? result.targets.browserslist : result.targets.browserslist && JSON.stringify(result.targets.browserslist));
  line('Tests', result.testFrameworks);
  line('Test examples', result.existingTestFiles);
  line('Lint', result.linters);
  line('Format', result.formatters);
  line('Types', result.types);
  line('Frameworks', result.frameworks);
  if (Object.keys(verifyCommands).length) {
    console.log('Verify with:');
    for (const [name, cmd] of Object.entries(verifyCommands)) console.log(`  ${name.padEnd(12)} ${cmd}`);
  }
  for (const w of warnings) console.log(`! ${w}`);
}
