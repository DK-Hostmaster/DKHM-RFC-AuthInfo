#!/bin/sh -l

echo ""
echo "Using Markdownlint on README file"
echo "---------------------------------"

find . -name "*.md" | xargs markdownlint
