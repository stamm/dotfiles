#!/bin/sh

# opencode-go.sh — использование подписки OpenCode Go в SketchyBar.
#
# Источник: GET https://opencode.ai/console/api/go/status
#   Authorization: Bearer <access-токен>  (берётся из opencode.db, таблица credential)
# Ответ: access.meters.{fiveHour,week,month} c usedMicroCents/limitMicroCents/resetsAt
# (плюс startsAt у пятичасового и недельного окна) и access.{startsAt,endsAt}.
# Одна сотая доллара = 1e6 microcents, то есть $ = microcents / 1e8.
#
# В баре: R{p}% W{p}% M{p}% (rolling/weekly/monthly) отдельными item'ами:
# подписи R/W/M белые, цветом подсвечивается только число того окна, чей
# процент дошёл до порога (по умолчанию 75 — жёлтый, 90 — красный).
# Иконка-чип красится по худшему из трёх окон.
# По клику открывается popup с деталями: точный процент, суммы в долларах
# и время сброса, темп с начала окна, прогноз месяца к дате продления,
# спарклайн дневного расхода и таблица использования по моделям за диапазон.
# Опрос: update_freq=60 (см. sketchybarrc). События: mouse.clicked,
# mouse.exited.global.
#
# Настройки через переменные окружения (или $CONFIG_DIR/opencode-go.env, chmod 600):
#   OPENCODE_GO_TOKEN       Bearer-токен (иначе читается из БД OpenCode)
#   OPENCODE_GO_ORG         workspace id  (x-opencode-org-id), необязательно
#   OPENCODE_GO_STATUS_API  эндпоинт статуса (по умолчанию .../console/api/go/status)
#   OPENCODE_GO_TTL         TTL кэша статуса в секундах (по умолчанию 60)
#   OPENCODE_GO_DB          путь к opencode.db
#   OPENCODE_GO_CONSOLE_URL хост консоли (по умолчанию https://opencode.ai/console)
#   OPENCODE_GO_USAGE_API   эндпоинт usage/models (по умолчанию .../api/usage/models)
#   OPENCODE_GO_RANGE       диапазон usage/models: 24h|7d|30d|all (по умолчанию 30d)
#   OPENCODE_GO_MODELS_TTL  TTL кэша usage/models в секундах (по умолчанию 300)
#   OPENCODE_GO_MODELS_LIMIT сколько моделей показывать (по умолчанию 6)
#   OPENCODE_GO_ACTIVITY_API эндпоинт дневного расхода Go (.../api/activity/go)
#   OPENCODE_GO_ACTIVITY_TTL TTL кэша activity в секундах (по умолчанию 300)
#   OPENCODE_GO_SPARK       спарклайн дневного расхода (1|0; по умолчанию 1)
#   OPENCODE_GO_NAMES_TTL   TTL кэша имён models.dev в секундах (86400)
#   OPENCODE_GO_WARN_PCT    порог жёлтой подсветки окна в баре (75)
#   OPENCODE_GO_CRIT_PCT    порог красной подсветки окна в баре (90)
#   OPENCODE_GO_BAR         полоса скорости сжигания 5ч-окна (1|0; по умолчанию 1)
#   OPENCODE_GO_BAR_WIDTH   ширина полосы в ячейках (по умолчанию 6)
#   OPENCODE_GO_SUSTAIN     «устойчивый» темп, он же 1×, %/ч (по умолчанию 20)
#   DRY_RUN=1               печатать команды sketchybar вместо применения
#
# Полоса (item opencode_go.burn): показывает средний темп с начала текущего
# 5ч-окна — скорость сжигания в %/ч, нормированную на SUSTAIN. Середина полосы
# = 1× (100% ровно за 5 ч). Цвет полосы — непрерывный градиент:
# зелёный (≤1×) → жёлтый (1.5×) → красный (≥2×).

set -u

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
[ -f "$CONFIG_DIR/opencode-go.env" ] && . "$CONFIG_DIR/opencode-go.env"

NAME="${NAME:-opencode_go}"
# Якорь попапа и иконки: при mouse-событии на opencode_go.r/.w/.m NAME содержит
# точку, а попап висит на базовом item'е opencode_go.
ROOT="${NAME%%.*}"
TTL="${OPENCODE_GO_TTL:-60}"
DB="${OPENCODE_GO_DB:-${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db}"

# --- Статус подписки Go: точные microcents по трём окнам ---
CONSOLE_URL="${OPENCODE_GO_CONSOLE_URL:-https://opencode.ai/console}"
STATUS_API="${OPENCODE_GO_STATUS_API:-$CONSOLE_URL/api/go/status}"
STATUS_CACHE="${TMPDIR:-/tmp}/sketchybar-opencode-go-status.json"

# --- Разбивка по моделям: Console Usage API (JSON) ---
MODELS_API="${OPENCODE_GO_USAGE_API:-$CONSOLE_URL/api/usage/models}"
USAGE_RANGE="${OPENCODE_GO_RANGE:-30d}"
MODELS_TTL="${OPENCODE_GO_MODELS_TTL:-300}"
MODELS_LIMIT="${OPENCODE_GO_MODELS_LIMIT:-6}"
MODELS_MAX=8
MODELS_CACHE="${TMPDIR:-/tmp}/sketchybar-opencode-models.json"
NAMES_CACHE="${TMPDIR:-/tmp}/sketchybar-modelnames.json"
NAMES_TSV="${TMPDIR:-/tmp}/sketchybar-modelnames.tsv"
NAMES_TTL="${OPENCODE_GO_NAMES_TTL:-86400}"

