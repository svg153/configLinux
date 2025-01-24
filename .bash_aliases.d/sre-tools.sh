## SSL
alias certexp="openssl x509 -enddate -noout -in"
alias certcheck="openssl x509 -noout -text -in"
alias caverify="openssl verify -CAfile"

## Networking
alias mtr="sudo /usr/local/sbin/mtr"
alias nlp="nslookup"

## Other
pwgen() {
    length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

## hashicorp vault
alias vault="source ~/.vault-env; vault"