# Bash startup

When onboarding starts from an older layout, establish public pre/local/post
hooks with `macos-bash-hooks`. Converge the current layout with
`bash-startup-unify --host HOST --plan|--apply`: `.bashrc` is the canonical
owner file and `.bash_profile` is the public thin loader.

Apply the settled owner default for distinct valid local bodies with
`--merge-distinct-profile`: retain the existing login-only body first, then
append the login-file body after removing only its redundant `.bashrc` loader.
For an exact canonical thin profile with an opaque tail, use only
`--merge-thin-profile-tail`. Add `--remove-bash-common-reference` only when
that exact guarded loader and redundant-file retirement were separately
frozen.

Preserve every opaque machine-local startup byte. Validate login, non-login,
nested, and noninteractive scope without changing the native account shell or
reloading a live session. Do not decide `.bash_common` liveness here; its
post-acceptance route owns that test.
