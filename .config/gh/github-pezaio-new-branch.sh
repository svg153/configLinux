function pezaio-new-branch() {
    wi_id="$1"
    wi_title="$(azdo-item-title "${wi_id}")"

    git sw -c "AB-${wi_id}_${wi_title}"
}