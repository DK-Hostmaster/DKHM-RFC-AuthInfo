#!/bin/sh -l

echo "\n\nUsing Markdownlint on all Markdown files"
echo "----------------------------------------\n"

find . -name "*.md" | xargs -t markdownlint

EXITCODE=$?

test $EXITCODE -eq 0 && echo "Everything looks good" || echo "Markdown does not comply with Markdownlint configuration";
exit $EXITCODE
