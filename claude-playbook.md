### goals
reduce token usage
-> reduce rewrites

reduce manual intervention

reduce worktime (not a priority)

keep the context low
-> less tokens
-> everything in the context not relevant to the current task reduces output quality
-> more reading https://code.claude.com/docs/en/costs#reduce-token-usage

### concepts
to improve output quality give claude a way to verify its outputs, tests, screenshots for design, linter, build exit code, or just some scripts that verify something in some way, etc.
a second agent verifiying the results of the first
plan first
for small tasks with a clear scope, dont use plan mode, as it adds overhead



### tools to guide claude
*constants*
Claude.md
rules

*variables*
skills
subagent

mcp server
LSP plugins


### in prompt good practises
be specific
use @ to refrence a file, usefull if you know where a problem is or where you want a change
if you want a solution based of a specific documentation, etc. specify its url directly instead of describing it
