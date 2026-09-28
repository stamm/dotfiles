#!/bin/sh

# opencode-go.sh — использование подписки OpenCode Go в SketchyBar.
#
# Источник: GET https://opencode.ai/inference/go/v1/usage
#   Authorization: Bearer <access-токен>  (берётся из opencode.db, таблица credential)
# Ответ: {"usage":{"rolling":{"status","percent","resetsAt"}, "weekly":{...}, "monthly":{...}}}
#
# В баре: R{p}% W{p}% M{p}% (rolling/weekly/monthly), цвет — по худшему окну.
# При наведении открывается popup с деталями (процент, остаток, время сброса)
# и таблицей использования по моделям за диапазон (Console Usage API).
# Опрос: update_freq=60 (см. sketchybarrc). События: mouse.entered, mouse.exited.global.
#
# Настройки через переменные окружения (или $CONFIG_DIR/opencode-go.env, chmod 600):
#   OPENCODE_GO_TOKEN   Bearer-токен (иначе читается из БД OpenCode)
#   OPENCODE_GO_ORG     workspace id  (x-opencode-org-id), необязательно
#   OPENCODE_GO_URL     эндпоинт (по умолчанию .../inference/go/v1/usage)
#   OPENCODE_GO_TTL     TTL кэша в секундах (по умолчанию 60)
#   OPENCODE_GO_DB      путь к opencode.db
#   OPENCODE_GO_SA_KEY  service-account ключ (oc_sk_...) для Console Usage API;
#                       без него таблица по моделям скрывается
#   OPENCODE_GO_CONSOLE_URL  хост консоли (по умолчанию https://opencode.ai/console)
#   OPENCODE_GO_RANGE   диапазон usage/export: 24h|7d|30d (по умолчанию 30d)
#   OPENCODE_GO_MODELS_TTL    TTL кэша CSV в секундах (по умолчанию 300)
#   OPENCODE_GO_MODELS_LIMIT  сколько моделей показывать (по умолчанию 6)
#   OPENCODE_GO_NAMES_TTL     TTL кэша имён models.dev в секундах (86400)
#   OPENCODE_GO_COST_DIVISOR  делитель cost (auto|число; по умолчанию auto)
#   OPENCODE_GO_BAR       полоса скорости сжигания 5ч-окна (1|0; по умолчанию 1)
#   OPENCODE_GO_BAR_WIDTH ширина полосы в ячейках (по умолчанию 6)
#   OPENCODE_GO_SLOPE_MIN окно наклона производной в минутах (по умолчанию 15)
#   OPENCODE_GO_SUSTAIN   «устойчивый» темп, он же 1×, %/ч (по умолчанию 20)
#   OPENCODE_GO_HISTORY   файл истории сэмплов rolling.percent
#                         (по умолчанию ~/.local/state/opencode-go/rolling.tsv)
#   DRY_RUN=1           печатать команды sketchybar вместо применения
#
# Полоса (item opencode_go.burn): показывает производную rolling.percent — скорость
# сжигания в %/ч, нормированную на SUSTAIN. Середина полосы = 1× (100% ровно за 5 ч).
# Цвет полосы — непрерывный градиент: зелёный (≤1×) → жёлтый (1.5×) → красный (≥2×).

set -u

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
[ -f "$CONFIG_DIR/opencode-go.env" ] && . "$CONFIG_DIR/opencode-go.env"

NAME="${NAME:-opencode_go}"
TTL="${OPENCODE_GO_TTL:-60}"
URL="${OPENCODE_GO_URL:-https://opencode.ai/inference/go/v1/usage}"
DB="${OPENCODE_GO_DB:-${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db}"
CACHE="${TMPDIR:-/tmp}/sketchybar-opencode-go.json"

# --- Разбивка по моделям: только Console Usage API (service-account ключ) ---
# Данные серверные, поэтому учитывается использование с любого устройства.
SA_KEY="${OPENCODE_GO_SA_KEY:-}"
CONSOLE_URL="${OPENCODE_GO_CONSOLE_URL:-https://opencode.ai/console}"
USAGE_RANGE="${OPENCODE_GO_RANGE:-30d}"
MODELS_TTL="${OPENCODE_GO_MODELS_TTL:-300}"
MODELS_LIMIT="${OPENCODE_GO_MODELS_LIMIT:-6}"
MODELS_MAX=8
COST_DIV="${OPENCODE_GO_COST_DIVISOR:-auto}"
USAGE_CACHE="${TMPDIR:-/tmp}/sketchybar-opencode-usage.csv"
NAMES_CACHE="${TMPDIR:-/tmp}/sketchybar-modelnames.json"
NAMES_TSV="${TMPDIR:-/tmp}/sketchybar-modelnames.tsv"
NAMES_TTL="${OPENCODE_GO_NAMES_TTL:-86400}"

