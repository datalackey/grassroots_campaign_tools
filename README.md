USER NOTES:

If you don't have a gmail.com account, then you can create a google account that will allow you to view spreadsheet via:

    https://accounts.google.com/signupwithoutgmail


Initial project set-up assumes you have installed required dependencies (frameworks, etc).

Current development flow assumes you are on Nixos-based Linux (but we could provide support for other
platforms in our scripted set-up at some point.)


for nixos, init dev env via:

    nix-shell    # this inits dependecies for your current shell seesion per shell.nix




*****
stuff to include later..

https://myaccount.google.com/deleteaccount

payment profile:
    org
        multi user
    individual
        one user

    ignore first project (autocreated).

setup test account  (requires manual interaction to sign up and establish credit card billing)

    https://accounts.google.com/signup



next
    https://console.cloud.google.com/billing

        Create a payments profile
        Add payment method

enable maps API manually..

https://console.cloud.google.com/apis/library/maps-backend.googleapis.com?project=distancetools--1751154563


What Can Be Scripted After Manual Billing Setup
Once the billing account exists, scripting becomes easy and safe. You can:

✅ Script These:
Task	Scriptable?	Notes
Create GCP project	✅	gcloud projects create
Link billing	✅	gcloud beta billing projects link
Enable APIs	✅	gcloud services enable ...
Push clasp scripts	✅	clasp push, etc.
Set budget alerts	✅	gcloud beta billing budgets create






npm install -g @google/clasp@2.4.1
might need to do this because the latest versions (e.g. 2.4.2 and newer) introduced 
a breaking change in how .clasp.json and .clasprc.json were handled, especially around:

    Broken or noisy clasp run behavior:

    clasp run began prompting for scopes or failing outright even when scopes were correct.

    Some of these issues appeared around v2.4.2+ due to changes in how runtime credentials and scopes are checked.

    Weird merge of Code.js vs Code.gs behavior:

    A regression where files downloaded as .gs (server default), but clasp confused them with .js locally, especially when both existed.





