default:
    just --list

check:
    just --unstable --fmt --check

format:
    just --unstable --fmt

install:
    brew bundle install
    bundle install

serve:
    bundle exec jekyll serve --livereload

build:
    bundle exec jekyll build --destination ../reflog-static