# --- Полоса скорости сжигания 5ч-окна (rolling) ---
BAR="${OPENCODE_GO_BAR:-1}"
BAR_W="${OPENCODE_GO_BAR_WIDTH:-6}"
SLOPE_MIN="${OPENCODE_GO_SLOPE_MIN:-15}"
SUSTAIN="${OPENCODE_GO_SUSTAIN:-20}"
HISTORY="${OPENCODE_GO_HISTORY:-${XDG_STATE_HOME:-$HOME/.local/state}/opencode-go/rolling.tsv}"

# Иконки (Nerd Font). Задаются байтами UTF-8: POSIX sh не умеет \u-escape.
ICON_GO="$(printf '\357\213\233')"    # U+F2DB nf-fa-microchip
ICON_WARN="$(printf '\357\201\261')"  # U+F071 nf-fa-warning

# Цвета (палитра из конфига opencode).
C_GREEN="0xff98c379"
C_YELLOW="0xffe5c07b"
C_RED="0xffe06c75"
C_HEAD="0xff7f849c"   # приглушённый — заголовок таблицы моделей

# RGB-каналы опорных цветов градиента (из C_GREEN/C_YELLOW/C_RED).
G_R=0x98; G_G=0xc3; G_B=0x79
Y_R=0xe5; Y_G=0xc0; Y_B=0x7b
R_R=0xe0; R_G=0x6c; R_B=0x75

# Символы полосы (UTF-8 байтами).
BLK_FULL="$(printf '\342\226\210')"   # U+2588 █
BLK_EMPTY="$(printf '\342\226\221')"  # U+2591 ░
BAR_L="$(printf '\342\226\217')"      # U+258F ▏
BAR_R="$(printf '\342\226\225')"      # U+2595 ▕

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

# Цвет по проценту использования.
sev_color() {
  case "$1" in
    ''|*[!0-9]*) printf '%s' "$C_GREEN" ;;
    *) if [ "$1" -ge 80 ]; then printf '%s' "$C_RED"
       elif [ "$1" -ge 50 ]; then printf '%s' "$C_YELLOW"
       else printf '%s' "$C_GREEN"; fi ;;
  esac
}

# Целое неотрицательное?
is_num() {
  case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac
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

# --- Обработка мыши: попап открываем/закрываем, данные не перезапрашиваем ---
case "${SENDER:-routine}" in
  mouse.entered)
    sb --set "$NAME" popup.drawing=on
    exit 0
    ;;
  mouse.exited.global)
    sb --set "$NAME" popup.drawing=off
    exit 0
    ;;
esac

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
  sb --set "$NAME" drawing=off
  sb --set "$NAME.burn" drawing=off
  exit 0
fi

# --- Данные: свежий кэш или запрос ---
now="$(date +%s)"
body=""
stale=0
if [ -f "$CACHE" ]; then
  mt="$(stat -f %m "$CACHE" 2>/dev/null || stat -c %Y "$CACHE" 2>/dev/null || echo 0)"
  if [ "$((now - mt))" -lt "$TTL" ] 2>/dev/null; then
    body="$(cat "$CACHE" 2>/dev/null || true)"
  fi
fi

if [ -z "$body" ]; then
  if [ -n "$ORG" ]; then
    body="$(curl -fsS -m 10 -H "Authorization: Bearer $TOKEN" -H "x-opencode-org-id: $ORG" \
      -H "Accept: application/json" "$URL" 2>/dev/null || true)"
  else
    body="$(curl -fsS -m 10 -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/json" "$URL" 2>/dev/null || true)"
  fi
  if printf '%s' "$body" | jq -e '.usage.rolling.percent != null' >/dev/null 2>&1; then
    printf '%s' "$body" > "$CACHE" 2>/dev/null || true
  else
    body=""
  fi
fi

if [ -z "$body" ] && [ -f "$CACHE" ]; then
  body="$(cat "$CACHE" 2>/dev/null || true)"
  stale=1
fi

if [ -z "$body" ] || ! command -v jq >/dev/null 2>&1; then
  sb --set "$NAME" drawing=on icon="$ICON_WARN" icon.color="$C_RED" label="n/a" label.color="$C_RED"
  sb --set "$NAME.rolling" icon.drawing=off label="Не удалось получить данные OpenCode Go" label.color="$C_RED"
  sb --set "$NAME.weekly" icon.drawing=off label=""
  sb --set "$NAME.monthly" icon.drawing=off label=""
  sb --set "$NAME.burn" drawing=off
  models_hide
  exit 0
