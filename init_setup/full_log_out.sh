#  run as . init_setup/full_log_out.sh
#
#  Removes ALL local gcloud and clasp credentials. It does not touch your browser: sign out of
#  Google there yourself, or just use a private window.
export GOOGLE_APPLICATION_CREDENTIALS=
gcloud auth revoke --all
rm -f service-account-key.json
gcloud config unset account
gcloud config unset project
rm -rf ~/.config/gcloud

clasp logout
rm -f ~/.clasprc.json       # <- This is clasp's global auth token
rm -rf ~/.clasp-*           # <- In case of clasp env profiles (not always present)
