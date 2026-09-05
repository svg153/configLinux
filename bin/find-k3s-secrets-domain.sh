#!/usr/bin/env bash
# Busca un dominio dentro de la clave k3s_secrets en archivos all.yaml/all.yml
# Uso:
#   DOMAIN=example.com ./find-k3s-secrets-domain.sh [DIRECTORIO]
#   ./find-k3s-secrets-domain.sh example.com [DIRECTORIO]

set -euo pipefail
IFS=$'\n\t'

print_usage() {
  printf '%s\n' "Uso: DOMAIN=<dominio> $0 [DIRECTORIO]" \
    "   o: $0 <dominio> [DIRECTORIO]" \
    "Busca recursivamente all.yaml/all.yml y, bajo k3s_secrets, valores iguales al dominio." >&2
}

# Dominio por variable o primer argumento
DOMAIN="${DOMAIN:-${1:-}}"
SEARCH_DIR="${2:-.}"

if [[ -z "${DOMAIN}" ]]; then
  print_usage
  exit 2
fi

# Dependencias obligatorias
if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' "Error: se requiere 'jq' en PATH" >&2
  exit 2
fi
if ! command -v yq >/dev/null 2>&1; then
  printf '%s\n' "Error: se requiere 'yq' (mikefarah/yq) en PATH" >&2
  exit 2
fi

matches=0

# Buscar archivos y procesar
while IFS= read -r -d '' file; do
  # Convertir YAML a JSON y filtrar bajo k3s_secrets
  # Salida: una línea por coincidencia, con la ruta en k3s_secrets
  if out=$(yq -o=json '.' "$file" | jq -r --arg domain "$DOMAIN" '
      .k3s_secrets? // empty
      | paths(scalars) as $p
      | select(getpath($p) == $domain)
      | $p
      | @json
    '); then
    if [[ -n "$out" ]]; then
      while IFS= read -r line; do
        # Formatear la ruta tipo: k3s_secrets.key[0].subkey
        path=$(printf '%s\n' "$line" | jq -r '
          map(
            if type=="number" then "["+tostring+"]"
            else tostring
            end
          ) | join(".")
        ')
        printf '%s: k3s_secrets.%s = %s\n' "$file" "$path" "$DOMAIN"
        matches=$((matches+1))
      done <<< "$out"
    fi
  fi
done < <(find "$SEARCH_DIR" -type f \( -name 'all.yaml' -o -name 'all.yml' -o -name 'all.ymal' \) -print0)

if [[ "$matches" -eq 0 ]]; then
  printf '%s\n' "No se encontraron coincidencias para el dominio: $DOMAIN" >&2
  exit 1
fi