fi

# --- Парсинг: key <tab> percent <tab> status <tab> reset <tab> countdown <tab> epoch ---
TAB="$(printf '\t')"
rows="$(printf '%s' "$body" | jq -r --argjson now "$now" '
  def cd($now):
    ((. - $now) | if . < 0 then 0 else . end) as $s
    | (($s/86400)|floor) as $d
    | ((($s%86400)/3600)|floor) as $h
    | ((($s%3600)/60)|floor) as $m
    | (if $d>0 then "\($d)d \($h)h"
       elif $h>0 then "\($h)h \($m)m"
       else "\($m)m" end);
  .usage | to_entries[]
  | .key as $k | .value as $v
  | (try (($v.resetsAt // "")
          | sub("\\.[0-9]+";"") | sub("\\+00:00$";"Z") | fromdateiso8601)
     catch null) as $ep
  | [ $k,
      ($v.percent | tostring),
      ($v.status // "unknown"),
      (if $ep == null then "?" else ($ep | localtime | strftime("%d.%m %H:%M")) end),
      (if $ep == null then "?" else ($ep | cd($now)) end),
      ($ep // 0)
    ] | @tsv' 2>/dev/null || true)"

R_PCT=""; W_PCT=""; M_PCT=""
R_ST=""; W_ST=""; M_ST=""
R_STR=""; W_STR=""; M_STR=""
R_CD=""; W_CD=""; M_CD=""
R_EP=""; W_EP=""; M_EP=""

# POSIX sh: разбираем строки без подоболочки while-в-пайпе.
old_ifs="$IFS"
IFS='
'
for row in $rows; do
  IFS="$TAB" read -r key pct status rstr rcd ep <<EOF
$row
EOF
  case "$key" in
    rolling) R_PCT="$pct"; R_ST="$status"; R_STR="$rstr"; R_CD="$rcd"; R_EP="$ep" ;;
    weekly)  W_PCT="$pct"; W_ST="$status"; W_STR="$rstr"; W_CD="$rcd"; W_EP="$ep" ;;
    monthly) M_PCT="$pct"; M_ST="$status"; M_STR="$rstr"; M_CD="$rcd"; M_EP="$ep" ;;
  esac
done
IFS="$old_ifs"

# --- Скорость сжигания 5ч-окна: производная rolling.percent ---
# rate — %/ч. Считаем наклоном по сэмплам за последние SLOPE_MIN минут; если
# сэмплов мало — средним темпом с начала окна (resetsAt − 5ч). ratio*1000
# нормируется на SUSTAIN («устойчивый» темп, он же середина полосы = 1×).
burn_rate=""
ratio_milli=""
ratio_disp=""
if [ -n "$R_PCT" ] && is_num "$R_PCT" && is_num "$R_EP" && [ "$R_EP" -gt 0 ] 2>/dev/null; then
  win_start=$((R_EP - 18000))
  hdir="${HISTORY%/*}"
  if [ "$hdir" != "$HISTORY" ] && [ ! -d "$hdir" ]; then mkdir -p "$hdir" 2>/dev/null || true; fi
  htmp="${HISTORY}.tmp.$$"
  if printf '' > "$htmp" 2>/dev/null; then
    # Оставляем только сэмплы текущего окна, затем дописываем текущий.
    if [ -f "$HISTORY" ]; then
      awk -F"$TAB" -v win="$R_EP" -v start="$win_start" '
        NF >= 3 && $1 ~ /^[0-9]+$/ && $3 == win && $1 + 0 >= start { print }
      ' "$HISTORY" 2>/dev/null > "$htmp"
    fi
    printf '%s\t%s\t%s\n' "$now" "$R_PCT" "$R_EP" >> "$htmp"

    burn_rate="$(awk -F"$TAB" -v now="$now" -v smin="$SLOPE_MIN" -v pct="$R_PCT" -v start="$win_start" '
      { n++; ep[n] = $1 + 0; pp[n] = $2 + 0 }
      END {
        idx = 0
        for (i = 1; i <= n; i++) if (ep[i] >= now - smin * 60) { idx = i; break }
        r = ""
        if (idx > 0 && n > idx) {
          dt = (now - ep[idx]) / 3600
          if (dt > 0) r = (pct - pp[idx]) / dt
        }
        if (r == "" || r < 0) {
          if (now > start) r = pct / ((now - start) / 3600); else r = pct
        }
        if (r < 0) r = 0
        printf "%.4f", r
      }' "$htmp" 2>/dev/null)"
    mv "$htmp" "$HISTORY" 2>/dev/null || rm -f "$htmp" 2>/dev/null || true
  fi

  if is_num "$SUSTAIN" && [ "$SUSTAIN" -gt 0 ] 2>/dev/null && [ -n "$burn_rate" ]; then
    ratio_milli="$(awk -v r="$burn_rate" -v s="$SUSTAIN" 'BEGIN{ v=(r/s)*1000; if(v<0)v=0; printf "%d", v }' 2>/dev/null)"
    ratio_disp="$(awk -v r="$burn_rate" -v s="$SUSTAIN" 'BEGIN{ printf "%.1f", (s>0 ? r/s : 0) }' 2>/dev/null)"
  fi
