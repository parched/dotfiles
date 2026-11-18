{{- /*
Renders a script that writes .content to .path, for files outside chezmoi's
target state (e.g. a dev container's CLAUDE_CONFIG_DIR). Renders nothing when
the file already matches, so chezmoi skips the script and `chezmoi diff` only
shows it, with a diff of the file as a comment, when there's a change.

Takes a dict: path (may start with ~) and content.
*/ -}}
{{- $path := regexReplaceAll "^~" .path (env "HOME") -}}
{{- $info := lstat $path -}}
{{- $isLink := and $info (eq $info.type "symlink") -}}
{{- $current := "" -}}
{{- if $info -}}
{{-   $current = include $path -}}
{{- end -}}
{{- if or $isLink (ne $current .content) -}}
#!/bin/sh
# Writes {{ $path }}{{ if $isLink }}, replacing the symlink there{{ end }}:
#
{{ output "sh" "-c" `[ -e "$1" ] || set -- /dev/null "$2" "$3"
printf '%s' "$3" | diff -u --label "$2" --label "$2" -- "$1" - | sed 's/^/# /'
:` "sh" $path $path .content -}}
set -eu
mkdir -p {{ dir $path | shellQuote }}
rm -f {{ $path | shellQuote }}
printf '%s' {{ .content | shellQuote }} > {{ $path | shellQuote }}
{{ end -}}
