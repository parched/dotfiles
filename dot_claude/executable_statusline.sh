#!/usr/bin/env bash
# Claude Code status line. Reads session JSON on stdin, prints one line.

input=$(cat)

IFS=$'\x1f' read -r model cwd project style used size ctx_tokens cost dur api_dur added removed < <(
  jq -r '[
    .model.display_name // "",
    .workspace.current_dir // .cwd // "",
    .workspace.project_dir // "",
    .output_style.name // "",
    (.context_window.used_percentage // "" | tostring),
    (.context_window.context_window_size // 0),
    ((.context_window.current_usage // {}) as $u
      | ($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)),
    (.cost.total_cost_usd // 0),
    (.cost.total_duration_ms // 0),
    (.cost.total_api_duration_ms // 0),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0)
  ] | map(tostring) | join("\u001f")' <<<"$input" 2>/dev/null
)
: "${size:=0}" "${ctx_tokens:=0}" "${cost:=0}" "${dur:=0}" "${api_dur:=0}" "${added:=0}" "${removed:=0}"

fmt_dur() {
  local s=$(($1 / 1000))
  if ((s >= 3600)); then printf '%dh%02dm' $((s / 3600)) $((s % 3600 / 60))
  elif ((s >= 60)); then printf '%dm%02ds' $((s / 60)) $((s % 60))
  else printf '%ds' "$s"
  fi
}

parts=()

[[ -n $model ]] && parts+=("$model")

# Directory: relative to the project when inside it, otherwise ~-abbreviated.
if [[ -n $cwd ]]; then
  if [[ -n $project && $cwd == "$project"* ]]; then
    dir=$(basename "$project")${cwd#"$project"}
  else
    dir=${cwd/#$HOME/\~}
  fi
  parts+=("$dir")
fi

# Git branch, dirty marker and ahead/behind upstream.
if [[ -n $cwd ]] && branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null); then
  git -C "$cwd" --no-optional-locks status --porcelain -uno 2>/dev/null | grep -q . && branch+="*"
  if counts=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null); then
    read -r behind ahead <<<"$counts"
    ((ahead > 0)) && branch+=" ↑$ahead"
    ((behind > 0)) && branch+=" ↓$behind"
  fi
  parts+=("$branch")
fi

# Context usage.
if [[ -n $used ]]; then
  ctx="ctx ${used%.*}%"
  ((size > 0)) && ctx+=" ($((ctx_tokens / 1000))k/$((size / 1000))k)"
  parts+=("$ctx")
else
  parts+=("ctx --")
fi

parts+=("$(printf '$%.2f' "$cost")")
parts+=("$(fmt_dur "$dur") (api $(fmt_dur "$api_dur"))")
parts+=("+$added −$removed")

[[ -n $style && $style != default ]] && parts+=("style:$style")

# Toolbox/container, if running inside one.
if [[ -f /run/.containerenv ]]; then
  name=$(sed -n 's/^name="\(.*\)"$/\1/p' /run/.containerenv)
  parts+=("⬢ ${name:-container}")
fi

# Kubernetes context, if configured.
if command -v kubectl >/dev/null && k8s=$(kubectl config current-context 2>/dev/null); then
  parts+=("⎈ $k8s")
fi

out=""
for p in "${parts[@]}"; do out+="${out:+ · }$p"; done
printf '%s\n' "$out"