# --- Дневной расход Go: Console Activity API (JSON) ---
ACTIVITY_API="${OPENCODE_GO_ACTIVITY_API:-$CONSOLE_URL/api/activity/go}"
ACTIVITY_TTL="${OPENCODE_GO_ACTIVITY_TTL:-300}"
ACTIVITY_CACHE="${TMPDIR:-/tmp}/sketchybar-opencode-activity.json"
SPARK="${OPENCODE_GO_SPARK:-1}"

# --- Полоса скорости сжигания 5ч-окна (rolling) ---
BAR="${OPENCODE_GO_BAR:-1}"
BAR_W="${OPENCODE_GO_BAR_WIDTH:-6}"
SUSTAIN="${OPENCODE_GO_SUSTAIN:-20}"

# Иконки (Nerd Font). Задаются байтами UTF-8: POSIX sh не умеет \u-escape.
ICON_GO="$(printf '\357\213\233')"    # U+F2DB nf-fa-microchip
ICON_WARN="$(printf '\357\201\261')"  # U+F071 nf-fa-warning

# Цвета (палитра из конфига opencode).
C_GREEN="0xff98c379"
C_YELLOW="0xffe5c07b"
C_RED="0xffe06c75"
C_HEAD="0xff7f849c"   # приглушённый — буквы окон, заголовок таблицы моделей
# Числа окон: тот же оттенок, но полупрозрачный — визуально бледнее.
C_VAL="0xbfb8bfc9"    # белый на ~75% альфы
C_VAL_WARN="0xd0e5c07b"  # жёлтый
C_VAL_CRIT="0xe0e06c75"  # красный

# Иконка-чип в баре: цвет по худшему окну, но приглушённый (альфа ~70%).
C_CHIP_OK="0xb398c379"
C_CHIP_WARN="0xb3e5c07b"
C_CHIP_CRIT="0xb3e06c75"

# Пороги подсветки значений окон в баре (в процентах):
# ниже WARN — белый, WARN..CRIT — жёлтый, CRIT и выше — красный.
WARN_PCT="${OPENCODE_GO_WARN_PCT:-75}"
CRIT_PCT="${OPENCODE_GO_CRIT_PCT:-90}"
WARN_P10=$((WARN_PCT * 10))
CRIT_P10=$((CRIT_PCT * 10))

# RGB-каналы опорных цветов градиента (из C_GREEN/C_YELLOW/C_RED).
G_R=0x98; G_G=0xc3; G_B=0x79
Y_R=0xe5; Y_G=0xc0; Y_B=0x7b
R_R=0xe0; R_G=0x6c; R_B=0x75

# Символы полосы (UTF-8 байтами).
BLK_FULL="$(printf '\342\226\210')"   # U+2588 █
BLK_EMPTY="$(printf '\342\226\221')"  # U+2591 ░
BAR_L="$(printf '\342\226\217')"      # U+258F ▏
BAR_R="$(printf '\342\226\225')"      # U+2595 ▕

# Спарклайн: U+2581..U+2588, от низкого к высокому.
SPARK_GLYPHS="$(printf '\342\226\201') $(printf '\342\226\202') $(printf '\342\226\203') $(printf '\342\226\204') $(printf '\342\226\205') $(printf '\342\226\206') $(printf '\342\226\207') $BLK_FULL"

TAB="$(printf '\t')"

sb() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    # Печатаем через "$@", а не "$*": "$*" склеивает аргументы по первому
    # символу IFS, который в цикле по строкам таблицы равен переводу строки.
    printf 'sketchybar'
    printf ' %s' "$@"
    printf '\n'
  else
    sketchybar "$@"
  fi
}

# Цвет по десятым долям процента (иконка-сводка и строки попапа).
sev_color10() {
  case "$1" in
    ''|*[!0-9]*) printf '%s' "$C_GREEN" ;;
    *) if [ "$1" -ge "$CRIT_P10" ]; then printf '%s' "$C_RED"
       elif [ "$1" -ge "$WARN_P10" ]; then printf '%s' "$C_YELLOW"
       else printf '%s' "$C_GREEN"; fi ;;
  esac
}

# Цвет числа окна в баре: ниже порога — бледный белый, иначе жёлтый/красный.
val_color10() {
  case "$1" in
    ''|*[!0-9]*) printf '%s' "$C_VAL" ;;
    *) if [ "$1" -ge "$CRIT_P10" ]; then printf '%s' "$C_VAL_CRIT"
       elif [ "$1" -ge "$WARN_P10" ]; then printf '%s' "$C_VAL_WARN"
       else printf '%s' "$C_VAL"; fi ;;
  esac
}

# Цвет иконки-чипа в баре: по худшему окну, но приглушённый.
chip_color10() {
  case "$1" in
    ''|*[!0-9]*) printf '%s' "$C_CHIP_OK" ;;
    *) if [ "$1" -ge "$CRIT_P10" ]; then printf '%s' "$C_CHIP_CRIT"
       elif [ "$1" -ge "$WARN_P10" ]; then printf '%s' "$C_CHIP_WARN"
       else printf '%s' "$C_CHIP_OK"; fi ;;
  esac
}

# Целое неотрицательное?
is_num() {
  case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac
}

# microcents -> доллары с двумя знаками.
usd() { awk -v c="$1" 'BEGIN{ if (c < 0) c = 0; printf "$%.2f", c / 100000000 }'; }

# Десятые доли процента -> строка с одним знаком (4.2).
pct1() { awk -v p="$1" 'BEGIN{ printf "%.1f", p / 10 }'; }

# Десятые доли процента -> округлённое целое для бара (42 -> 4, 17 -> 2, 8 -> 1).
pct_int() { printf '%d' "$(( ($1 + 5) / 10 ))"; }

