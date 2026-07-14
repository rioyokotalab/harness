# Alps interactive convenience. Automated calls should use explicit uenv run.
prgenv() {
    echo 'NATIVE uenv start prgenv-gnu/25.11:v1 --view=default' >&2
    command uenv start prgenv-gnu/25.11:v1 --view=default
}
