default:
    just --list

check:
    just --unstable --fmt --check

format:
    just --unstable --fmt
