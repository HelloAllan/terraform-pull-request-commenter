FROM hashicorp/terraform:1.4.5

LABEL \
    repository="https://github.com/sheeeng/terraform-pull-request-commenter" \
    homepage="https://github.com/sheeeng/terraform-pull-request-commenter" \
    maintainer="Leonard Sheng Sheng Lee" \
    com.github.actions.name="Terraform Pull Request Commenter" \
    com.github.actions.description="Adds opinionated comments to a PR from Terraform fmt/init/plan output." \
    com.github.actions.icon="git-pull-request" \
    com.github.actions.color="purple"

RUN apk add \
    --no-cache \
    --quiet \
    bash=~5 \
    curl=~8 \
    jq=~1 && apk add --upgrade curl

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
