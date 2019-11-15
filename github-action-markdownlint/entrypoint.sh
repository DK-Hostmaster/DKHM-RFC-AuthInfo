#!/bin/sh -l

stdbuf -i0 -o0 -e0 echo "\n\nUsing Markdownlint on all Markdown files"
stdbuf -i0 -o0 -e0 echo "----------------------------------------\n"

find . -name "*.md" | xargs -t markdownlint

EXITCODE=$?

test $EXITCODE -eq 0 && echo "Everything looks good" || echo "Markdown does not comply with Markdownlint configuration";
exit $EXITCODE
