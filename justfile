default:
    just --list

check:
    just --unstable --fmt --check

format:
    just --unstable --fmt

install:
    brew bundle install
    bundle install
