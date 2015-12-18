#!/bin/bash

GH_STATUS_REPO_NAME=${INITIATING_REPO_NAME:-"alphagov/content-tagger"}
CONTEXT_MESSAGE=${CONTEXT_MESSAGE:-"default"}
GH_STATUS_GIT_COMMIT=${INITIATING_GIT_COMMIT:-${GIT_COMMIT}}

function github_status {
  STATUS="$1"
  MESSAGE="$2"
  gh-status "$GH_STATUS_REPO_NAME" "$GH_STATUS_GIT_COMMIT" "$STATUS" -d "Build #${BUILD_NUMBER} ${MESSAGE}" -u "$BUILD_URL" -c "$CONTEXT_MESSAGE" >/dev/null
}

function error_handler {
  trap - ERR # disable error trap to avoid recursion
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  github_status error "errored on Jenkins"
  exit "${code}"
}

trap 'error_handler ${LINENO}' ERR
github_status pending "is running on Jenkins"

# Cleanup anything left from previous test runs
git clean -fdx

# Clone govuk-content-schemas depedency for contract tests
rm -rf /tmp/govuk-content-schemas
git clone git@github.com:alphagov/govuk-content-schemas.git /tmp/govuk-content-schemas
(
  cd /tmp/govuk-content-schemas
  git checkout ${SCHEMA_GIT_COMMIT:-"master"}
)
export GOVUK_CONTENT_SCHEMAS_PATH=/tmp/govuk-content-schemas

# Try to merge master into the current branch, and abort if it doesn't exit
# cleanly (ie there are conflicts). This will be a noop if the current branch
# is master.
git merge --no-commit origin/master || git merge --abort

export RAILS_ENV=test
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment --without development

bundle exec govuk-lint-ruby

bundle exec rake db:drop db:create db:schema:load

if bundle exec rake ${TEST_TASK:-"default"}; then
  github_status success "succeeded on Jenkins"
else
  github_status failure "failed on Jenkins"
  exit 1
fi