# Эпоха -> дата/время (macOS date -r, иначе GNU date -d).
fmt_date() {
  date -r "$1" "$2" 2>/dev/null || date -d "@$1" "$2" 2>/dev/null || printf '?'
}

# Линейная интерполяция канала: c0 + (c1-c0)*t/steps (целые).
lerp() { printf '%d' "$(( $1 + ($2 - $1) * $3 / $4 ))"; }

# Цвет полосы по ratio*1000: ≤1× зелёный, 1→1.5 зел.→жёлт., 1.5→2 жёлт.→красный, ≥2 красный.
grade_color() {
  rm_=${1:-0}
  [ "$rm_" -le 1000 ] && { printf '%s' "$C_GREEN"; return; }
  [ "$rm_" -ge 2000 ] && { printf '%s' "$C_RED"; return; }
  if [ "$rm_" -le 1500 ]; then
    t=$((rm_ - 1000))
    r=$(lerp "$G_R" "$Y_R" "$t" 500); g=$(lerp "$G_G" "$Y_G" "$t" 500); b=$(lerp "$G_B" "$Y_B" "$t" 500)
  else
    t=$((rm_ - 1500))
    r=$(lerp "$Y_R" "$R_R" "$t" 500); g=$(lerp "$Y_G" "$R_G" "$t" 500); b=$(lerp "$Y_B" "$R_B" "$t" 500)
  fi
  printf '0xff%02x%02x%02x' "$r" "$g" "$b"
}

# Полоса 0..2, заполнение слева, середина = 1× (ratio*1000 == 1000).
bar_string() {
  rm_=${1:-0}; w=${2:-6}
  is_num "$w" && [ "$w" -gt 0 ] || w=6
  [ "$rm_" -lt 0 ] && rm_=0
  [ "$rm_" -gt 2000 ] && rm_=2000
  filled=$(( (rm_ * w + 1000) / 2000 ))
  [ "$filled" -gt "$w" ] && filled=$w
  s=""; i=0
  while [ "$i" -lt "$w" ]; do
    if [ "$i" -lt "$filled" ]; then s="$s$BLK_FULL"; else s="$s$BLK_EMPTY"; fi
    i=$((i + 1))
  done
  printf '%s%s%s' "$BAR_L" "$s" "$BAR_R"
}

# --- Секция "Usage by Model" в попапе (заполняется ниже) ---
NAME_W=27

# Скрыть всю секцию моделей.
models_hide() {
  sb --set "$NAME.models_title" drawing=off
  sb --set "$NAME.model_head" drawing=off
  i=1
  while [ "$i" -le "$MODELS_MAX" ]; do
    sb --set "$NAME.model.$i" drawing=off
    i=$((i + 1))
  done
}

# Скрыть прогноз и спарклайн (нет токена, данных или подписки).
extra_hide() {
  sb --set "$NAME.forecast" drawing=off
  sb --set "$NAME.spark" drawing=off
}

# Показать одну строку-подсказку вместо таблицы.
models_hint() {
  sb --set "$NAME.models_title" drawing=on label="$1" label.color="$C_HEAD"
  sb --set "$NAME.model_head" drawing=off
  i=1
  while [ "$i" -le "$MODELS_MAX" ]; do
    sb --set "$NAME.model.$i" drawing=off
    i=$((i + 1))
  done
}

# --- Обработка мыши: попап по клику (toggle), данные не перезапрашиваем ---
case "${SENDER:-routine}" in
  mouse.clicked)
    # Только левая кнопка: правый/средний клик по чипу игнорируем.
    [ "${BUTTON:-left}" = "left" ] || exit 0
    # Состояние читаем у SketchyBar, а не храним в файле: так оно не
    # рассинхронизируется после перезагрузки/перезапуска бара.
    if [ "$(sketchybar --query "$ROOT" 2>/dev/null \
            | jq -r '.popup.drawing' 2>/dev/null)" = "on" ]; then
      sb --set "$ROOT" popup.drawing=off
    else
      sb --set "$ROOT" popup.drawing=on
    fi
    exit 0
    ;;
  mouse.exited.global)
    sb --set "$ROOT" popup.drawing=off
    exit 0
    ;;
esac

# Item'ы .r/.w/.m несут скрипт только ради mouse-событий (обработаны выше);
# их содержимое обновляет основной item opencode_go, routine-опрос им не нужен.
[ "$NAME" = "$ROOT" ] || exit 0

# --- Учётные данные: env, иначе строка из БД OpenCode (active, integration=opencode) ---
TOKEN="${OPENCODE_GO_TOKEN:-}"
ORG="${OPENCODE_GO_ORG:-}"
if [ -z "$TOKEN" ] && command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  cred="$(sqlite3 -readonly "$DB" \
    "SELECT value FROM credential WHERE active=1 AND integration_id='opencode' ORDER BY time_updated DESC LIMIT 1;" \
    2>/dev/null || true)"
  if [ -n "$cred" ] && command -v jq >/dev/null 2>&1; then
    TOKEN="$(printf '%s' "$cred" | jq -r '.access // empty' 2>/dev/null || true)"
    [ -n "$ORG" ] || ORG="$(printf '%s' "$cred" | jq -r '.metadata.orgID // empty' 2>/dev/null || true)"
  fi
fi

if [ -z "$TOKEN" ]; then
  # Нет токена — прячем item, чтобы не мусорить в баре.
  sb --set "$ROOT" drawing=off
  sb --set "$ROOT.r" drawing=off
  sb --set "$ROOT.w" drawing=off
  sb --set "$ROOT.m" drawing=off
  sb --set "$ROOT.burn" drawing=off
  sb --set "$NAME.pace" drawing=off
  extra_hide
  exit 0
