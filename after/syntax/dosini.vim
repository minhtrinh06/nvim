" Also highlight space-separated `Key value` pairs (fluent-bit style .conf)
syntax match dosiniLabel "^\s*\k\+\ze\s\+\S"
" Builtin dosini only matches comments at column 1; allow indented ones too
syntax match dosiniComment "^\s*[#;].*$" contains=dosiniTodo,@Spell
