pezaio-new-branch(){
    local wi_id="$1"
    local wi_title="$(az-wi-title "${wi_id}")"
    
    git sw -c "AB-${wi_id}_${wi_title}"
}