fi

# --- Статус: свежий кэш или запрос ---
now="$(date +%s)"
body=""
stale=0
if [ -f "$STATUS_CACHE" ]; then
  mt="$(stat -f %m "$STATUS_CACHE" 2>/dev/null || stat -c %Y "$STATUS_CACHE" 2>/dev/null || echo 0)"
  if [ "$((now - mt))" -lt "$TTL" ] 2>/dev/null; then
    body="$(cat "$STATUS_CACHE" 2>/dev/null || true)"
  fi
fi

if [ -z "$body" ]; then
  if [ -n "$ORG" ]; then
    body="$(curl -fsS -m 10 -H "Authorization: Bearer $TOKEN" -H "x-opencode-org-id: $ORG" \
      -H "Accept: application/json" "$STATUS_API" 2>/dev/null || true)"
  else
    body="$(curl -fsS -m 10 -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/json" "$STATUS_API" 2>/dev/null || true)"
  fi
  # Валидный ответ: есть ключ access (null — подписки нет) либо meters.
  if printf '%s' "$body" | jq -e \
      'has("access") and (if .access == null then true else (.access.meters.month.usedMicroCents != null) end)' \
      >/dev/null 2>&1; then
    printf '%s' "$body" > "$STATUS_CACHE" 2>/dev/null || true
  else
    body=""
  fi
fi

if [ -z "$body" ] && [ -f "$STATUS_CACHE" ]; then
  body="$(cat "$STATUS_CACHE" 2>/dev/null || true)"
  stale=1
fi

if [ -z "$body" ] || ! command -v jq >/dev/null 2>&1; then
  sb --set "$ROOT" drawing=on icon="$ICON_WARN" icon.color="$C_RED" label.drawing=on label="n/a" label.color="$C_RED"
  sb --set "$ROOT.r" drawing=off
  sb --set "$ROOT.w" drawing=off
  sb --set "$ROOT.m" drawing=off
  sb --set "$NAME.rolling" icon.drawing=off label="Не удалось получить данные OpenCode Go" label.color="$C_RED"
  sb --set "$NAME.weekly" icon.drawing=off label=""
  sb --set "$NAME.monthly" icon.drawing=off label=""
  sb --set "$NAME.pace" drawing=off
  sb --set "$ROOT.burn" drawing=off
  models_hide
  extra_hide
  exit 0
fi

# Подписки нет — молча скрываем виджет.
if printf '%s' "$body" | jq -e 'has("access") and .access == null' >/dev/null 2>&1; then
  sb --set "$ROOT" drawing=off
  sb --set "$ROOT.r" drawing=off
  sb --set "$ROOT.w" drawing=off
  sb --set "$ROOT.m" drawing=off
  sb --set "$ROOT.burn" drawing=off
  sb --set "$NAME.pace" drawing=off
  sb --set "$ROOT" popup.drawing=off
  models_hide
  extra_hide
  exit 0
fi

