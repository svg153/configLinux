
github-clone-all(){
    user="$1"
    
    gh repos-name-all "${user}" | xargs -I '%' gh clo "${user}" %
    # OR
    # gh clone-org -p "${user}" -y "${user}"
}