fi

# --- Цвет item'а по худшему из трёх окон ---
worst=0
for p in "$R_PCT" "$W_PCT" "$M_PCT"; do
  case "$p" in ''|*[!0-9]*) continue ;; esac
  [ "$p" -gt "$worst" ] && worst="$p"
done
color="$(sev_color "$worst")"

# --- Бар ---
label="R${R_PCT:-?}% W${W_PCT:-?}% M${M_PCT:-?}%"
[ "$stale" = "1" ] && label="$label~"
sb --set "$NAME" drawing=on icon="$ICON_GO" icon.color="$color" label="$label" label.color="$color"

# --- Полоса скорости сжигания (отдельный item со своим цветом-градиентом) ---
if [ "$BAR" = "1" ] && [ -n "$ratio_milli" ]; then
  sb --set "$NAME.burn" drawing=on \
     label="$(bar_string "$ratio_milli" "$BAR_W")" \
     label.color="$(grade_color "$ratio_milli")"
else
  sb --set "$NAME.burn" drawing=off
fi

# --- Попап: подробности по каждому окну ---
status_suffix() {
  case "$1" in
    ok|''|unknown) printf '' ;;
    *) printf ' [%s]' "$1" ;;
  esac
}

if [ -n "$R_PCT" ]; then
  R_LEFT="$((100 - R_PCT))"
  R_NOTE=""
  [ -n "$burn_rate" ] && R_NOTE=" · burn $(printf '%.1f' "$burn_rate")%/h (${ratio_disp}×)"
  sb --set "$NAME.rolling" icon.drawing=off \
     label="Rolling: ${R_PCT}% used, ${R_LEFT}% left — resets ${R_STR} (in ${R_CD})$(status_suffix "$R_ST")${R_NOTE}" \
     label.color="$(sev_color "$R_PCT")"
fi
if [ -n "$W_PCT" ]; then
  W_LEFT="$((100 - W_PCT))"
  sb --set "$NAME.weekly" icon.drawing=off \
     label="Weekly: ${W_PCT}% used, ${W_LEFT}% left — resets ${W_STR} (in ${W_CD})$(status_suffix "$W_ST")" \
     label.color="$(sev_color "$W_PCT")"
fi
if [ -n "$M_PCT" ]; then
  M_LEFT="$((100 - M_PCT))"
  sb --set "$NAME.monthly" icon.drawing=off \
     label="Monthly: ${M_PCT}% used, ${M_LEFT}% left — resets ${M_STR} (in ${M_CD})$(status_suffix "$M_ST")" \
     label.color="$(sev_color "$M_PCT")"
fi

# --- Попап: Usage by Model (только Console Usage API, service-account ключ) ---
# Считается на сервере, поэтому учитывает использование с других устройств.
if [ -z "$SA_KEY" ]; then
  models_hint "Usage by Model — задай OPENCODE_GO_SA_KEY"