# --- Парсинг: key <tab> used <tab> limit <tab> pct10 <tab> reset <tab> countdown <tab> reset_ep <tab> start_ep <tab> access_start ---
rows="$(printf '%s' "$body" | jq -r --argjson now "$now" '
  def cd($now):
    ((. - $now) | if . < 0 then 0 else . end) as $s
    | (($s/86400)|floor) as $d
    | ((($s%86400)/3600)|floor) as $h
    | ((($s%3600)/60)|floor) as $m
    | (if $d>0 then "\($d)d \($h)h"
       elif $h>0 then "\($h)h \($m)m"
       else "\($m)m" end);
  def ep: (try ((. // "") | sub("\\.[0-9]+";"") | sub("\\+00:00$";"Z") | fromdateiso8601) catch null);
  (.access.startsAt | ep) as $astart
  | .access.meters
  | [ ["rolling", .fiveHour], ["weekly", .week], ["monthly", .month] ][]
  | .[0] as $k | .[1] as $m
  | ($m.resetsAt | ep) as $r
  | ($m.startsAt | ep) as $s
  | [ $k,
      (($m.usedMicroCents // "0") | tonumber),
      (($m.limitMicroCents // "0") | tonumber),
      (((($m.usedMicroCents // "0") | tonumber) * 1000 / (($m.limitMicroCents // "1") | tonumber)) | round),
      (if $r == null then "?" else ($r | localtime | strftime("%d.%m %H:%M")) end),
      (if $r == null then "?" else ($r | cd($now)) end),
      ($r // 0),
      ($s // 0),
      ($astart // 0)
    ] | @tsv' 2>/dev/null || true)"

R_P10=""; W_P10=""; M_P10=""
R_USED=""; W_USED=""; M_USED=""
R_LIMIT=""; W_LIMIT=""; M_LIMIT=""
R_STR=""; W_STR=""; M_STR=""
R_CD=""; W_CD=""; M_CD=""
R_EP=""; W_EP=""; M_EP=""
R_START=""; A_START=""

# POSIX sh: разбираем строки без подоболочки while-в-пайпе.
old_ifs="$IFS"
IFS='
'
for row in $rows; do
  IFS="$TAB" read -r key used limit pct10 rstr rcd ep start astart <<EOF
$row
EOF
  [ -n "${astart:-}" ] && A_START="$astart"
  case "$key" in
    rolling) R_P10="$pct10"; R_USED="$used"; R_LIMIT="$limit"; R_STR="$rstr"; R_CD="$rcd"; R_EP="$ep"; R_START="$start" ;;
    weekly)  W_P10="$pct10"; W_USED="$used"; W_LIMIT="$limit"; W_STR="$rstr"; W_CD="$rcd"; W_EP="$ep" ;;
    monthly) M_P10="$pct10"; M_USED="$used"; M_LIMIT="$limit"; M_STR="$rstr"; M_CD="$rcd"; M_EP="$ep" ;;
  esac
done
IFS="$old_ifs"

# --- Скорость сжигания 5ч-окна: средний темп с начала окна ---
# rate — %/ч. Считаем по точным microcents: elapsed от fiveHour.startsAt.
# ratio*1000 нормируется на SUSTAIN («устойчивый» темп, середина полосы = 1×).
burn_rate=""
ratio_milli=""
ratio_disp=""
pace5=""
hit_ep=""
if [ -n "$R_P10" ] && is_num "$R_P10" \
   && is_num "$R_START" && [ "$R_START" -gt 0 ] && is_num "$SUSTAIN" && [ "$SUSTAIN" -gt 0 ]; then
  burn_data="$(awk -v now="$now" -v start="$R_START" -v p10="$R_P10" -v sus="$SUSTAIN" '
    BEGIN {
      el = (now - start) / 3600
      if (el <= 0 || el < 0.0833) exit
      p = p10 / 10
      r = p / el
      rm = (r / sus) * 1000
      if (rm < 0) rm = 0
      f = p * 5 / el
      hit = (p > 0) ? start + (now - start) * 100 / p : 0
      printf "%d\t%.2f\t%.2f\t%.1f\t%.0f", rm, r, r / sus, f, hit
    }' 2>/dev/null)"
  if [ -n "$burn_data" ]; then
    IFS="$TAB" read -r ratio_milli burn_rate ratio_disp pace5 hit_ep <<EOF
$burn_data
EOF
  fi
fi

# --- Цвет item'а по худшему из трёх окон ---
worst=0
for p in "$R_P10" "$W_P10" "$M_P10"; do
  case "$p" in ''|*[!0-9]*) continue ;; esac
  [ "$p" -gt "$worst" ] && worst="$p"
done
color="$(chip_color10 "$worst")"

# --- Бар: иконка-сводка + значения окон по отдельности ---
# Иконка-чип приглушённо красится по худшему окну. Значения окон — мелкая
# приглушённая буква окна (иконка) + крупное бледное число без знака %
# (0..9 с ведущим нулём), подсвечиваемое цветом при достижении порога.
fmt_pct() {
  if is_num "$1" && [ "$1" -lt 10 ]; then printf '0%s' "$1"; else printf '%s' "$1"; fi
}

sb --set "$ROOT" drawing=on icon="$ICON_GO" icon.color="$color" label.drawing=off
if [ "$stale" = "1" ]; then
  sb --set "$ROOT" label.drawing=on label="~" label.color="$C_HEAD"
fi
sb --set "$ROOT.r" icon.drawing=on icon="R" icon.color="$C_HEAD" label="$(fmt_pct "$(pct_int "${R_P10:-0}")")" label.color="$(val_color10 "${R_P10:-}")"
sb --set "$ROOT.w" icon.drawing=on icon="W" icon.color="$C_HEAD" label="$(fmt_pct "$(pct_int "${W_P10:-0}")")" label.color="$(val_color10 "${W_P10:-}")"
sb --set "$ROOT.m" icon.drawing=on icon="M" icon.color="$C_HEAD" label="$(fmt_pct "$(pct_int "${M_P10:-0}")")" label.color="$(val_color10 "${M_P10:-}")"

# --- Полоса скорости сжигания (отдельный item со своим цветом-градиентом) ---
if [ "$BAR" = "1" ] && [ -n "$ratio_milli" ]; then
  sb --set "$NAME.burn" drawing=on \
     label="$(bar_string "$ratio_milli" "$BAR_W")" \
     label.color="$(grade_color "$ratio_milli")"
else
  sb --set "$NAME.burn" drawing=off
fi

# --- Попап: подробности по каждому окну ---
# Строка окна: "Rolling:  4.2% · $0.50/$12.00 · reset 26.10 14:26 (2h 58m)".
window_line() {
  key_label="$1"; p10="$2"; used="$3"; limit="$4"; rstr="$5"; rcd="$6"
  p1="$(pct1 "$p10")"
  u="$(usd "$used")"
  l="$(usd "$limit")"
  note=""
  if [ "$p10" -ge 1000 ] 2>/dev/null; then note=" [limit reached]"; fi
  printf '%-8s %4s%% · %6s/%-6s · reset %s (%7s)%s' \
    "$key_label:" "$p1" "$u" "$l" "$rstr" "$rcd" "$note"
}

if [ -n "$R_P10" ]; then
  sb --set "$NAME.rolling" icon.drawing=off \
     label="$(window_line "Rolling" "$R_P10" "$R_USED" "$R_LIMIT" "$R_STR" "$R_CD")" \
     label.color="$(sev_color10 "$R_P10")"
fi
if [ -n "$W_P10" ]; then
  sb --set "$NAME.weekly" icon.drawing=off \
     label="$(window_line "Weekly" "$W_P10" "$W_USED" "$W_LIMIT" "$W_STR" "$W_CD")" \
     label.color="$(sev_color10 "$W_P10")"
fi
if [ -n "$M_P10" ]; then
  sb --set "$NAME.monthly" icon.drawing=off \
     label="$(window_line "Monthly" "$M_P10" "$M_USED" "$M_LIMIT" "$M_STR" "$M_CD")" \
     label.color="$(sev_color10 "$M_P10")"
fi

# --- Попап: темп 5ч-окна ---
pace_parts=""
pace_color="$C_HEAD"
if [ -n "$burn_rate" ] && [ "$R_P10" -gt 0 ] 2>/dev/null; then
  if [ -n "$hit_ep" ] && [ "$hit_ep" -gt 0 ] 2>/dev/null && [ "$hit_ep" -lt "$R_EP" ] 2>/dev/null; then
    pace_parts="5h ${burn_rate}%/h (${ratio_disp}×) → 100% ~$(fmt_date "$hit_ep" +%H:%M)"
    pace_color="$C_YELLOW"
  else
    pace_parts="5h ${burn_rate}%/h (${ratio_disp}×) → ${pace5}% by reset"
    [ "$ratio_milli" -ge 1500 ] 2>/dev/null && pace_color="$C_YELLOW"
  fi
fi
if [ -n "$pace_parts" ]; then
  sb --set "$NAME.pace" drawing=on label="Pace: $pace_parts" label.color="$pace_color"
else
  sb --set "$NAME.pace" drawing=off
fi

# --- Попап: прогноз месяца к дате продления ---
# Формула как на странице Console → Go: линейная экстраполяция процента
# месячного лимита от access.startsAt до month.resetsAt. Как и на сайте,
# прогноз не показываем, пока с начала периода не прошли сутки.
fc_data=""
if [ -n "$M_P10" ] && is_num "$M_P10" && [ "$M_P10" -gt 0 ] \
   && is_num "$M_USED" && is_num "$M_LIMIT" && [ "$M_LIMIT" -gt 0 ] \
   && is_num "$A_START" && [ "$A_START" -gt 0 ] && is_num "$M_EP" && [ "$M_EP" -gt 0 ] \
   && [ "$A_START" -lt "$M_EP" ]; then
  fc_data="$(awk -v used="$M_USED" -v limit="$M_LIMIT" -v start="$A_START" -v end="$M_EP" -v now="$now" '
    BEGIN {
      el = now - start
      if (el < 86400) exit
      p = used * 100 / limit
      span = end - start
      f = p * span / el
      hit = (p > 0) ? start + el * 100 / p : 0
      usd = used * span / el
      per = p * 86400 / el
      printf "%d\t%.0f\t%.0f\t%.2f", int(f * 10 + 0.5), hit, usd, per
    }' 2>/dev/null)"
fi

F_P10=""; F_HIT=""; F_USD=""; F_PER=""
if [ -n "$fc_data" ]; then
  IFS="$TAB" read -r F_P10 F_HIT F_USD F_PER <<EOF
$fc_data
EOF
fi

F_LABEL=""; F_COLOR="$C_HEAD"
if [ -n "$F_P10" ]; then
  if [ "$M_USED" -ge "$M_LIMIT" ] 2>/dev/null; then
    F_LABEL="Forecast: monthly limit reached"
    F_COLOR="$C_RED"
  elif [ "$F_P10" -ge 1000 ]; then
    F_LABEL="Forecast: on pace to hit 100% $(fmt_date "$F_HIT" +%d.%m) · $(pct1 "$F_P10")% by $(fmt_date "$M_EP" +%d.%m)"
    F_COLOR="$C_RED"
  else
    F_LABEL="Forecast: $(pct1 "$F_P10")% by $(fmt_date "$M_EP" +%d.%m) · $(usd "$F_USD") of $(usd "$M_LIMIT")"
    [ "$F_P10" -ge "$WARN_P10" ] && F_COLOR="$C_YELLOW"
  fi
  sb --set "$NAME.forecast" drawing=on label="$F_LABEL" label.color="$F_COLOR"
else
  sb --set "$NAME.forecast" drawing=off
fi

# --- Попап: спарклайн дневного расхода за текущий период Go ---
# Console Activity API отдаёт дневные суммы, но они могут не совпадать со
# счётчиком месяца (скидки/льготы), поэтому, как и сайт, нормируем их на
# текущий процент месячного лимита.
abody=""
if [ "$SPARK" = "1" ]; then
  if [ -f "$ACTIVITY_CACHE" ]; then
    mt="$(stat -f %m "$ACTIVITY_CACHE" 2>/dev/null || stat -c %Y "$ACTIVITY_CACHE" 2>/dev/null || echo 0)"
    if [ "$((now - mt))" -lt "$ACTIVITY_TTL" ] 2>/dev/null; then
      abody="$(cat "$ACTIVITY_CACHE" 2>/dev/null || true)"
    fi
  fi
  if [ -z "$abody" ]; then
    if [ -n "$ORG" ]; then
      abody="$(curl -fsS -m 15 -H "Authorization: Bearer $TOKEN" -H "x-opencode-org-id: $ORG" \
        -H "Accept: application/json" "$ACTIVITY_API" 2>/dev/null || true)"
    else
      abody="$(curl -fsS -m 15 -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/json" "$ACTIVITY_API" 2>/dev/null || true)"
    fi
    if printf '%s' "$abody" | jq -e '(.daily | type) == "array"' >/dev/null 2>&1; then
      printf '%s\n' "$abody" > "$ACTIVITY_CACHE" 2>/dev/null || true
    else
      abody=""
    fi
  fi
  if [ -z "$abody" ] && [ -f "$ACTIVITY_CACHE" ]; then
    abody="$(cat "$ACTIVITY_CACHE" 2>/dev/null || true)"
  fi
fi

adaily=""
if [ "$SPARK" = "1" ] && [ -n "$abody" ] && [ -n "$M_P10" ] && is_num "$M_P10" \
   && [ "$M_P10" -gt 0 ] && is_num "$M_USED" && is_num "$M_LIMIT" && [ "$M_LIMIT" -gt 0 ] \
   && is_num "$A_START" && [ "$A_START" -gt 0 ] \
   && is_num "$M_EP" && [ "$M_EP" -gt 0 ]; then
  adaily="$(printf '%s' "$abody" | jq -r \
    '(.daily // [])[] | [.date, ((.totalCostMicroCents // "0") | tonumber)] | @tsv' 2>/dev/null || true)"
fi

spark=""
if [ -n "$adaily" ]; then
  spark="$(printf '%s\n' "$adaily" | awk -F'\t' \
    -v used="$M_USED" -v limit="$M_LIMIT" -v start="$A_START" -v end="$M_EP" -v now="$now" -v glyphs="$SPARK_GLYPHS" '
    { n++; c[n] = $2 + 0; sum += $2 + 0 }
    END {
      p = used * 100 / limit
      if (n == 0 || sum <= 0 || p <= 0) exit
      split(glyphs, G, " ")
      avg = (now > start) ? p * 86400 / (now - start) : 0
      max = 0
      for (i = 1; i <= n; i++) { v[i] = p * c[i] / sum; if (v[i] > max) max = v[i] }
      scale = 2 * avg
      if (max > scale) scale = max
      if (scale <= 0) scale = max
      bars = ""
      for (i = 1; i <= n; i++) {
        lvl = int(v[i] * 7 / scale + 0.5) + 1
        if (lvl > 8) lvl = 8
        if (lvl < 1) lvl = 1
        bars = bars G[lvl]
      }
      days = (end - start) / 86400
      printf "%s\t%.1f\t%d\t%.0f", bars, avg, n, days
    }' 2>/dev/null)"
fi

S_BARS=""; S_AVG=""; S_N=""; S_DAYS=""
if [ -n "$spark" ]; then
  IFS="$TAB" read -r S_BARS S_AVG S_N S_DAYS <<EOF
$spark
EOF
fi

if [ -n "$S_BARS" ]; then
  slabel="Daily: $S_BARS"
  # Средний темп имеет смысл только после суток — как и прогноз.
  [ -n "$F_PER" ] && [ -n "$S_AVG" ] && slabel="$slabel  avg ${S_AVG}%/day"
  [ -n "$S_DAYS" ] && [ "$S_DAYS" -gt 0 ] 2>/dev/null && slabel="$slabel · $S_N of $S_DAYS days"
  sb --set "$NAME.spark" drawing=on label="$slabel" label.color="$C_VAL"
else
  sb --set "$NAME.spark" drawing=off
fi

# --- Попап: Usage by Model (Console Usage API, JSON) ---
# Данные серверные, поэтому учитывается использование с любого устройства.
# CSV-экспорт больше не используется: usage/models отдаёт те же агрегаты
# (cost в microcents), но без SA-ключа и без разбора CSV.
mbody=""
hint=""
if [ -f "$MODELS_CACHE" ]; then
  mt="$(stat -f %m "$MODELS_CACHE" 2>/dev/null || stat -c %Y "$MODELS_CACHE" 2>/dev/null || echo 0)"
  if [ "$((now - mt))" -lt "$MODELS_TTL" ] 2>/dev/null; then
    mbody="$(cat "$MODELS_CACHE" 2>/dev/null || true)"
  fi
fi

if [ -z "$mbody" ]; then
  if [ -n "$ORG" ]; then
    resp="$(curl -sS -m 30 -w '\n%{http_code}' -H "Authorization: Bearer $TOKEN" \
      -H "x-opencode-org-id: $ORG" -H "Accept: application/json" \
      --get "$MODELS_API" --data-urlencode "range=$USAGE_RANGE" --data-urlencode "pageSize=100" \
      2>/dev/null || true)"
  else
    resp="$(curl -sS -m 30 -w '\n%{http_code}' -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/json" \
      --get "$MODELS_API" --data-urlencode "range=$USAGE_RANGE" --data-urlencode "pageSize=100" \
      2>/dev/null || true)"
  fi
  http="$(printf '%s' "$resp" | tail -n 1)"
  mbody="$(printf '%s' "$resp" | sed '$d')"
  case "$http" in
    200)
      if printf '%s' "$mbody" | jq -e '(.items | type) == "array"' >/dev/null 2>&1; then
        printf '%s\n' "$mbody" > "$MODELS_CACHE" 2>/dev/null || true
      else
        mbody=""; hint="Usage by Model — неожиданный ответ API"
      fi
      ;;
    401) mbody=""; hint="Usage by Model — токен отклонён (401)" ;;
    403) mbody=""; hint="Usage by Model — 403: нет доступа к usage" ;;
    400) mbody=""; hint="Usage by Model — неверный range (400)" ;;
    000|"") mbody=""; hint="Usage by Model — нет соединения с API" ;;
    *)   mbody=""; hint="Usage by Model — API вернул $http" ;;
  esac
fi

# Протухший кэш лучше пустоты: показываем последние удачные данные.
if [ -z "$mbody" ] && [ -f "$MODELS_CACHE" ]; then
  mbody="$(cat "$MODELS_CACHE" 2>/dev/null || true)"
  hint=""
fi

if [ -z "$mbody" ]; then
  models_hint "${hint:-Usage by Model — нет данных API}"
else
  # Агрегация по (provider, model):
  # provider<TAB>model<TAB>req<TAB>in<TAB>cacheRead<TAB>cacheWrite<TAB>out<TAB>costMicroCents<TAB>tokens
  raw="$(printf '%s' "$mbody" | jq -r '
    def num: (. // 0) | tonumber;
    .items[]
    | [ .provider, .model,
        (.totalRequests | num),
        (.totalInputTokens | num),
        (.totalCacheReadTokens | num),
        (((.totalCacheWrite5mTokens | num) + (.totalCacheWrite1hTokens | num))),
        (.totalOutputTokens | num),
        (.totalCostMicroCents | num),
        (((.totalInputTokens | num) + (.totalCacheReadTokens | num)
          + (.totalCacheWrite5mTokens | num) + (.totalCacheWrite1hTokens | num)
          + (.totalOutputTokens | num)))
      ] | @tsv' 2>/dev/null || true)"

  if [ -z "$raw" ]; then
    models_hint "Usage by Model — пусто за $USAGE_RANGE"
  else
    total_req="$(printf '%s\n' "$raw" | awk -F'\t' '{ s += $3 } END { print s + 0 }')"

    # Сортировка по стоимости, при нулевой стоимости — по объёму токенов.
    mrows="$(printf '%s\n' "$raw" | sort -t"$TAB" -k8,8nr -k9,9nr \
      | head -n "$MODELS_LIMIT" | grep -v '^$' || true)"

    if [ -z "$mrows" ]; then
      models_hint "Usage by Model — пусто за $USAGE_RANGE"
    else
      # Имена моделей из публичного каталога models.dev (кэш 24 ч).
      if [ -f "$NAMES_CACHE" ]; then
        mt="$(stat -f %m "$NAMES_CACHE" 2>/dev/null || stat -c %Y "$NAMES_CACHE" 2>/dev/null || echo 0)"
        if [ "$((now - mt))" -lt "$NAMES_TTL" ] 2>/dev/null; then
          jq -r 'to_entries[] | .key as $p | (.value.models // {}) | to_entries[] | "\($p)\t\(.key)\t\(.value.name // "")"' "$NAMES_CACHE" 2>/dev/null > "$NAMES_TSV"
        fi
      fi
      if [ ! -s "$NAMES_TSV" ]; then
        if curl -fsS -m 30 -o "$NAMES_CACHE" https://models.dev/api.json 2>/dev/null; then
          jq -r 'to_entries[] | .key as $p | (.value.models // {}) | to_entries[] | "\($p)\t\(.key)\t\(.value.name // "")"' "$NAMES_CACHE" 2>/dev/null > "$NAMES_TSV"
        fi
      fi

      # Доля топ-модели по запросам (как «Most used this period» в консоли).
      top_provider="$(printf '%s\n' "$mrows" | head -n 1 | cut -f1)"
      top_model="$(printf '%s\n' "$mrows" | head -n 1 | cut -f2)"
      top_req="$(printf '%s\n' "$mrows" | head -n 1 | cut -f3)"
      top_name="$(awk -F'\t' -v p="$top_provider" -v m="$top_model" '
        { key = $1 SUBSEP $2; if (!(key in nm)) nm[key] = $3; if (!($2 in glob)) glob[$2] = $3 }
        END { n = nm[p SUBSEP m]; if (n == "") n = glob[m]; if (n == "") n = m; print n }' "$NAMES_TSV" 2>/dev/null)"
      [ -n "$top_name" ] || top_name="$top_model"
      share="$(awk -v r="$top_req" -v t="$total_req" 'BEGIN { if (t <= 0) print 0; else printf "%d", r * 100 / t + 0.5 }')"

      models_title="Usage by Model · $USAGE_RANGE"
      [ "$total_req" -gt 0 ] 2>/dev/null && models_title="$models_title · top: $top_name ${share}%"
      sb --set "$NAME.models_title" drawing=on label="$models_title" label.color="$C_HEAD"
      sb --set "$NAME.model_head" drawing=on label.color="$C_HEAD" \
        label="$(printf "%-${NAME_W}s %6s %8s %8s %8s %8s %8s" "Model" "Req" "In" "CacheR" "CacheW" "Out" "Cost")"

      labels="$(printf '%s\n' "$mrows" | awk -F'\t' -v w="$NAME_W" -v pf="$NAMES_TSV" '
        BEGIN {
          while ((getline line < pf) > 0) {
            n = split(line, f, "\t")
            if (n < 3) continue
            key = f[1] SUBSEP f[2]
            if (!(key in nm)) nm[key] = f[3]
            if (!(f[2] in glob)) glob[f[2]] = f[3]
          }
        }
        function fmt(x){ if (x == "" || x + 0 == 0) return "-"; if (x + 0 >= 1000000) return sprintf("%.1fM", x / 1000000); if (x + 0 >= 1000) return sprintf("%.1fk", x / 1000); return sprintf("%d", x) }
        function money(c){ c = c / 100000000; if (c <= 0) return "$0.00"; if (c < 0.01) return "<$0.01"; return sprintf("$%.2f", c) }
        {
          name = nm[$1 SUBSEP $2]; if (name == "") name = glob[$2]; if (name == "") name = $2
          if (length(name) > w) name = substr(name, 1, w)
          printf "%-" w "s %6d %8s %8s %8s %8s %8s\n", name, $3, fmt($4), fmt($5), fmt($6), fmt($7), money($8)
        }')"

      i=0
      old_ifs="$IFS"
      set -f
      IFS='
'
      for label in $labels; do
        i=$((i + 1))
        [ "$i" -gt "$MODELS_MAX" ] && break
        sb --set "$NAME.model.$i" drawing=on label="$label"
      done
      IFS="$old_ifs"
      set +f
      while [ "$i" -lt "$MODELS_MAX" ]; do
        i=$((i + 1))
        sb --set "$NAME.model.$i" drawing=off
      done
    fi
  fi
fi
