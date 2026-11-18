# cr <角色> [其他 claude 参数]：在当前目录以指定角色启动或恢复会话
# 当前目录就是项目目录。用法：在 shell 配置里加一行 source ~/.claude/roles/cr.sh
#   cr architect             新开 architect 会话，当前目录只读
#   cr engineer --continue   恢复 engineer 会话，角色文件重新带上
# 环境变量 CR_CLAUDE 指定启动的命令名或路径，不能带参数；没设置时用 claude。
cr() {
  local role=${1:-}
  if [ -z "$role" ]; then
    local roles_dir="$HOME/.claude/roles"
    echo "用法: cr <角色> [其他 claude 参数]" >&2
    echo "  cr architect             新开 architect 会话，当前目录只读" >&2
    echo "  cr engineer --continue   恢复 engineer 会话，角色文件重新带上" >&2
    echo >&2
    local names=() f
    for f in "$roles_dir"/*.md; do
      [ -f "$f" ] && names+=("$(basename "$f" .md)")
    done
    if [ "${#names[@]}" -gt 0 ]; then
      echo "可用角色（$roles_dir）：${names[*]}" >&2
    else
      echo "没有找到角色文件（$roles_dir）" >&2
    fi
    echo >&2
    echo "环境变量 CR_CLAUDE 指定启动的命令名或路径，不能带参数；没设置时用 claude。" >&2
    return 1
  fi
  shift
  local file="$HOME/.claude/roles/$role.md"
  if [ ! -f "$file" ]; then
    echo "cr: 没有角色文件 $file" >&2
    return 1
  fi
  local extra=()
  if [ "$role" = architect ]; then
    if [ "$PWD" = "$HOME" ] || [ "$PWD" = / ]; then
      echo "cr: 当前目录是 $PWD，不像项目目录；先 cd 到项目目录再启动 architect" >&2
      return 1
    fi
    # 逻辑路径与物理路径都加上，路径里有符号链接时规则仍然生效
    local physical
    physical=$(pwd -P)
    local rules="\"Edit(/$PWD/**)\""
    if [ "$physical" != "$PWD" ]; then
      rules="$rules,\"Edit(/$physical/**)\""
    fi
    extra=(--settings "{\"permissions\":{\"deny\":[$rules]}}")
  fi
  # 默认会把首次请求的系统提示词记录下来，恢复时原样复用，改过的角色文件要到下次压缩才生效；
  # 关掉记录，每次启动都用当前的角色文件
  "${CR_CLAUDE:-claude}" --append-system-prompt-file "$file" --system-prompt-snapshot off "${extra[@]}" "$@"
}
