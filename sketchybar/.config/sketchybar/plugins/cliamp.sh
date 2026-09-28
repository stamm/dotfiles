#!/bin/sh

# cliamp «now playing» для SketchyBar.
# Зависимости: cliamp (запущен и отдаёт IPC), jq.
# Опрос: update_freq=2 (см. sketchybarrc). Мышь: mouse.clicked / mouse.scrolled.
#
# Настройки через переменные окружения:
#   CLIAMP            путь к бинарю cliamp
#   CLIAMP_MAX_CHARS  максимум символов в лейбле
#   CLIAMP_SCROLL_UP / CLIAMP_SCROLL_DOWN  действие на скролл (next|prev)

# Иконки (Nerd Font, Font Awesome): play / pause / stop.
# Задаются байтами UTF-8, т.к. POSIX sh не умеет \u-escape.
ICON_PLAY="$(printf '\357\201\213')"   # U+F04B
ICON_PAUSE="$(printf '\357\201\214')"  # U+F04C
ICON_STOP="$(printf '\357\201\215')"   # U+F04D

CLIAMP="${CLIAMP:-/opt/homebrew/bin/cliamp}"
MAX_CHARS="${CLIAMP_MAX_CHARS:-40}"
SCROLL_UP_ACTION="${CLIAMP_SCROLL_UP:-prev}"
SCROLL_DOWN_ACTION="${CLIAMP_SCROLL_DOWN:-next}"

# --- Обработка мыши (не выходим: после действия сразу перечитываем статус) ---
case "$SENDER" in
  mouse.clicked)
    case "$BUTTON" in
      left)  "$CLIAMP" toggle >/dev/null 2>&1 ;;
      right) "$CLIAMP" next   >/dev/null 2>&1 ;;
    esac
    ;;
  mouse.scrolled)
    case "${SCROLL_DELTA:-0}" in
      -*) action="$SCROLL_DOWN_ACTION" ;;
      *)  action="$SCROLL_UP_ACTION" ;;
    esac
    "$CLIAMP" "$action" >/dev/null 2>&1
    ;;
esac

# --- Читаем состояние ---
raw="$("$CLIAMP" status --json 2>/dev/null)"

if [ -z "$raw" ] || ! printf '%s' "$raw" | jq -e '.ok == true' >/dev/null 2>&1; then
  # cliamp не запущен / IPC недоступен — прячем item
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

state="$(printf '%s' "$raw" | jq -r '.state // "stopped"')"
title="$(printf '%s' "$raw" | jq -r '.track.title // ""')"
artist="$(printf '%s' "$raw" | jq -r '.track.artist // ""')"

if [ -z "$title" ] || [ "$title" = "null" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

case "$state" in
  playing) icon="$ICON_PLAY" ;;
  paused)  icon="$ICON_PAUSE" ;;
  *)       icon="$ICON_STOP" ;;
esac

if [ -n "$artist" ] && [ "$artist" != "null" ]; then
  label="$artist — $title"
else
  label="$title"
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$icon" \
  label="$label" \
  label.max_chars="$MAX_CHARS"