else
  # CSV из usage/export, с кэшем на MODELS_TTL секунд.
  csv=""
  if [ -f "$USAGE_CACHE" ]; then
    mt="$(stat -f %m "$USAGE_CACHE" 2>/dev/null || stat -c %Y "$USAGE_CACHE" 2>/dev/null || echo 0)"
    if [ "$((now - mt))" -lt "$MODELS_TTL" ] 2>/dev/null; then
      csv="$(cat "$USAGE_CACHE" 2>/dev/null || true)"
    fi
  fi
  if [ -z "$csv" ]; then
    resp="$(curl -sS -m 30 -w '\n%{http_code}' -H "Authorization: Bearer $SA_KEY" -H "Accept: text/csv" \
      --get "$CONSOLE_URL/api/v1/usage/export" \
      --data-urlencode scope=organization --data-urlencode range="$USAGE_RANGE" 2>/dev/null || true)"
    http="$(printf '%s' "$resp" | tail -n 1)"
    csv="$(printf '%s' "$resp" | sed '$d')"
    first="$(printf '%s\n' "$csv" | head -n 1 | tr -d '\r')"
    case "$http:$first" in
      200:*model*) printf '%s\n' "$csv" > "$USAGE_CACHE" 2>/dev/null || true ;;
      200:*) csv=""; hint="Usage by Model — пустой ответ API (200)" ;;
      401:*) csv=""; hint="Usage by Model — ключ отклонён (401)" ;;
      403:*) csv=""; hint="Usage by Model — 403: нет права читать usage" ;;
      400:*) csv=""; hint="Usage by Model — неверные параметры (400)" ;;
      "")    csv=""; hint="Usage by Model — нет соединения с API" ;;
      *)     csv=""; hint="Usage by Model — API вернул $http" ;;
    esac
  fi

  if [ -z "$csv" ]; then
    models_hint "${hint:-Usage by Model — нет данных API}"
  else
    # Агрегация по (provider, model):
    # provider<TAB>model<TAB>req<TAB>in<TAB>cacheRead<TAB>cacheWrite<TAB>out<TAB>cost<TAB>tokens
    # Колонки CSV: cost_micro_cents (÷1e8), cache_write_5m_tokens + cache_write_1h_tokens.
    raw="$(printf '%s\n' "$csv" | awk -F',' -v div="$COST_DIV" '
      function clean(s){ gsub(/\r$/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); if (s ~ /^".*"$/) s = substr(s, 2, length(s) - 2); return s }
      NR == 1 {
        for (i = 1; i <= NF; i++) { h = tolower(clean($i)); col[h] = i }
        ci = col["input_tokens"]; if (!ci) ci = col["input"]
        co = col["output_tokens"]; if (!co) co = col["output"]
        cr = col["cache_read_tokens"]; if (!cr) cr = col["cache_read"]; if (!cr) cr = col["cached_tokens"]
        cw5 = col["cache_write_5m_tokens"]; cw1 = col["cache_write_1h_tokens"]
        cw = col["cache_write_tokens"]; if (!cw) cw = col["cache_write"]
        ccm = col["cost_micro_cents"]; cc = col["cost"]
        cm = col["model"]; cp = col["provider"]
        next
      }
      {
        m = (cm ? clean($cm) : ""); if (m == "") next
        p = (cp ? clean($cp) : "")
        k = p SUBSEP m
        req[k]++
        if (ci) inp[k] += clean($ci) + 0
        if (co) outp[k] += clean($co) + 0
        if (cr) crd[k] += clean($cr) + 0
        if (cw5 || cw1) { if (cw5) cwr[k] += clean($cw5) + 0; if (cw1) cwr[k] += clean($cw1) + 0 }
        else if (cw) cwr[k] += clean($cw) + 0
        if (ccm) { v = clean($ccm) + 0; cst[k] += v; tot += v }
        else if (cc) { v = clean($cc); if (v ~ /\./) dot = 1; cst[k] += v + 0; tot += v + 0 }
      }
      END {
        if (div == "auto") d = ccm ? 100000000 : ((dot == 0 && tot >= 1000000) ? 100000000 : 1)
        else d = div + 0
        if (d <= 0) d = 1
        for (k in req) {
          split(k, a, SUBSEP)
          tok = inp[k] + crd[k] + cwr[k] + outp[k]
          printf "%s\t%s\t%d\t%d\t%d\t%d\t%d\t%.8f\t%d\n", a[1], a[2], req[k], inp[k], crd[k], cwr[k], outp[k], cst[k] / d, tok
        }
      }')"

    # Сортировка по стоимости, при нулевой стоимости — по объёму токенов.
    rows="$(printf '%s\n' "$raw" | sort -t"$TAB" -k8,8nr -k9,9nr | head -n "$MODELS_LIMIT" | grep -v '^$' || true)"

    if [ -z "$rows" ]; then
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

      sb --set "$NAME.models_title" drawing=on label="Usage by Model · $USAGE_RANGE" label.color="$C_HEAD"
      sb --set "$NAME.model_head" drawing=on label.color="$C_HEAD" \
        label="$(printf "%-${NAME_W}s %6s %8s %8s %8s %8s %8s" "Model" "Req" "In" "CacheR" "CacheW" "Out" "Cost")"

      labels="$(printf '%s\n' "$rows" | awk -F'\t' -v w="$NAME_W" -v pf="$NAMES_TSV" '
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
        function money(c){ if (c + 0 <= 0) return "$0.00"; if (c + 0 < 0.01) return "<$0.01"; return sprintf("$%.2f", c) }
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
